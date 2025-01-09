#include "rbs/util/rbs_constant_pool.h"
#include "ruby.h" // Temporarily used for rb_intern2().
#include "ruby/encoding.h" // Temporarily used for rb_usascii_encoding().


#ifdef _MSC_VER
    _STATIC_ASSERT(
        sizeof(ID) == sizeof(rbs_constant_id_t)
    );
    _STATIC_ASSERT(
        sizeof(VALUE) == sizeof(rbs_constant_t)
    );
#else
    _Static_assert(
        __builtin_types_compatible_p(ID, rbs_constant_id_t),
        "rbs_constant_id_t must be the same as a Ruby ID for now."
    );

    _Static_assert(
        __builtin_types_compatible_p(VALUE, rbs_constant_t),
        "rbs_constant_t must be the same as a Ruby Symbol for now."
    );
#endif

static rbs_constant_pool_t RBS_GLOBAL_CONSTANT_POOL_STORAGE = {};
rbs_constant_pool_t *RBS_GLOBAL_CONSTANT_POOL = &RBS_GLOBAL_CONSTANT_POOL_STORAGE;

// This mask is used to obfuscate the constant IDs returned by `rb_intern2()`,
// so that we don't inadvertently mix usages of the RBS constant pool and the Ruby ID pool.
static const rbs_constant_id_t XOR_MASK = 0b1111110000111010111111000011101011111100001110101111110000111010;

/**
 * Initialize a new constant pool with a given capacity.
 */
bool
rbs_constant_pool_init(rbs_constant_pool_t *pool, uint32_t capacity) {
    assert(capacity == 0); // The capacity parameter is not used yet.
    return true;
}

/**
 * Return a pointer to the constant indicated by the given constant id.
 */
rbs_constant_t *
rbs_constant_pool_id_to_constant(const rbs_constant_pool_t *pool, rbs_constant_id_t constant_id) {
    assert(pool == RBS_GLOBAL_CONSTANT_POOL);

    if (constant_id == RBS_CONSTANT_ID_UNSET) return NULL;

    ID ruby_id = constant_id ^ XOR_MASK;
    VALUE symbol = ID2SYM(ruby_id);

    return (rbs_constant_t *) symbol;
}

/**
 * Find a constant in a constant pool. Returns the id of the constant, or 0 if
 * the constant is not found.
 */
rbs_constant_id_t
rbs_constant_pool_find(const rbs_constant_pool_t *pool, const uint8_t *start, size_t length) {
    // Note: `rb_intern2(name, length)` just delegates to `rb_intern3(name, length, rb_usascii_encoding())`,
    // so we're using `rb_usascii_encoding()` here to match that.
    ID id = rb_check_id_cstr((const char *) start, length, rb_usascii_encoding());

    if (id == 0) {
        return RBS_CONSTANT_ID_UNSET;
    }

    return id ^ XOR_MASK;
}

/**
 * Insert a constant into a constant pool. Returns the id of the constant, or
 * RBS_CONSTANT_ID_UNSET if any potential calls to resize fail.
 */
rbs_constant_id_t
rbs_constant_pool_insert_shared(rbs_constant_pool_t *pool, const uint8_t *start, size_t length) {
    assert(pool != RBS_GLOBAL_CONSTANT_POOL);

    ID id = rb_intern2((const char *) start, length);

    if (id == 0) {
        return RBS_CONSTANT_ID_UNSET;
    }

    return id ^ XOR_MASK;
}

/**
 * Insert a constant into a constant pool from memory that is constant. Returns
 * the id of the constant, or RBS_CONSTANT_ID_UNSET if any potential calls to
 * resize fail.
 */
rbs_constant_id_t
rbs_constant_pool_insert_constant(rbs_constant_pool_t *pool, const uint8_t *start, size_t length) {
    assert(pool == RBS_GLOBAL_CONSTANT_POOL);
    return rb_intern2((const char *) start, length) ^ XOR_MASK;
}

/**
 * Free the memory associated with a constant pool.
 */
void
rbs_constant_pool_free(rbs_constant_pool_t *pool) {
    // no-op, for now.
}
