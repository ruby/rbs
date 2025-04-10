#include "rbs/util/rbs_unescape.h"
#include <string.h>
#include <stdlib.h>
#include <ctype.h>

// Define the escape character mappings
// TODO: use a switch instead
static const struct {
    const char* from;
    const char* to;
} TABLE[] = {
    {"\\a", "\a"},
    {"\\b", "\b"},
    {"\\e", "\033"},
    {"\\f", "\f"},
    {"\\n", "\n"},
    {"\\r", "\r"},
    {"\\s", " "},
    {"\\t", "\t"},
    {"\\v", "\v"},
    {"\\\"", "\""},
    {"\\'", "'"},
    {"\\\\", "\\"},
    {"\\", ""}
};

// Helper function to convert hex string to integer
static int hex_to_int(const char* hex, int length) {
    int result = 0;
    for (int i = 0; i < length; i++) {
        result = result * 16 + (isdigit(hex[i]) ? hex[i] - '0' : tolower(hex[i]) - 'a' + 10);
    }
    return result;
}

// Helper function to convert octal string to integer
static int octal_to_int(const char* octal, int length) {
    int result = 0;
    for (int i = 0; i < length; i++) {
        result = result * 8 + (octal[i] - '0');
    }
    return result;
}

int rbs_utf8_codelen(unsigned int c) {
    if (c <= 0x7F) return 1;
    if (c <= 0x7FF) return 2;
    if (c <= 0xFFFF) return 3;
    if (c <= 0x10FFFF) return 4;
    return 1; // Invalid Unicode codepoint, treat as 1 byte
}

rbs_string_t unescape_string(rbs_allocator_t *allocator, const rbs_string_t string, bool is_double_quote) {
    if (!string.start) return RBS_STRING_NULL;

    size_t len = string.end - string.start;
    const char* input = string.start;

    char* output = rbs_allocator_alloc_many(allocator, len + 1, char);
    if (!output) return RBS_STRING_NULL;

    size_t i = 0, j = 0;
    while (i < len) {
        if (input[i] == '\\' && i + 1 < len) {
            if (is_double_quote) {
                if (isdigit(input[i+1])) {
                    // Octal escape
                    int octal_len = 1;
                    while (octal_len < 3 && i + 1 + octal_len < len && isdigit(input[i + 1 + octal_len])) octal_len++;
                    int value = octal_to_int(input + i + 1, octal_len);
                    output[j++] = (char)value;
                    i += octal_len + 1;
                } else if (input[i+1] == 'x' && i + 3 < len) {
                    // Hex escape
                    int hex_len = isxdigit(input[i+3]) ? 2 : 1;
                    int value = hex_to_int(input + i + 2, hex_len);
                    output[j++] = (char)value;
                    i += hex_len + 2;
                } else if (input[i+1] == 'u' && i + 5 < len) {
                    // Unicode escape
                    int value = hex_to_int(input + i + 2, 4);
                    output[j++] = (char)value;
                    i += 6;
                } else {
                    // Other escapes
                    int found = 0;
                    for (size_t k = 0; k < sizeof(TABLE) / sizeof(TABLE[0]); k++) {
                        if (strncmp(input + i, TABLE[k].from, strlen(TABLE[k].from)) == 0) {
                            output[j++] = TABLE[k].to[0];
                            i += strlen(TABLE[k].from);
                            found = 1;
                            break;
                        }
                    }
                    if (!found) {
                        output[j++] = input[i++];
                    }
                }
            } else {
                /* Single quote: only escape ' and \ */
                if (input[i+1] == '\'' || input[i+1] == '\\') {
                    output[j++] = input[i+1];
                    i += 2;
                } else {
                    output[j++] = input[i++];
                }
            }
        } else {
            output[j++] = input[i++];
        }
    }
    output[j] = '\0';
    return rbs_string_new(output, output + j);
}

rbs_string_t rbs_unquote_string(rbs_allocator_t *allocator, rbs_string_t input) {
    unsigned int first_char = rbs_utf8_string_to_codepoint(input);
    size_t byte_length = rbs_string_len(input);

    ptrdiff_t start_offset = 0;
    if (first_char == '"' || first_char == '\'' || first_char == '`') {
      int bs = rbs_utf8_codelen(first_char);
      start_offset += bs;
      byte_length -= 2 * bs;
    }

    const char *new_start = input.start + start_offset;
    rbs_string_t string = rbs_string_new(new_start, new_start + byte_length);
    return unescape_string(allocator, string, first_char == '"');
}
