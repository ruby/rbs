# RBS parser as WebAssembly

The parser under [`src/`](../src) is plain, self-contained C with no dependency
on the Ruby C API, so it can be compiled to WebAssembly as-is. This directory
holds the small entry-point shim ([`rbs_wasm.c`](rbs_wasm.c)) that exposes a
stable ABI to a WebAssembly host.

The motivating use case is running RBS on Ruby implementations that cannot load
the MRI C extension (notably JRuby): the host loads `rbs_parser.wasm`, runs the
parser over a source buffer, and reads the result back out — no native build per
platform required.

## Building

The build needs the [WASI SDK](https://github.com/WebAssembly/wasi-sdk/releases)
(for `clang`, the wasi-libc sysroot, and the wasm32 compiler-rt builtins):

```console
$ export WASI_SDK_PATH=/path/to/wasi-sdk
$ rake wasm:build
Built .../wasm/rbs_parser.wasm
```

To also run the smoke test you need [wasmtime](https://wasmtime.dev/) (or another
WASI runtime, via the `WASMTIME` environment variable):

```console
$ rake wasm:check
WebAssembly selftest passed.
```

The compiled `rbs_parser.wasm` is a build artifact and is not checked in.

## Exported functions

The module is built as a "reactor": it has no `main`, and the host calls
`_initialize` once before invoking any export.

| Export                     | Signature             | Description                                                              |
| -------------------------- | --------------------- | ------------------------------------------------------------------------ |
| `rbs_wasm_alloc`           | `(i32) -> i32`        | Allocate N bytes in linear memory and return the offset.                 |
| `rbs_wasm_free`            | `(i32) -> ()`         | Free a region returned by `rbs_wasm_alloc`.                              |
| `rbs_wasm_parse_signature` | `(i32 ptr, i32 len) -> i32` | Parse the UTF-8 source at `ptr`/`len`. Returns 0 on success, 1 on error. |
| `rbs_wasm_selftest`        | `() -> i32`           | Parse a small fixed signature. Returns 0 on success, 1 otherwise.        |

This is the foundation step: it proves the parser builds and runs under
WebAssembly. Subsequent steps add a compact serialization of the parsed AST so
the host can reconstruct `RBS::AST` objects, and wire the module into RBS on
JRuby through a JVM WebAssembly runtime.
