# RBS AST binary serialization

This document describes the binary format used to move a parsed RBS AST out of
the parser and into Ruby objects without going through the Ruby C API. It exists
so that RBS can run on Ruby implementations that cannot load the C extension
(notably JRuby): the parser runs inside WebAssembly, serializes the result with
this format, and the host rebuilds `RBS::AST` objects in pure Ruby.

The encoder (`rbs_serialize_node`, `src/serialize.c`) and the schema that drives
the decoder (`RBS::WASM::SerializationSchema`, `lib/rbs/wasm/serialization_schema.rb`)
are both generated from `config.yml`, so they always agree. The decoder itself
is `RBS::WASM::Deserializer`.

## Conventions

- All multi-byte integers are **little-endian**.
- `u8`, `u32` are unsigned; `i32` is signed.
- `str` is a `u32` byte length followed by that many raw bytes (no terminator).
- A value is reconstructed to mirror exactly what `ast_translation.c` produces,
  including string encodings: string/integer literal nodes are UTF-8, while
  comments, annotations and symbols use the source buffer's encoding.

## Nodes

Every node begins with a `u8` **tag**:

- `0` — a NULL node (`nil` on the Ruby side).
- `1..N` — a node type, in the order they appear in `SerializationSchema::SCHEMA`.
- `SYMBOL_TAG` (`N + 1`) — an interned symbol, followed by `str` (the symbol's
  bytes). Decoded with `String#to_sym`.

A few node types are encoded specially, matching their bespoke handling in
`ast_translation.c`:

| Node | Payload after tag | Decoded as |
| --- | --- | --- |
| `RBS::AST::Bool` | `u8` | `true` / `false` |
| `RBS::AST::Integer` | `str` | `String#to_i` |
| `RBS::AST::String` | `str` | the string (UTF-8) |
| `RBS::Types::Record::FieldType` | node, then `u8` | `[type, required]` |
| `RBS::Signature` | node-list, then node-list | `[directives, declarations]` |
| `RBS::Namespace` | node-list, then `u8` | `RBS::Namespace[path, absolute]` |
| `RBS::TypeName` | node, then node | `RBS::TypeName[namespace, name]` |

Every other node is encoded generically:

1. If the node exposes a location, its **base location** is written (see below),
   followed by one location range per declared child, in order.
2. Each field is written in declaration order, encoded by its type (see below).

The decoder constructs `Klass.new(location:, **fields)` (omitting `location:`
for nodes that do not expose one). For `Class`, `Module`, `Interface`,
`TypeAlias` and `MethodType`, `RBS::AST::TypeParam.resolve_variables` is applied
to `type_params` first, exactly as the C translation does.

## Fields

| Field type | Encoding |
| --- | --- |
| node (`rbs_node`, `rbs_type_name`, `rbs_ast_comment`, `rbs_ast_symbol`, ...) | a node (recursive; NULL allowed) |
| `rbs_node_list` | `u32` count, then that many nodes |
| `rbs_hash` | `u32` count, then count × (key node, value node) |
| `rbs_string` | `str` (source encoding) |
| `bool` | `u8` |
| enum | `u8` index into the enum's values (see `SCHEMA`) |
| `rbs_location_range` | a location range |
| `rbs_location_range_list` | `u32` count, then that many location ranges |
| `rbs_attr_ivar_name` | `u8` tag: `0` → `nil`, `1` → `false`, `2` → `str` → symbol |

## Location ranges

A location range is a `u8` presence flag:

- `0` — null range (`nil`, or a node with no location).
- `1` — followed by `i32` start and `i32` end **character** positions.

The base location and child ranges together let the decoder rebuild an
`RBS::Location` (with its required/optional children) through the public
`RBS::Location` API, so the same decoder works whether `RBS::Location` is backed
by the C extension or a pure-Ruby implementation.
