#ifndef RBS__RBS_LOCATION_H
#define RBS__RBS_LOCATION_H

#include "ruby.h"
#include "lexer.h"
#include "rbs/util/rbs_constant_pool.h"
#include "rbs/rbs_location_internals.h"

typedef struct rbs_location {
    range rg;
    rbs_loc_children *children;
} rbs_location_t;

rbs_location_t *rbs_location_new(range rg);
void rbs_loc_alloc_children(rbs_location_t *loc, int size);
void rbs_loc_add_required_child(rbs_location_t *loc, rbs_constant_id_t name, range r);
void rbs_loc_add_optional_child(rbs_location_t *loc, rbs_constant_id_t name, range r);

/**
 * Returns rbs_location_t struct with start/end positions.
 *
 * @param start_pos
 * @param end_pos
 * @return New rbs_location_t struct.
 * */
rbs_location_t *rbs_location_pp(const position *start_pos, const position *end_pos);

#endif
