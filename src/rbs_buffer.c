#include "rbs/rbs_buffer.h"

bool rbs_buffer_init_capacity(rbs_buffer_t *buffer, size_t capacity) {
    buffer->length = 0;
    buffer->capacity = capacity;

    buffer->value = (char *) malloc(capacity);
    return buffer->value != NULL;
}

bool rbs_buffer_init(rbs_buffer_t *buffer) {
    return rbs_buffer_init_capacity(buffer, 1024);
}

char *rbs_buffer_value(const rbs_buffer_t *buffer) {
    return buffer->value;
}

size_t rbs_buffer_length(const rbs_buffer_t *buffer) {
    return buffer->length;
}

static inline bool rbs_buffer_append_length(rbs_buffer_t *buffer, size_t length) {
    size_t next_length = buffer->length + length;

    if (next_length > buffer->capacity) {
        if (buffer->capacity == 0) {
            buffer->capacity = 1;
        }

        while (next_length > buffer->capacity) {
            buffer->capacity *= 2;
        }

        buffer->value = realloc(buffer->value, buffer->capacity);
        if (buffer->value == NULL) return false;
    }

    buffer->length = next_length;
    return true;
}

static inline void rbs_buffer_append(rbs_buffer_t *buffer, const void *source, size_t length) {
    size_t cursor = buffer->length;
    if (rbs_buffer_append_length(buffer, length)) {
        memcpy(buffer->value + cursor, source, length);
    }
}

void rbs_buffer_append_cstr(rbs_buffer_t *buffer, const char *value) {
    rbs_buffer_append(buffer, value, strlen(value));
}

void rbs_buffer_append_string(rbs_buffer_t *buffer, const char *value, size_t length) {
    rbs_buffer_append(buffer, value, length);
}

rbs_string_t rbs_buffer_to_string(rbs_buffer_t *buffer) {
    return rbs_string_shared_new(buffer->value, buffer->value + buffer->length);
}

void rbs_buffer_free(rbs_buffer_t *buffer) {
    free(buffer->value);
}
