#include "rbs/string.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

unsigned int rbs_utf8_string_to_codepoint(const rbs_string_t string) {
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

rbs_string_t rbs_string_new(const char *start, const char *end) {
    return (rbs_string_t) {
        .start = start,
        .end = end,
    };
}

rbs_string_t rbs_string_strip_whitespace(rbs_string_t *self) {
    const char *new_start = self->start;
    while (isspace(*new_start) && new_start < self->end) {
        new_start++;
    }

    if (new_start == self->end) { // Handle empty string case
        return rbs_string_new(new_start, new_start);
    }

    const char *new_end = self->end - 1;
    while (isspace(*new_end) && new_start < new_end) {
        new_end--;
    }

    return rbs_string_new(new_start, new_end + 1);
}

size_t rbs_string_len(const rbs_string_t self) {
    return self.end - self.start;
}

bool rbs_string_equal(const rbs_string_t lhs, const rbs_string_t rhs) {
    if (lhs.start == rhs.start && lhs.end == rhs.end) return true;
    if (rbs_string_len(lhs) != rbs_string_len(rhs)) return false;
    return strncmp(lhs.start, rhs.start, rbs_string_len(lhs)) == 0;
}
