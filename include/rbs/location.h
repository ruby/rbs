#ifndef RBS__RBS_LOCATION_H
#define RBS__RBS_LOCATION_H

#include "lexer.h"

#include "rbs/util/rbs_constant_pool.h"
#include "rbs/util/rbs_allocator.h"

#define RBS_LOCATION_NULL_RANGE ((rbs_location_range) { -1, -1 })
#define RBS_LOCATION_NULL_RANGE_P(rg) ((rg).start == -1)

/**
 * Converts a lexer range (rbs_range_t) to an AST location range (rbs_location_range) by extracting character positions.
 */
#define RBS_RANGE_LEX2AST(rg) ((rbs_location_range) { (rg).start.char_pos, (rg).end.char_pos })

typedef struct {
    int start;
    int end;
} rbs_location_range;

typedef struct {
    rbs_constant_id_t name;
    rbs_location_range rg;
} rbs_location_entry;

typedef unsigned int rbs_location_entry_bitmap;

// The flexible array always allocates, but it's okay.
// This struct is not allocated when the `rbs_location` doesn't have children.
typedef struct {
    unsigned short len;
    unsigned short cap;
    rbs_location_entry_bitmap required_p;
    rbs_location_entry entries[1];
} rbs_location_children;

typedef struct rbs_location {
    rbs_range_t rg;
    rbs_location_children *children;
} rbs_location_t;

typedef struct rbs_location_list_node {
    rbs_location_t *loc;
    struct rbs_location_list_node *next;
} rbs_location_list_node_t;

typedef struct rbs_location_list {
    rbs_allocator_t *allocator;
    rbs_location_list_node_t *head;
    rbs_location_list_node_t *tail;
    size_t length;
} rbs_location_list_t;

void rbs_loc_alloc_children(rbs_allocator_t *, rbs_location_t *loc, size_t capacity);
void rbs_loc_add_required_child(rbs_location_t *loc, rbs_constant_id_t name, rbs_range_t r);
void rbs_loc_add_optional_child(rbs_location_t *loc, rbs_constant_id_t name, rbs_range_t r);

/**
 * Allocate new rbs_location_t object through the given allocator.
 * */
rbs_location_t *rbs_location_new(rbs_allocator_t *, rbs_range_t rg);

rbs_location_list_t *rbs_location_list_new(rbs_allocator_t *allocator);
void rbs_location_list_append(rbs_location_list_t *list, rbs_location_t *loc);

#endif
