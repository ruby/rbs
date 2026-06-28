# RBS parser as WebAssembly

The parser under [`src/`](../src) is plain, self-contained C with no dependency
on the Ruby C API, so it can be compiled to WebAssembly as-is. This directory
holds the small entry-point shim ([`rbs_wasm.c`](rbs_wasm.c)) that exposes a
stable ABI to a WebAssembly host.

This is how RBS runs on Ruby implementations that cannot load the MRI C
extension (notably JRuby): the host loads `rbs_parser.wasm`, runs the parser over
a source buffer, and reads the serialized AST back out. The Ruby side then
rebuilds `RBS::AST` objects with `RBS::WASM::Deserializer` — no native build per
platform required. See [`lib/rbs/wasm`](../lib/rbs/wasm) and
[`docs/wasm_serialization.md`](../docs/wasm_serialization.md).

## Building

The build needs the [WASI SDK](https://github.com/WebAssembly/wasi-sdk/releases)
(for `clang`, the wasi-libc sysroot, and the wasm32 compiler-rt builtins):

```console
$ export WASI_SDK_PATH=/path/to/wasi-sdk
$ rake wasm:build        # compile rbs_parser.wasm
$ rake wasm:check        # also smoke-test it (needs wasmtime)
$ rake wasm:jruby_setup  # copy rbs_parser.wasm into lib/rbs/wasm/ for JRuby
$ rake wasm:install_jars # download the Chicory/ASM jars into ~/.m2 and
                         # generate lib/rbs_jars.rb (run on JRuby)
```

The compiled `rbs_parser.wasm` is a build artifact and is not checked in.

## Exported functions

The module is built as a "reactor": it has no `main`, and the host calls
`_initialize` once before invoking any export.

Memory management and results:

| Export | Signature | Description |
| --- | --- | --- |
| `rbs_wasm_alloc` | `(i32) -> i32` | Allocate N bytes in linear memory, return the offset. |
| `rbs_wasm_free` | `(i32) -> ()` | Free a region from `rbs_wasm_alloc`. |
| `rbs_wasm_result_ptr` | `() -> i32` | Offset of the most recent result. |
| `rbs_wasm_result_len` | `() -> i32` | Length of the most recent result. |

Parsing — each takes the whole buffer (`ptr`/`len`), its Ruby encoding name
(`enc`/`enc_len`, e.g. `"UTF-8"` or `"EUC-JP"`; falls back to UTF-8 when empty or
unknown), and the character range to parse (`start`/`end`). Each returns `1` on
success or `0` on a parse error. On success the result is the serialized AST; on
error it is an error blob (start/end positions, syntax flag, token type,
message). Type/method-type parsing also takes a buffer of newline-separated
type-variable names (`vars`/`vars_len`, with `vars_len < 0` meaning "none"):

| Export | Signature |
| --- | --- |
| `rbs_wasm_parse_signature` | `(ptr, len, enc, enc_len, start, end) -> i32` |
| `rbs_wasm_parse_type` | `(ptr, len, enc, enc_len, start, end, vars, vars_len, require_eof, void_allowed, self_allowed, classish_allowed) -> i32` |
| `rbs_wasm_parse_method_type` | `(ptr, len, enc, enc_len, start, end, vars, vars_len, require_eof) -> i32` |
| `rbs_wasm_selftest` | `() -> i32` (parses a fixed sample; `1` on success) |

For type and method-type parsing, a successful result of length 0 means the input
was empty (`nil`).
