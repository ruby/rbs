#include "rbs/rbs_location.h"
#include "location.h"

#define RBS_LOC_CHILDREN_SIZE(cap) (sizeof(rbs_loc_children) + sizeof(rbs_loc_entry) * ((cap) - 1))

static void check_children_max(unsigned short n) {
  size_t max = sizeof(rbs_loc_entry_bitmap) * 8;
  if (n > max) {
    rb_raise(rb_eRuntimeError, "Too many children added to location: %d", n);
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

rbs_location_t *rbs_location_pp(const position *start_pos, const position *end_pos) {
  range rg = { *start_pos, *end_pos };
  rg.start = *start_pos;
  rg.end = *end_pos;

  return rbs_location_new(rg);
}

rbs_location_t *rbs_location_new(range rg) {
    rbs_location_t *location = (rbs_location_t *)malloc(sizeof(rbs_location_t));
    *location = (rbs_location_t) {
      .rg = rg,
      .children = NULL,
    };

    return location;
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
  check_children_cap(loc);

  unsigned short i = loc->children->len++;
  loc->children->entries[i].name = name;
  loc->children->entries[i].rg = rbs_new_loc_range(r);

  loc->children->required_p |= 1 << i;
}

void rbs_loc_add_optional_child(rbs_location_t *loc, rbs_constant_id_t name, range r) {
  check_children_cap(loc);

  unsigned short i = loc->children->len++;
  loc->children->entries[i].name = name;
  loc->children->entries[i].rg = rbs_new_loc_range(r);
}
