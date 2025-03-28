#include "rbs/rbs_location.h"
#include "rbs/util/rbs_assert.h"

#include <stdio.h>

#define RBS_LOC_CHILDREN_SIZE(cap) (sizeof(rbs_loc_children) + sizeof(rbs_loc_entry) * ((cap) - 1))

void rbs_loc_alloc_children(rbs_allocator_t *allocator, rbs_location_t *loc, size_t capacity) {
  rbs_assert(capacity <= sizeof(rbs_loc_entry_bitmap) * 8, "Capacity %zu is too large. Max is %zu", capacity, sizeof(rbs_loc_entry_bitmap) * 8);

  loc->children = rbs_allocator_malloc_impl(allocator, RBS_LOC_CHILDREN_SIZE(capacity), alignof(rbs_loc_children));

  loc->children->len = 0;
  loc->children->required_p = 0;
  loc->children->cap = capacity;
}

void rbs_loc_add_optional_child(rbs_location_t *loc, rbs_constant_id_t name, rbs_range_t r) {
  rbs_assert(loc->children != NULL, "All children should have been pre-allocated with rbs_loc_alloc_children()");
  rbs_assert((loc->children->len + 1 <= loc->children->cap), "Not enough space was pre-allocated for the children. Children: %hu, Capacity: %hu", loc->children->len, loc->children->cap);

  unsigned short i = loc->children->len++;
  loc->children->entries[i].name = name;
  loc->children->entries[i].rg = (rbs_loc_range) { r.start.char_pos, r.end.char_pos };
}

void rbs_loc_add_required_child(rbs_location_t *loc, rbs_constant_id_t name, rbs_range_t r) {
  rbs_loc_add_optional_child(loc, name, r);
  unsigned short last_index = loc->children->len - 1;
  loc->children->required_p |= 1 << last_index;
}

rbs_location_t *rbs_location_new(rbs_allocator_t *allocator, rbs_range_t rg) {
  rbs_location_t *location = rbs_allocator_alloc(allocator, rbs_location_t);
  *location = (rbs_location_t) {
    .rg = rg,
    .children = NULL,
  };

  return location;
}

