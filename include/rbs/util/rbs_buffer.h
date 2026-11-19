#ifndef RBS__RBS_BUFFER_H
#define RBS__RBS_BUFFER_H

#include "rbs/util/rbs_allocator.h"
#include "rbs/string.h"

#include <stdbool.h>
#include <stdlib.h>
#include <string.h>

/**
 * A rbs_buffer_t is a simple memory buffer that stores data in a contiguous block of memory.
 */
typedef struct {
    /** The length of the buffer in bytes. */
    size_t length;

    /** The capacity of the buffer in bytes that has been allocated. */
    size_t capacity;

    /** A pointer to the start of the buffer. */
    char *value;
} rbs_buffer_t;

/**
 * Initialize a rbs_buffer_t with its default values.
 *
 * @param allocator The allocator to use.
 * @param buffer The buffer to initialize.
 * @returns True if the buffer was initialized successfully, false otherwise.
 */
bool rbs_buffer_init(rbs_allocator_t *, rbs_buffer_t *buffer);

bool rbs_buffer_init_with_capacity(rbs_allocator_t *allocator, rbs_buffer_t *buffer, size_t capacity);

/**
 * Return the value of the buffer.
 *
 * @param buffer The buffer to get the value of.
 * @returns The value of the buffer.
 */
char *rbs_buffer_value(const rbs_buffer_t *buffer);

/**
 * Return the length of the buffer.
 *
 * @param buffer The buffer to get the length of.
 * @returns The length of the buffer.
 */
size_t rbs_buffer_length(const rbs_buffer_t *buffer);

/**
 * Append a C string to the buffer.
 *
 * @param allocator The allocator to use.
 * @param buffer The buffer to append to.
 * @param value The C string to append.
 */
void rbs_buffer_append_cstr(rbs_allocator_t *, rbs_buffer_t *buffer, const char *value);

/**
 * Append a string to the buffer.
 *
 * @param allocator The allocator to use.
 * @param buffer The buffer to append to.
 * @param value The string to append.
 * @param length The length of the string to append.
 */
void rbs_buffer_append_string(rbs_allocator_t *, rbs_buffer_t *buffer, const char *value, size_t length);

/**
 * Convert the buffer to a rbs_string_t.
 *
 * @param buffer The buffer to convert.
 * @returns The converted rbs_string_t.
 */
rbs_string_t rbs_buffer_to_string(rbs_buffer_t *buffer);

/**
 * Append a value to the buffer.
 *
 * @param allocator The allocator to use.
 * @param buffer The buffer to append to.
 * @param value The value to append.
 * @param type The type of the value to append, which determines how many bytes to append.
 */
#define rbs_buffer_append_value(allocator, buffer, value, type) \
    rbs_buffer_append_string((allocator), (buffer), (char *) (value), sizeof(type))

/**
 * Returns a copy of a `type` from the `buffer` at the given `index`.
 *
 * This cast is unchecked, so it's up to caller to ensure the type is correct.
 * Note: This assumes the buffer contains only elements of the specified type.
 *
 * @param buffer The buffer to get the value from.
 * @param index The index of the element to retrieve.
 * @param type The element type that the data will be cast to.
 * @returns The value at the specified index, cast to the specified type.
 */
#define rbs_buffer_get(buffer, index, type) ( \
    ((type *) (buffer).value)[index]          \
)

#endif
