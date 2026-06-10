#ifndef RBS__SERIALIZER_H
#define RBS__SERIALIZER_H

#include "rbs/ast.h"
#include "rbs/util/rbs_buffer.h"
#include "rbs/util/rbs_constant_pool.h"

/**
 * Serializes AST nodes into a compact binary format, consumed by the
 * pure-Ruby deserializer of the FFI parser backend
 * (lib/rbs/parser/deserializer.rb).
 *
 * The format is private to RBS: it is produced and consumed by the same gem
 * version, with both sides generated from config.yml, and carries no
 * versioning or compatibility guarantees. All integers are little-endian,
 * independent of the host platform.
 */
typedef struct {
    rbs_allocator_t *allocator;
    rbs_buffer_t *buffer;
    const rbs_constant_pool_t *constant_pool;
} rbs_serializer_t;

void rbs_serializer_write_u8(rbs_serializer_t *serializer, uint8_t value);
void rbs_serializer_write_u32(rbs_serializer_t *serializer, uint32_t value);
void rbs_serializer_write_i32(rbs_serializer_t *serializer, int32_t value);
void rbs_serializer_write_string(rbs_serializer_t *serializer, rbs_string_t string);

/**
 * Writes the serialized representation of the given node (or 0 for NULL)
 * into the serializer's buffer.
 */
void rbs_serializer_write_node(rbs_serializer_t *serializer, const rbs_node_t *node);

/**
 * Writes a node list: u32 element count followed by each node.
 */
void rbs_serializer_write_node_list(rbs_serializer_t *serializer, rbs_node_list_t *list);

#endif
