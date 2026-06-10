/**
 * FFI entry points for non-MRI Ruby implementations (JRuby, TruffleRuby).
 *
 * These functions provide a one-shot, Ruby-independent API on top of the
 * core parser. Each call parses (or lexes) the given source and returns an
 * `rbs_ffi_result_t` holding a serialized byte buffer. The caller reads the
 * bytes with `rbs_ffi_result_bytes()` / `rbs_ffi_result_length()` and then
 * releases everything with `rbs_ffi_result_free()`.
 *
 * The byte format is private to RBS: it is produced and consumed by the same
 * gem version (see lib/rbs/parser/ffi.rb), so it carries no versioning or
 * compatibility guarantees.
 *
 * All integers are encoded in little-endian byte order, independent of the
 * host platform.
 */

#include "rbs.h"
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
