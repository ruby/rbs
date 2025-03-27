#include "rbs/encoding.h"

unsigned int rbs_utf8_to_codepoint(const rbs_string_t string) {
    unsigned int codepoint = 0;
    int remaining_bytes = 0;

    const char *s = string.start;
    const char *end = string.end;

    if (s >= end) return 0;  // End of string

    if ((*s & 0x80) == 0) {
        // Single byte character (0xxxxxxx)
        return *s;
    } else if ((*s & 0xE0) == 0xC0) {
        // Two byte character (110xxxxx 10xxxxxx)
        codepoint = *s & 0x1F;
        remaining_bytes = 1;
    } else if ((*s & 0xF0) == 0xE0) {
        // Three byte character (1110xxxx 10xxxxxx 10xxxxxx)
        codepoint = *s & 0x0F;
        remaining_bytes = 2;
    } else if ((*s & 0xF8) == 0xF0) {
        // Four byte character (11110xxx 10xxxxxx 10xxxxxx 10xxxxxx)
        codepoint = *s & 0x07;
        remaining_bytes = 3;
    } else {
        // Invalid UTF-8 sequence
        return 0xFFFD;  // Unicode replacement character
    }

    s++;
    while (remaining_bytes > 0 && s < end) {
        if ((*s & 0xC0) != 0x80) {
            // Invalid continuation byte
            return 0xFFFD;
        }
        codepoint = (codepoint << 6) | (*s & 0x3F);
        s++;
        remaining_bytes--;
    }

    if (remaining_bytes > 0) {
        // Incomplete sequence
        return 0xFFFD;
    }

    return codepoint;
}

int rbs_utf8_codelen(unsigned int c) {
    if (c <= 0x7F) return 1;
    if (c <= 0x7FF) return 2;
    if (c <= 0xFFFF) return 3;
    if (c <= 0x10FFFF) return 4;
    return 1; // Invalid Unicode codepoint, treat as 1 byte
}
