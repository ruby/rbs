#ifndef RBS__RBS_STRING_H
#define RBS__RBS_STRING_H

#include <stddef.h>
#include <stdbool.h>

typedef struct {
  const char *start;
  const char *end;

  enum rbs_string_type {
    /** This string is a constant string, and should not be freed. */
    RBS_STRING_CONSTANT,
    /** This is a slice of another string, and should not be freed. */
    RBS_STRING_SHARED,
    /** This string owns its memory, and should be freed using `rbs_string_free`. */
    RBS_STRING_OWNED,
  } type;
} rbs_string_t;

#define RBS_STRING_NULL ((rbs_string_t) { \
    .start = NULL,                        \
    .end = NULL,                          \
    .type = RBS_STRING_CONSTANT,          \
  })

/**
 * Returns a new `rbs_string_t` struct that points to the given C string without owning it.
 */
rbs_string_t rbs_string_shared_new(const char *start, const char *end);

/**
 * Returns a new `rbs_string_t` struct that owns its memory.
 */
rbs_string_t rbs_string_owned_new(const char *start, const char *end);

/**
 * Ensures that the given string is owned, so that it manages its own memory, uncoupled from its original source.
 */
void rbs_string_ensure_owned(rbs_string_t *self);

/**
 * Returns a new `rbs_string_t` with its start shifted forward by the given amount.
 * This returns a shared string which points to the same memory as the original string.
 */
rbs_string_t rbs_string_offset(const rbs_string_t self, size_t offset);

/**
 * Modifies the given string to drop its first `n` characters.
 */
void rbs_string_drop_first(rbs_string_t *self, size_t n);

/**
 * Modifies the given string to drop its last `n` characters.
 */
void rbs_string_drop_last(rbs_string_t *self, size_t n);

/**
 * Modifies the given string to limit its length to the given number of characters.
 */
void rbs_string_limit_length(rbs_string_t *self, size_t new_length);

/**
 * Copies a portion of the input string into a new owned string.
 * @param start_inset Number of characters to exclude from the start
 * @param length Number of characters to include
 */
rbs_string_t rbs_string_slice(const rbs_string_t self, size_t start_inset, size_t length);

/**
 * Drops the leading and trailing whitespace from the given string, in-place.
 */
void rbs_string_strip_whitespace(rbs_string_t *self);

/**
 * Returns the length of the string.
 */
size_t rbs_string_len(const rbs_string_t self);

/**
 * Compares two strings for equality.
 */
bool rbs_string_equal(const rbs_string_t lhs, const rbs_string_t rhs);

#endif
