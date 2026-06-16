/**
 * @file rbs_wasm.c
 *
 * WebAssembly entry points for the RBS parser.
 *
 * The RBS parser in `src/` is plain, self-contained C with no dependency on
 * the Ruby C API. This file exposes a small, stable ABI so that the parser can
 * be driven from a WebAssembly host (for example, a JVM-based runtime running
 * under JRuby).
 *
 * This module is built as a "reactor" (`-mexec-model=reactor`): it has no
 * `main`, and the host is expected to call `_initialize` once before invoking
 * any of the exported functions below.
 *
 * For now this only proves the toolchain end to end: it can allocate memory in
 * the linear address space, run the parser over a source buffer, and report
 * whether parsing succeeded. Serializing the resulting AST back to the host is
 * handled in a later step.
 */

#include <stdlib.h>
#include <string.h>
#include <stdint.h>

#include "rbs/parser.h"
#include "rbs/string.h"
#include "rbs/util/rbs_encoding.h"

/**
 * Allocate `size` bytes in the module's linear memory and return the offset.
 *
 * The host uses this to reserve a region it can write an input string into
 * before calling one of the parse entry points.
 */
__attribute__((export_name("rbs_wasm_alloc"))) void *rbs_wasm_alloc(size_t size) {
    return malloc(size);
}

/**
 * Free a region previously returned by `rbs_wasm_alloc`.
 */
__attribute__((export_name("rbs_wasm_free"))) void rbs_wasm_free(void *ptr) {
    free(ptr);
}

/**
 * Parse an RBS signature from a UTF-8 source buffer.
 *
 * @param source Offset of the source buffer in linear memory.
 * @param length Length of the source buffer, in bytes.
 * @return 0 if parsing succeeded, 1 if a parse error occurred.
 */
__attribute__((export_name("rbs_wasm_parse_signature"))) int rbs_wasm_parse_signature(const char *source, int length) {
    rbs_string_t string = rbs_string_new(source, source + length);
    const rbs_encoding_t *encoding = RBS_ENCODING_UTF_8_ENTRY;
    rbs_parser_t *parser = rbs_parser_new(string, encoding, 0, length);

    rbs_signature_t *signature = NULL;
    bool ok = rbs_parse_signature(parser, &signature);

    int result = (ok && parser->error == NULL) ? 0 : 1;

    rbs_parser_free(parser);

    return result;
}

/**
 * Parse a small, fixed RBS document.
 *
 * This exercises the whole parser path inside WebAssembly without the host
 * having to write anything into linear memory, which makes it convenient as a
 * build smoke test (`wasmtime run --invoke rbs_wasm_selftest rbs_parser.wasm`).
 *
 * @return 0 if the sample parsed successfully, 1 otherwise.
 */
__attribute__((export_name("rbs_wasm_selftest"))) int rbs_wasm_selftest(void) {
    static const char source[] =
        "class User\n"
        "  attr_reader name: String\n"
        "  def initialize: (String name) -> void\n"
        "end\n"
        "\n"
        "module Authentication\n"
        "  def authenticate: (String, String) -> bool\n"
        "end\n";

    return rbs_wasm_parse_signature(source, (int) (sizeof(source) - 1));
}
