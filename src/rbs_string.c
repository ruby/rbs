#include "rbs/rbs_string.h"

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <ctype.h>

rbs_string_t rbs_string_shared_new(const char *start, const char *end) {
    return (rbs_string_t) {
        .start = start,
        .end = end,
        .type = RBS_STRING_SHARED,
    };
}

rbs_string_t rbs_string_owned_new(const char *start, const char *end) {
    return (rbs_string_t) {
        .start = start,
        .end = end,
        .type = RBS_STRING_OWNED,
    };
}

void rbs_string_ensure_owned(rbs_string_t *self) {
    if (self->type == RBS_STRING_OWNED) return;

    char *buffer = (char *)malloc(self->end - self->start + 1);
    size_t length = self->end - self->start;

    strncpy(buffer, self->start, length);
    buffer[length] = '\0';

    *self = rbs_string_owned_new(buffer, buffer + length);
}

rbs_string_t rbs_string_offset(const rbs_string_t self, const size_t offset) {
    return rbs_string_shared_new(self.start + offset, self.end);
}

// // Ensure the given string is shared, so that we can slice it without needing to free the old string.
// static void ensure_shared(rbs_string_t *self) {
//     if (self->type != RBS_STRING_SHARED) {
//         fprintf(stderr, "Calling this function requires a shared string.\n");
//         exit(EXIT_FAILURE);
//     }
// }

void rbs_string_drop_first(rbs_string_t *self, size_t n) {
    // ensure_shared(self);

    self->start += n;
}

void rbs_string_drop_last(rbs_string_t *self, size_t n) {
    // ensure_shared(self);

    self->end -= n;
}

void rbs_string_limit_length(rbs_string_t *self, size_t new_length) {
    // ensure_shared(self);

    self->end = self->start + new_length;
}

rbs_string_t rbs_string_slice(const rbs_string_t self, size_t start_inset, size_t length) {
    if (length > rbs_string_len(self)) {
        fprintf(stderr, "rbs_string_slice tried to slice more characters than exist in the string.\n");
        exit(EXIT_FAILURE);
    }

    if (self.start + start_inset + length >= self.end) {
        fprintf(stderr, "rbs_string_slice tried to slice past the end of the string.\n");
        exit(EXIT_FAILURE);
    }

    const char *new_start = self.start + start_inset;

    return rbs_string_shared_new(new_start, new_start + length);
}

void rbs_string_strip_whitespace(rbs_string_t *self) {
    // ensure_shared(self);

    const char *new_start = self->start;
    while (isspace(*new_start) && new_start < self->end) {
        new_start++;
    }

    if (new_start == self->end) { // Handle empty string case
        self->start = new_start;
        return;
    }

    const char *new_end = self->end - 1;
    while (isspace(*new_end) && new_start < new_end) {
        new_end--;
    }

    self->start = new_start;
    self->end = new_end + 1;
}

size_t rbs_string_len(const rbs_string_t self) {
    return self.end - self.start;
}

bool rbs_string_equal(const rbs_string_t lhs, const rbs_string_t rhs) {
    if (lhs.start == rhs.start && lhs.end == rhs.end) return true;
    if (rbs_string_len(lhs) != rbs_string_len(rhs)) return false;
    return strncmp(lhs.start, rhs.start, rbs_string_len(lhs)) == 0;
}
