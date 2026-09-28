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
$ rake wasm:install_jars # download the Chicory/ASM jars into ~/.m2 (run on JRuby)
```

The compiled `rbs_parser.wasm` is a build artifact and is not checked in.

Like the MRI extension, the module is compiled with `-DNDEBUG`, which removes the
`RBS_ASSERT` checks — they sit in the lexer and the constant pool, so leaving them
in costs around 20% of parse time. `DEBUG=1 rake wasm:build` keeps them, which is
what you want when debugging the parser itself through the module.

The WASI SDK is needed for the *build*, not for running the result — the host clang already
knows the `wasm32` target, but there is no wasm32 libc on a normal machine, so it picks up the
host headers and fails on the first `#include`. That is what the SDK supplies, along with the
builtins the link step needs.

## Running the suite on JRuby

[`Dockerfile.jruby`](../Dockerfile.jruby) builds an image that has everything this needs, so no
JRuby, JDK or WASI SDK has to be installed to work on the JRuby side:

```console
$ docker build -f Dockerfile.jruby -t rbs-jruby .
$ docker run --rm rbs-jruby                                  # run the test suite
$ docker run --rm -e RBS_PLATFORM=java rbs-jruby \
    gem build rbs.gemspec                                    # build the -java gem
```

Two things in it are not obvious:

- `build-essential` is for prism, which builds `libprism.so` and loads it through FFI on JRuby
  rather than as an MRI C extension. It needs `cc` and `make`.
- Bundler is skipped. The development `Gemfile` pulls in CRuby-only C extensions (bigdecimal,
  stackprof, …) that cannot build on JRuby, so the few gems the suite needs are installed
  directly, in the same set as [`jruby.yml`](../.github/workflows/jruby.yml).

The image compiles `rbs_parser.wasm` itself, which is why it carries the WASI SDK. That is not
the only arrangement: the build needs the SDK but not JRuby, and running the suite needs JRuby
but not the SDK, so `jruby.yml` splits them instead — it compiles the module on CRuby and then
switches engines to test against the result.

`rake wasm:install_jars` is the step that has to be on JRuby either way: it resolves the `jar`
requirements from `rbs.gemspec` through the JVM.

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
unknown), and the character range to parse (`start`/`end`). Each returns:

| Status | Meaning | Result |
| --- | --- | --- |
| `1` | Parsed. | The serialized AST. |
| `0` | Parse error. | An error blob (start/end positions, syntax flag, token type, message). |
| `-1` | Negative or reversed range. | Empty. |
| `-2` | `start` is a byte position no character starts at — inside a character, or past the end of the buffer. | Empty. |

An `end` past the end of the buffer is not an error: it is clamped to the
buffer, which is where lexing stops anyway. The two negative statuses are about
the range the caller asked for rather than the source text, and `RBS::Parser`
turns both into an `ArgumentError`, as the C extension does.

Type/method-type parsing also takes a buffer of newline-separated
type-variable names (`vars`/`vars_len`, with `vars_len < 0` meaning "none"):

| Export | Signature |
| --- | --- |
| `rbs_wasm_parse_signature` | `(ptr, len, enc, enc_len, start, end) -> i32` |
| `rbs_wasm_parse_type` | `(ptr, len, enc, enc_len, start, end, vars, vars_len, require_eof, void_allowed, self_allowed, classish_allowed) -> i32` |
| `rbs_wasm_parse_method_type` | `(ptr, len, enc, enc_len, start, end, vars, vars_len, require_eof) -> i32` |
| `rbs_wasm_selftest` | `() -> i32` (parses a fixed sample; `1` on success) |

For type and method-type parsing, a successful result of length 0 means the input
was empty (`nil`).
