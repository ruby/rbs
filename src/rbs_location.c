#include "rbs/rbs_location.h"
#include "location.h"

// A helper for getting the "old style" `rbs_loc` from the new `rbs_location_t` struct.
static rbs_loc *get_rbs_location(const rbs_location_t *loc) {
  return rbs_check_location(loc->cached_ruby_value);
}

rbs_location_t *rbs_location_pp(VALUE buffer, const position *start_pos, const position *end_pos) {
  range rg = { *start_pos, *end_pos };
  rg.start = *start_pos;
  rg.end = *end_pos;

  return rbs_location_new(buffer, rg);
}

void rbs_loc_alloc_children(rbs_location_t *loc, int size) {
  rbs_loc_legacy_alloc_children(get_rbs_location(loc), size);
}

void rbs_loc_add_required_child(rbs_location_t *loc, rbs_constant_id_t name, range r) {
  rbs_loc_legacy_add_required_child(get_rbs_location(loc), name, r);
}

void rbs_loc_add_optional_child(rbs_location_t *loc, rbs_constant_id_t name, range r) {
  rbs_loc_legacy_add_optional_child(get_rbs_location(loc), name, r);
}
