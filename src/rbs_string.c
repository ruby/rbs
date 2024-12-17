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

rbs_string_t rbs_string_copy_slice(rbs_string_t *self, size_t start_inset, size_t length) {
    char *buffer = (char *) malloc(length + 1);
    strncpy(buffer, self->start + start_inset, length);
    buffer[length] = '\0';

    return rbs_string_owned_new(buffer, buffer + length);
}

void rbs_string_free_if_needed(rbs_string_t *self) {
    if (self->type == RBS_STRING_OWNED) {
        rbs_string_free(self);
    }
}

void rbs_string_free(rbs_string_t *self) {
    if (self->type != RBS_STRING_OWNED) {
        fprintf(stderr, "rbs_string_free(%p): not owned\n", self->start);
        exit(EXIT_FAILURE);
    }

    free((void *) self->start);
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

rbs_string_t rbs_string_strip_whitespace(rbs_string_t *self) {
    // ensure_shared(self);

    const char *new_start = self->start;
    while (isspace(*new_start) && new_start < self->end) {
        new_start++;
    }

    if (new_start == self->end) { // Handle empty string case
        return rbs_string_shared_new(new_start, new_start);
    }

    const char *new_end = self->end - 1;
    while (isspace(*new_end) && new_start < new_end) {
        new_end--;
    }

    return rbs_string_copy_slice(self, new_start - self->start, new_end - new_start + 1);
}

size_t rbs_string_len(const rbs_string_t self) {
    return self.end - self.start;
}

bool rbs_string_equal(const rbs_string_t lhs, const rbs_string_t rhs) {
    if (lhs.start == rhs.start && lhs.end == rhs.end) return true;
    if (rbs_string_len(lhs) != rbs_string_len(rhs)) return false;
    return strncmp(lhs.start, rhs.start, rbs_string_len(lhs)) == 0;
}
