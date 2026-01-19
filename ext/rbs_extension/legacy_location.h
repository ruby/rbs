#ifndef RBS_LOCATION_H
#define RBS_LOCATION_H

#include "compat.h"

SUPPRESS_RUBY_HEADER_DIAGNOSTICS_BEGIN
#include "ruby.h"
SUPPRESS_RUBY_HEADER_DIAGNOSTICS_END

#include "rbs.h"

/**
 * Data structures for implementing RBS::Location class in Ruby.
 *
 * These structs support hierarchical locations, allowing sub-locations (children)
 * to be stored under a main location. Each sub-location is identified by its
 * name (Ruby Symbol ID).
 */

/**
 * RBS::Location class
 * */
extern VALUE RBS_Location;

/**
 * Range of character index for `rbs_loc` locations.
 */
typedef struct {
    int start;
    int end;
} rbs_loc_range;

typedef struct {
    ID name; /* Ruby ID for the name of the entry */
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

typedef struct {
    VALUE buffer;
    rbs_loc_range rg;
    rbs_loc_children *children; // NULL when no children is allocated
} rbs_loc;

/**
 * Returns new RBS::Location object, with given buffer and range.
 * */
VALUE rbs_new_location(VALUE buffer, rbs_range_t rg);

/**
 * Return rbs_loc associated with the RBS::Location object.
 * */
rbs_loc *rbs_check_location(VALUE location);

/**
 * Allocate memory for child locations.
 *
 * Do not call twice for the same location.
 * */
void rbs_loc_legacy_alloc_children(rbs_loc *loc, unsigned short cap);

void rbs_loc_legacy_add_optional_child(rbs_loc *loc, ID name, rbs_loc_range r);
void rbs_loc_legacy_add_required_child(rbs_loc *loc, ID name, rbs_loc_range r);

/**
 * Define RBS::Location class.
 * */
void rbs__init_location();

#endif
