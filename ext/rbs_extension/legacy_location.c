#include "legacy_location.h"
#include "rbs_extension.h"
#include "ruby/internal/intern/object.h"
#include "ruby/internal/intern/variable.h"
#include "ruby/internal/symbol.h"

#define RBS_LOC_REQUIRED_P(loc, i) ((loc)->children->required_p & (1 << (i)))
#define RBS_LOC_OPTIONAL_P(loc, i) (!RBS_LOC_REQUIRED_P((loc), (i)))
#define RBS_LOC_CHILDREN_SIZE(cap) (sizeof(rbs_loc_children) + sizeof(rbs_loc_entry) * ((cap) - 1))
#define NULL_LOC_RANGE_P(rg) ((rg).start == -1)

rbs_loc_range RBS_LOC_NULL_RANGE = { -1, -1 };
VALUE RBS_Location;

VALUE rbs_build_location2(VALUE buffer, int start_char, int end_char, VALUE required_children, VALUE optional_children) {
    return rb_funcall(
        RBS_Location,
        rb_intern("build"),
        5,
        buffer,
        INT2NUM(start_char),
        INT2NUM(end_char),
        required_children,
        optional_children
    );
}

VALUE rbs_new_location(VALUE buffer, rbs_range_t rg) {
    VALUE location = rb_funcall(RBS_Location, rb_intern("new"), 3, buffer, INT2NUM(rg.start.char_pos), INT2NUM(rg.end.char_pos));

    rb_obj_freeze(location);

    return location;
}

VALUE rbs_new_location2(VALUE buffer, int start_char, int end_char) {
    VALUE location = rb_funcall(RBS_Location, rb_intern("new"), 3, buffer, INT2NUM(start_char), INT2NUM(end_char));

    rb_obj_freeze(location);

    return location;
}

// static VALUE rbs_new_location_from_loc_range(VALUE buffer, rbs_loc_range rg) {
//     rbs_loc *loc;
//     VALUE obj = TypedData_Make_Struct(RBS_Location, rbs_loc, &location_type, loc);

//     rbs_loc_init(loc, buffer, rg);

//     return obj;
// }

// static VALUE location_aref(VALUE self, VALUE name) {
//     rbs_loc *loc = rbs_check_location(self);

//     ID id = rb_sym2id(name);

//     if (loc->children != NULL) {
//         for (unsigned short i = 0; i < loc->children->len; i++) {
//             if (loc->children->entries[i].name == id) {
//                 rbs_loc_range result = loc->children->entries[i].rg;

//                 if (RBS_LOC_OPTIONAL_P(loc, i) && NULL_LOC_RANGE_P(result)) {
//                     return Qnil;
//                 } else {
//                     return rbs_new_location_from_loc_range(loc->buffer, result);
//                 }
//             }
//         }
//     }

//     VALUE string = rb_funcall(name, rb_intern("to_s"), 0);
//     rb_raise(rb_eRuntimeError, "Unknown child name given: %s", RSTRING_PTR(string));
// }

// static VALUE location_optional_keys(VALUE self) {
//     VALUE keys = rb_ary_new();

//     rbs_loc *loc = rbs_check_location(self);
//     rbs_loc_children *children = loc->children;
//     if (children == NULL) {
//         return keys;
//     }

//     for (unsigned short i = 0; i < children->len; i++) {
//         if (RBS_LOC_OPTIONAL_P(loc, i)) {
//             VALUE key_sym = rb_id2sym(children->entries[i].name);
//             rb_ary_push(keys, key_sym);
//         }
//     }

//     return keys;
// }

// static VALUE location_required_keys(VALUE self) {
//     VALUE keys = rb_ary_new();

//     rbs_loc *loc = rbs_check_location(self);
//     rbs_loc_children *children = loc->children;
//     if (children == NULL) {
//         return keys;
//     }

//     for (unsigned short i = 0; i < children->len; i++) {
//         if (RBS_LOC_REQUIRED_P(loc, i)) {
//             VALUE key_sym = rb_id2sym(children->entries[i].name);
//             rb_ary_push(keys, key_sym);
//         }
//     }

//     return keys;
// }

void rbs__init_location(void) {
    // RBS_Location = rb_const_get(RBS, rb_intern("Location"));
    RBS_Location = rb_define_class_under(RBS, "Location", rb_cObject);
    // rb_define_alloc_func(RBS_Location, location_s_allocate);
    // rb_define_private_method(RBS_Location, "initialize", location_initialize, 3);
    // rb_define_private_method(RBS_Location, "initialize_copy", location_initialize_copy, 1);
    // rb_define_method(RBS_Location, "buffer", location_buffer, 0);
    // rb_define_method(RBS_Location, "_start_pos", location_start_pos, 0);
    // rb_define_method(RBS_Location, "_end_pos", location_end_pos, 0);
    // rb_define_method(RBS_Location, "_add_required_child", location_add_required_child, 3);
    // rb_define_method(RBS_Location, "_add_optional_child", location_add_optional_child, 3);
    // rb_define_method(RBS_Location, "_add_optional_no_child", location_add_optional_no_child, 1);
    // rb_define_method(RBS_Location, "_optional_keys", location_optional_keys, 0);
    // rb_define_method(RBS_Location, "_required_keys", location_required_keys, 0);
    // rb_define_method(RBS_Location, "[]", location_aref, 1);
}
