/**
 * FFI entry points for non-MRI Ruby implementations (JRuby, TruffleRuby).
 *
 * These functions provide a one-shot, Ruby-independent API on top of the
 * core parser. Each call parses (or lexes) the given source and returns an
 * `rbs_ffi_result_t` holding a serialized byte buffer. The caller reads the
 * bytes with `rbs_ffi_result_bytes()` / `rbs_ffi_result_length()` and then
 * releases everything with `rbs_ffi_result_free()`.
 *
 * Each entry point mirrors the control flow of the corresponding
 * `rbsparser_*` function in ext/rbs_extension/main.c.
 *
 * The byte format is private to RBS: it is produced and consumed by the same
 * gem version (see lib/rbs/parser/ffi.rb and
 * lib/rbs/parser/deserializer.rb), so it carries no versioning or
 * compatibility guarantees.
 *
 * All integers are encoded in little-endian byte order, independent of the
 * host platform.
 */

#include "rbs.h"
#include "rbs/serializer.h"
#include "rbs/util/rbs_buffer.h"
#include "rbs/util/rbs_encoding.h"

#include <stdint.h>
#include <stdlib.h>
#include <string.h>

typedef struct rbs_ffi_result {
    rbs_allocator_t *allocator;
    rbs_buffer_t buffer;
} rbs_ffi_result_t;

/* Status bytes prefixed to every result. */
enum {
    RBS_FFI_STATUS_SUCCESS = 0,
    RBS_FFI_STATUS_ERROR = 1,
    RBS_FFI_STATUS_NIL = 2,
};

static rbs_ffi_result_t *rbs_ffi_result_new(void) {
    rbs_allocator_t *allocator = rbs_allocator_init();
    rbs_ffi_result_t *result = (rbs_ffi_result_t *) malloc(sizeof(rbs_ffi_result_t));
    result->allocator = allocator;
    rbs_buffer_init(allocator, &result->buffer);
    return result;
}

const char *rbs_ffi_result_bytes(const rbs_ffi_result_t *result) {
    return rbs_buffer_value(&result->buffer);
}

size_t rbs_ffi_result_length(const rbs_ffi_result_t *result) {
    return rbs_buffer_length(&result->buffer);
}

void rbs_ffi_result_free(rbs_ffi_result_t *result) {
    rbs_allocator_free(result->allocator);
    free(result);
}

static rbs_serializer_t result_serializer(rbs_ffi_result_t *result, const rbs_parser_t *parser) {
    return (rbs_serializer_t) {
        .allocator = result->allocator,
        .buffer = &result->buffer,
        .constant_pool = parser ? &parser->constant_pool : NULL,
    };
}

static void append_u8(rbs_ffi_result_t *result, uint8_t value) {
    rbs_buffer_append_string(result->allocator, &result->buffer, (const char *) &value, 1);
}

static void append_u32(rbs_ffi_result_t *result, uint32_t value) {
    char bytes[4] = {
        (char) (value & 0xff),
        (char) ((value >> 8) & 0xff),
        (char) ((value >> 16) & 0xff),
        (char) ((value >> 24) & 0xff),
    };
    rbs_buffer_append_string(result->allocator, &result->buffer, bytes, 4);
}

static void append_i32(rbs_ffi_result_t *result, int32_t value) {
    append_u32(result, (uint32_t) value);
}

static void append_str(rbs_ffi_result_t *result, const char *value, size_t length) {
    append_u32(result, (uint32_t) length);
    rbs_buffer_append_string(result->allocator, &result->buffer, value, length);
}

static void append_cstr(rbs_ffi_result_t *result, const char *value) {
    append_str(result, value, strlen(value));
}

static const rbs_encoding_t *find_encoding(const char *enc_name) {
    const rbs_encoding_t *encoding = rbs_encoding_find(
        (const uint8_t *) enc_name,
        (const uint8_t *) (enc_name + strlen(enc_name))
    );
    if (encoding == NULL) {
        encoding = &rbs_encodings[RBS_ENCODING_UTF_8];
    }
    return encoding;
}

/**
 * Serializes the parser's error:
 *
 *   u8 status (RBS_FFI_STATUS_ERROR)
 *   u8 syntax error flag
 *   u32 length + bytes of message
 *   u32 length + bytes of token type name
 *   i32 token start char, i32 token end char
 */
static void serialize_error(rbs_ffi_result_t *result, const rbs_error_t *error) {
    append_u8(result, RBS_FFI_STATUS_ERROR);
    append_u8(result, error->syntax_error ? 1 : 0);
    append_cstr(result, error->message);
    append_cstr(result, rbs_token_type_str(error->token.type));
    append_i32(result, error->token.range.start.char_pos);
    append_i32(result, error->token.range.end.char_pos);
}

static uint32_t read_u32le(const char *bytes) {
    return (uint32_t) (uint8_t) bytes[0] |
        ((uint32_t) (uint8_t) bytes[1] << 8) |
        ((uint32_t) (uint8_t) bytes[2] << 16) |
        ((uint32_t) (uint8_t) bytes[3] << 24);
}

/**
 * Declares type variables in the parser, replicating
 * `declare_type_variables()` in ext/rbs_extension/main.c.
 *
 * `vars` is a packed buffer: u32 count, then (u32 length, bytes) per
 * variable name. May be NULL when there are no variables.
 *
 * Returns false when insertion fails, with the error serialized into the
 * result.
 */
static bool declare_type_variables(rbs_parser_t *parser, const char *vars, rbs_ffi_result_t *result) {
    if (vars == NULL) return true;

    rbs_parser_push_typevar_table(parser, true);

    const char *cursor = vars;
    uint32_t count = read_u32le(cursor);
    cursor += 4;

    for (uint32_t i = 0; i < count; i++) {
        uint32_t length = read_u32le(cursor);
        cursor += 4;

        uint8_t *copied_name = (uint8_t *) malloc(length);
        memcpy(copied_name, cursor, length);
        cursor += length;

        rbs_constant_id_t id = rbs_constant_pool_insert_owned(
            &parser->constant_pool,
            copied_name,
            length
        );

        if (!rbs_parser_insert_typevar(parser, id)) {
            serialize_error(result, parser->error);
            return false;
        }
    }

    return true;
}

/**
 * Lexes the given source and serializes the resulting token list:
 *
 *   u8 status (RBS_FFI_STATUS_SUCCESS)
 *   u32 token count
 *   tokens: (u32 length + bytes of token type name, i32 start char, i32 end char)*
 *
 * The token list includes the trailing pEOF token, mirroring
 * `RBS::Parser._lex` in ext/rbs_extension/main.c.
 */
rbs_ffi_result_t *rbs_ffi_lex(const char *src, size_t len, const char *enc_name, int end_pos) {
    rbs_ffi_result_t *result = rbs_ffi_result_new();

    rbs_allocator_t *allocator = rbs_allocator_init();
    rbs_string_t string = rbs_string_new(src, src + len);
    rbs_lexer_t *lexer = rbs_lexer_new(allocator, string, find_encoding(enc_name), 0, end_pos);

    append_u8(result, RBS_FFI_STATUS_SUCCESS);

    /* Reserve the count slot; patched after the token loop below. */
    size_t count_offset = rbs_buffer_length(&result->buffer);
    append_u32(result, 0);

    uint32_t count = 0;
    rbs_token_t token = NullToken;
    while (token.type != pEOF) {
        token = rbs_lexer_next_token(lexer);
        append_cstr(result, rbs_token_type_str(token.type));
        append_i32(result, token.range.start.char_pos);
        append_i32(result, token.range.end.char_pos);
        count++;
    }

    char *count_slot = rbs_buffer_value(&result->buffer) + count_offset;
    count_slot[0] = (char) (count & 0xff);
    count_slot[1] = (char) ((count >> 8) & 0xff);
    count_slot[2] = (char) ((count >> 16) & 0xff);
    count_slot[3] = (char) ((count >> 24) & 0xff);

    rbs_allocator_free(allocator);

    return result;
}

rbs_ffi_result_t *rbs_ffi_parse_type(
    const char *src,
    size_t len,
    const char *enc_name,
    int start_pos,
    int end_pos,
    const char *vars,
    bool require_eof,
    bool void_allowed,
    bool self_allowed,
    bool classish_allowed
) {
    rbs_ffi_result_t *result = rbs_ffi_result_new();

    rbs_string_t string = rbs_string_new(src, src + len);
    rbs_parser_t *parser = rbs_parser_new(string, find_encoding(enc_name), start_pos, end_pos);

    if (!declare_type_variables(parser, vars, result)) {
        rbs_parser_free(parser);
        return result;
    }

    if (parser->next_token.type == pEOF) {
        append_u8(result, RBS_FFI_STATUS_NIL);
        rbs_parser_free(parser);
        return result;
    }

    rbs_node_t *type;
    rbs_parse_type(parser, &type, void_allowed, self_allowed, classish_allowed);

    if (parser->error != NULL) {
        serialize_error(result, parser->error);
        rbs_parser_free(parser);
        return result;
    }

    if (require_eof) {
        rbs_parser_advance(parser);
        if (parser->current_token.type != pEOF) {
            rbs_parser_set_error(parser, parser->current_token, true, "expected a token `%s`", rbs_token_type_str(pEOF));
            serialize_error(result, parser->error);
            rbs_parser_free(parser);
            return result;
        }
    }

    append_u8(result, RBS_FFI_STATUS_SUCCESS);
    rbs_serializer_t serializer = result_serializer(result, parser);
    rbs_serializer_write_node(&serializer, type);

    rbs_parser_free(parser);
    return result;
}

rbs_ffi_result_t *rbs_ffi_parse_method_type(
    const char *src,
    size_t len,
    const char *enc_name,
    int start_pos,
    int end_pos,
    const char *vars,
    bool require_eof
) {
    rbs_ffi_result_t *result = rbs_ffi_result_new();

    rbs_string_t string = rbs_string_new(src, src + len);
    rbs_parser_t *parser = rbs_parser_new(string, find_encoding(enc_name), start_pos, end_pos);

    if (!declare_type_variables(parser, vars, result)) {
        rbs_parser_free(parser);
        return result;
    }

    if (parser->next_token.type == pEOF) {
        append_u8(result, RBS_FFI_STATUS_NIL);
        rbs_parser_free(parser);
        return result;
    }

    rbs_method_type_t *method_type = NULL;
    rbs_parse_method_type(parser, &method_type, require_eof, true);

    if (parser->error != NULL) {
        serialize_error(result, parser->error);
        rbs_parser_free(parser);
        return result;
    }

    append_u8(result, RBS_FFI_STATUS_SUCCESS);
    rbs_serializer_t serializer = result_serializer(result, parser);
    rbs_serializer_write_node(&serializer, (rbs_node_t *) method_type);

    rbs_parser_free(parser);
    return result;
}

rbs_ffi_result_t *rbs_ffi_parse_signature(
    const char *src,
    size_t len,
    const char *enc_name,
    int start_pos,
    int end_pos
) {
    rbs_ffi_result_t *result = rbs_ffi_result_new();

    rbs_string_t string = rbs_string_new(src, src + len);
    rbs_parser_t *parser = rbs_parser_new(string, find_encoding(enc_name), start_pos, end_pos);

    rbs_signature_t *signature = NULL;
    rbs_parse_signature(parser, &signature);

    if (parser->error != NULL) {
        serialize_error(result, parser->error);
        rbs_parser_free(parser);
        return result;
    }

    append_u8(result, RBS_FFI_STATUS_SUCCESS);
    rbs_serializer_t serializer = result_serializer(result, parser);
    rbs_serializer_write_node(&serializer, (rbs_node_t *) signature);

    rbs_parser_free(parser);
    return result;
}

rbs_ffi_result_t *rbs_ffi_parse_type_params(
    const char *src,
    size_t len,
    const char *enc_name,
    int start_pos,
    int end_pos,
    bool module_type_params
) {
    rbs_ffi_result_t *result = rbs_ffi_result_new();

    rbs_string_t string = rbs_string_new(src, src + len);
    rbs_parser_t *parser = rbs_parser_new(string, find_encoding(enc_name), start_pos, end_pos);

    if (parser->next_token.type == pEOF) {
        append_u8(result, RBS_FFI_STATUS_NIL);
        rbs_parser_free(parser);
        return result;
    }

    rbs_node_list_t *params = NULL;
    rbs_parse_type_params(parser, module_type_params, &params);

    if (parser->error != NULL) {
        serialize_error(result, parser->error);
        rbs_parser_free(parser);
        return result;
    }

    append_u8(result, RBS_FFI_STATUS_SUCCESS);
    rbs_serializer_t serializer = result_serializer(result, parser);
    rbs_serializer_write_node_list(&serializer, params);

    rbs_parser_free(parser);
    return result;
}

typedef bool (*rbs_parse_inline_annotation_func)(rbs_parser_t *, rbs_ast_ruby_annotations_t **);

static rbs_ffi_result_t *parse_inline_annotation(
    const char *src,
    size_t len,
    const char *enc_name,
    int start_pos,
    int end_pos,
    const char *vars,
    rbs_parse_inline_annotation_func parse
) {
    rbs_ffi_result_t *result = rbs_ffi_result_new();

    rbs_string_t string = rbs_string_new(src, src + len);
    rbs_parser_t *parser = rbs_parser_new(string, find_encoding(enc_name), start_pos, end_pos);

    if (!declare_type_variables(parser, vars, result)) {
        rbs_parser_free(parser);
        return result;
    }

    rbs_ast_ruby_annotations_t *annotation = NULL;
    bool success = parse(parser, &annotation);

    if (parser->error != NULL) {
        serialize_error(result, parser->error);
        rbs_parser_free(parser);
        return result;
    }

    if (!success || annotation == NULL) {
        append_u8(result, RBS_FFI_STATUS_NIL);
        rbs_parser_free(parser);
        return result;
    }

    append_u8(result, RBS_FFI_STATUS_SUCCESS);
    rbs_serializer_t serializer = result_serializer(result, parser);
    rbs_serializer_write_node(&serializer, (rbs_node_t *) annotation);

    rbs_parser_free(parser);
    return result;
}

rbs_ffi_result_t *rbs_ffi_parse_inline_leading_annotation(
    const char *src,
    size_t len,
    const char *enc_name,
    int start_pos,
    int end_pos,
    const char *vars
) {
    return parse_inline_annotation(src, len, enc_name, start_pos, end_pos, vars, rbs_parse_inline_leading_annotation);
}

rbs_ffi_result_t *rbs_ffi_parse_inline_trailing_annotation(
    const char *src,
    size_t len,
    const char *enc_name,
    int start_pos,
    int end_pos,
    const char *vars
) {
    return parse_inline_annotation(src, len, enc_name, start_pos, end_pos, vars, rbs_parse_inline_trailing_annotation);
}
