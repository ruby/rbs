#ifndef RBS__RBS_LOCATION_INTERNALS_H
#define RBS__RBS_LOCATION_INTERNALS_H

#include "rbs/util/rbs_constant_pool.h"

typedef struct {
  int start;
  int end;
} rbs_loc_range;

typedef struct {
  rbs_constant_id_t name;
  rbs_loc_range rg;
} rbs_loc_entry;

typedef unsigned int rbs_loc_entry_bitmap;

// The flexible array always allocates, but it's okay.
// This struct is not allocated when the `rbs_loc` doesn't have children.
typedef struct {
  unsigned short len;
  unsigned short cap;
  rbs_loc_entry_bitmap required_p;
  rbs_loc_entry entries[1];
} rbs_loc_children;

#endif
