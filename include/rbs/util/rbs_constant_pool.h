/**
 * @file rbs_constant_pool.h
 *
 * A data structure that stores a set of strings.
 *
 * Each string is assigned a unique id, which can be used to compare strings for
 * equality. This comparison ends up being much faster than strcmp, since it
 * only requires a single integer comparison.
 */
#ifndef RBS_CONSTANT_POOL_H
#define RBS_CONSTANT_POOL_H

#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

/**
 * When we allocate constants into the pool, we reserve 0 to mean that the slot
 * is not yet filled. This constant is reused in other places to indicate the
 * lack of a constant id.
 */
#define RBS_CONSTANT_ID_UNSET 0

/**
 * A constant id is a unique identifier for a constant in the constant pool.
 */
typedef uintptr_t rbs_constant_id_t;

/** A constant in the pool which effectively stores a string. */
typedef uintptr_t rbs_constant_t;

/** The overall constant pool, which stores constants found while parsing. */
typedef struct {
    void *dummy; // Workaround for structs not being allowed to be empty.
} rbs_constant_pool_t;

// A temporary stand-in for the constant pool until start using a real implementation.
// For now, it just defers to Ruby's ID interning mechanism (`rb_intern3`).
extern rbs_constant_pool_t *RBS_GLOBAL_CONSTANT_POOL;

/**
 * Initialize a new constant pool with a given capacity.
 *
 * @param pool The pool to initialize.
 * @param capacity The initial capacity of the pool.
 * @return Whether the initialization succeeded.
 */
bool rbs_constant_pool_init(rbs_constant_pool_t *pool, uint32_t capacity);

/**
 * Return a pointer to the constant indicated by the given constant id.
 *
 * @param pool The pool to get the constant from.
 * @param constant_id The id of the constant to get.
 * @return A pointer to the constant.
 */
rbs_constant_t * rbs_constant_pool_id_to_constant(const rbs_constant_pool_t *pool, rbs_constant_id_t constant_id);

/**
 * Find a constant in a constant pool. Returns the id of the constant, or 0 if
 * the constant is not found.
 *
 * @param pool The pool to find the constant in.
 * @param start A pointer to the start of the constant.
 * @param length The length of the constant.
 * @return The id of the constant.
 */
rbs_constant_id_t rbs_constant_pool_find(const rbs_constant_pool_t *pool, const uint8_t *start, size_t length);

/**
 * Insert a constant into a constant pool that is a slice of a source string.
 * Returns the id of the constant, or 0 if any potential calls to resize fail.
 *
 * @param pool The pool to insert the constant into.
 * @param start A pointer to the start of the constant.
 * @param length The length of the constant.
 * @return The id of the constant.
 */
rbs_constant_id_t rbs_constant_pool_insert_shared(rbs_constant_pool_t *pool, const uint8_t *start, size_t length);

/**
 * Insert a constant into a constant pool from memory that is constant. Returns
 * the id of the constant, or 0 if any potential calls to resize fail.
 *
 * @param pool The pool to insert the constant into.
 * @param start A pointer to the start of the constant.
 * @param length The length of the constant.
 * @return The id of the constant.
 */
rbs_constant_id_t rbs_constant_pool_insert_constant(rbs_constant_pool_t *pool, const uint8_t *start, size_t length);

/**
 * Free the memory associated with a constant pool.
 *
 * @param pool The pool to free.
 */
void rbs_constant_pool_free(rbs_constant_pool_t *pool);

#endif
