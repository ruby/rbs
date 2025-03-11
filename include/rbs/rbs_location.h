#ifndef RBS__RBS_LOCATION_H
#define RBS__RBS_LOCATION_H

#include "lexer.h"

#include "rbs/util/rbs_constant_pool.h"
#include "rbs/util/rbs_allocator.h"
#include "rbs/rbs_location_internals.h"

typedef struct rbs_location {
    range rg;
    rbs_loc_children *children;
} rbs_location_t;

void rbs_loc_alloc_children(rbs_allocator_t *, rbs_location_t *loc, int size);
void rbs_loc_add_required_child(rbs_location_t *loc, rbs_constant_id_t name, range r);
void rbs_loc_add_optional_child(rbs_location_t *loc, rbs_constant_id_t name, range r);

/**
 * Allocate new rbs_location_t object through the given allocator.
 * */
rbs_location_t *rbs_location_new(rbs_allocator_t *, range rg);

#endif
