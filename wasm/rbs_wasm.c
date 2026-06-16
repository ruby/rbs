/**
 * @file rbs_wasm.c
 *
 * WebAssembly entry points for the RBS parser.
 *
 * The parser in `src/` is plain, self-contained C with no dependency on the
 * Ruby C API, so it compiles to WebAssembly as-is. This file exposes a small,
 * stable ABI so the parser can be driven from a WebAssembly host (a JVM-based
 * runtime running under JRuby).
 *
 * The flow is: the host writes a UTF-8 source string into linear memory
 * (`rbs_wasm_alloc`), calls one of the `rbs_wasm_parse_*` functions, and reads
 * the result back out (`rbs_wasm_result_ptr` / `rbs_wasm_result_len`). On
 * success the result is the serialized AST (see `rbs_serialize_node` and
 * `docs/wasm_serialization.md`); on a parse error it is an error blob (see
 * `set_error_result`). `RBS::WASM` on the Ruby side decodes both.
 *
 * Built as a "reactor": no `main`, and the host calls `_initialize` once before
 * invoking any export.
 */

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

#include "rbs/parser.h"
#include "rbs/serialize.h"
#include "rbs/string.h"
#include "rbs/util/rbs_encoding.h"

// The result of the most recent parse, living in linear memory until the next
// call replaces it. WebAssembly is little-endian, so the multi-byte integers
// written below match the little-endian format the Ruby decoder expects.
static char *result_buffer = NULL;
static int32_t result_length = 0;

// Replace the current result with a fresh `length`-byte buffer and return a
// pointer to it for the caller to fill in.
static char *allocate_result(size_t length) {
    free(result_buffer);
    result_buffer = (char *) malloc(length == 0 ? 1 : length);
    result_length = (int32_t) length;
    return result_buffer;
}

/**
 * Allocate `size` bytes in linear memory and return the offset. The host uses
 * this to reserve space for an input string before calling a parse function.
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
 * Offset of the most recent parse result in linear memory.
 */
__attribute__((export_name("rbs_wasm_result_ptr")))
int32_t
rbs_wasm_result_ptr(void) {
    return (int32_t) (intptr_t) result_buffer;
}

/**
 * Length, in bytes, of the most recent parse result.
 */
__attribute__((export_name("rbs_wasm_result_len")))
int32_t
rbs_wasm_result_len(void) {
    return result_length;
}

// Encode the parser's error into the result buffer:
//
//   [i32 start_char][i32 end_char][u8 syntax_error]
//   [u32 token_type_len][token_type bytes][u32 message_len][message bytes]
//
// Always returns 0, the failure status for the parse functions.
static int set_error_result(rbs_parser_t *parser) {
    rbs_error_t *error = parser->error;
    const char *token_type = rbs_token_type_str(error->token.type);
    const char *message = error->message;
    uint32_t token_type_len = (uint32_t) strlen(token_type);
    uint32_t message_len = (uint32_t) strlen(message);

    int32_t start_char = error->token.range.start.char_pos;
    int32_t end_char = error->token.range.end.char_pos;
    uint8_t syntax_error = error->syntax_error ? 1 : 0;

    size_t total = 4 + 4 + 1 + 4 + token_type_len + 4 + message_len;
    char *p = allocate_result(total);

    memcpy(p, &start_char, 4);
    p += 4;
    memcpy(p, &end_char, 4);
    p += 4;
    *p++ = (char) syntax_error;
    memcpy(p, &token_type_len, 4);
    p += 4;
    memcpy(p, token_type, token_type_len);
    p += token_type_len;
    memcpy(p, &message_len, 4);
    p += 4;
    memcpy(p, message, message_len);

    return 0;
}

static int set_serialized_result(rbs_parser_t *parser, rbs_node_t *node) {
    rbs_string_t bytes = rbs_serialize_node(parser->allocator, &parser->constant_pool, node);
    size_t length = rbs_string_len(bytes);
    memcpy(allocate_result(length), bytes.start, length);
    return 1;
}

// Declare type variables from a buffer of newline-separated names. A negative
// length means "no variables given" (the parser keeps its default table).
static void declare_variables(rbs_parser_t *parser, const char *variables, int variables_length) {
    if (variables_length < 0) return;

    rbs_parser_push_typevar_table(parser, true);

    const char *cursor = variables;
    const char *end = variables + variables_length;
    const char *name_start = cursor;

    while (cursor <= end) {
        if (cursor == end || *cursor == '\n') {
            size_t name_length = (size_t) (cursor - name_start);
            if (name_length > 0) {
                uint8_t *copied = (uint8_t *) malloc(name_length);
                memcpy(copied, name_start, name_length);
                rbs_constant_id_t id = rbs_constant_pool_insert_owned(&parser->constant_pool, copied, name_length);
                (void) rbs_parser_insert_typevar(parser, id);
            }
            name_start = cursor + 1;
        }
        cursor++;
    }
}

/**
 * Parse an RBS signature from a UTF-8 source buffer.
 *
 * `source`/`length` is the whole buffer content; `start_pos`/`end_pos` are the
 * character range within it to parse, so reported locations are absolute (this
 * mirrors RBS::Parser._parse_signature).
 *
 * @return 1 on success (result is the serialized AST), 0 on a parse error
 *         (result is an error blob).
 */
__attribute__((export_name("rbs_wasm_parse_signature"))) int rbs_wasm_parse_signature(const char *source, int length, int start_pos, int end_pos) {
    rbs_string_t string = rbs_string_new(source, source + length);
    rbs_parser_t *parser = rbs_parser_new(string, RBS_ENCODING_UTF_8_ENTRY, start_pos, end_pos);

    rbs_signature_t *signature = NULL;
    rbs_parse_signature(parser, &signature);

    int status;
    if (parser->error == NULL) {
        status = set_serialized_result(parser, (rbs_node_t *) signature);
    } else {
        status = set_error_result(parser);
    }

    rbs_parser_free(parser);
    return status;
}

/**
 * Parse a single RBS type.
 *
 * @param variables Newline-separated type variable names (length < 0 for none).
 * @return 1 on success, 0 on a parse error. On success with an empty result
 *         (`rbs_wasm_result_len` == 0), the input was empty (`nil`).
 */
__attribute__((export_name("rbs_wasm_parse_type"))) int rbs_wasm_parse_type(const char *source, int length, int start_pos, int end_pos, const char *variables, int variables_length, int require_eof, int void_allowed, int self_allowed, int classish_allowed) {
    rbs_string_t string = rbs_string_new(source, source + length);
    rbs_parser_t *parser = rbs_parser_new(string, RBS_ENCODING_UTF_8_ENTRY, start_pos, end_pos);
    declare_variables(parser, variables, variables_length);

    int status;
    if (parser->next_token.type == pEOF) {
        allocate_result(0);
        status = 1;
    } else {
        rbs_node_t *type = NULL;
        rbs_parse_type(parser, &type, void_allowed != 0, self_allowed != 0, classish_allowed != 0);

        if (parser->error == NULL && require_eof) {
            rbs_parser_advance(parser);
            if (parser->current_token.type != pEOF) {
                rbs_parser_set_error(parser, parser->current_token, true, "expected a token `%s`", rbs_token_type_str(pEOF));
            }
        }

        status = parser->error == NULL ? set_serialized_result(parser, type) : set_error_result(parser);
    }

    rbs_parser_free(parser);
    return status;
}

/**
 * Parse a single RBS method type.
 *
 * @param variables Newline-separated type variable names (length < 0 for none).
 * @return 1 on success, 0 on a parse error. On success with an empty result,
 *         the input was empty (`nil`).
 */
__attribute__((export_name("rbs_wasm_parse_method_type"))) int rbs_wasm_parse_method_type(const char *source, int length, int start_pos, int end_pos, const char *variables, int variables_length, int require_eof) {
    rbs_string_t string = rbs_string_new(source, source + length);
    rbs_parser_t *parser = rbs_parser_new(string, RBS_ENCODING_UTF_8_ENTRY, start_pos, end_pos);
    declare_variables(parser, variables, variables_length);

    int status;
    if (parser->next_token.type == pEOF) {
        allocate_result(0);
        status = 1;
    } else {
        rbs_method_type_t *method_type = NULL;
        rbs_parse_method_type(parser, &method_type, require_eof != 0, true);

        status = parser->error == NULL ? set_serialized_result(parser, (rbs_node_t *) method_type) : set_error_result(parser);
    }

    rbs_parser_free(parser);
    return status;
}

/**
 * Parse a small, fixed RBS document, used as a build smoke test
 * (`wasmtime run --invoke rbs_wasm_selftest rbs_parser.wasm`).
 *
 * @return 1 if the sample parsed successfully, 0 otherwise.
 */
__attribute__((export_name("rbs_wasm_selftest"))) int rbs_wasm_selftest(void) {
    static const char source[] =
        "class User\n"
        "  attr_reader name: String\n"
        "  def initialize: (String name) -> void\n"
        "end\n";

    int length = (int) (sizeof(source) - 1);
    return rbs_wasm_parse_signature(source, length, 0, length);
}
