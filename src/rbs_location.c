#include "rbs/rbs_location.h"

#include <stdio.h>

#define RBS_LOC_CHILDREN_SIZE(cap) (sizeof(rbs_loc_children) + sizeof(rbs_loc_entry) * ((cap) - 1))

static void check_children_max(unsigned short n) {
  size_t max = sizeof(rbs_loc_entry_bitmap) * 8;
  if (n > max) {
    fprintf(stderr, "Too many children added to location: %d", n);
    exit(EXIT_FAILURE);
  }
}

static void check_children_cap(rbs_location_t *loc) {
  if (loc->children == NULL) {
    rbs_loc_alloc_children(loc, 1);
  } else {
    if (loc->children->len == loc->children->cap) {
      check_children_max(loc->children->cap + 1);
      size_t s = RBS_LOC_CHILDREN_SIZE(++loc->children->cap);
      loc->children = realloc(loc->children, s);
    }
  }
}

static rbs_loc_range rbs_new_loc_range(range rg) {
  rbs_loc_range r = { rg.start.char_pos, rg.end.char_pos };
  return r;
}

void rbs_loc_alloc_children(rbs_location_t *loc, int capacity) {
  check_children_max(capacity);

  size_t s = RBS_LOC_CHILDREN_SIZE(capacity);
  loc->children = malloc(s);

  loc->children->len = 0;
  loc->children->required_p = 0;
  loc->children->cap = capacity;
}

void rbs_loc_add_required_child(rbs_location_t *loc, rbs_constant_id_t name, range r) {
  rbs_loc_add_optional_child(loc, name, r);

  unsigned short last_index = loc->children->len - 1;
  loc->children->required_p |= 1 << last_index;
}

void rbs_loc_add_optional_child(rbs_location_t *loc, rbs_constant_id_t name, range r) {
  check_children_cap(loc);

  unsigned short i = loc->children->len++;
  loc->children->entries[i].name = name;
  loc->children->entries[i].rg = rbs_new_loc_range(r);
}

rbs_location_t *rbs_location_new(rbs_allocator_t *allocator, range rg) {
  rbs_location_t *location = rbs_allocator_alloc(allocator, rbs_location_t);
  *location = (rbs_location_t) {
    .rg = rg,
    .children = NULL,
  };

  return location;
}

