#ifndef RBS__RBS_LOCATION_H
#define RBS__RBS_LOCATION_H

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

typedef struct rbs_location_range_list_node {
    rbs_location_range range;
    struct rbs_location_range_list_node *next;
} rbs_location_range_list_node_t;

typedef struct rbs_location_range_list {
    rbs_allocator_t *allocator;
    struct rbs_location_range_list_node *head;
    struct rbs_location_range_list_node *tail;
    size_t length;
} rbs_location_range_list_t;

/**
 * Allocate new rbs_location_range_list_t object through the given allocator.
 */
rbs_location_range_list_t *rbs_location_range_list_new(rbs_allocator_t *allocator);
void rbs_location_range_list_append(rbs_location_range_list_t *list, rbs_location_range range);

#endif
