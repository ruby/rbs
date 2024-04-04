#include "rbs_extension.h"

VALUE RBS_Location;

position rbs_loc_position(int char_pos) {
  position pos = { 0, char_pos, -1, -1 };
  return pos;
}

position rbs_loc_position3(int char_pos, int line, int column) {
  position pos = { 0, char_pos, line, column };
  return pos;
}

void rbs_loc_alloc_children(rbs_loc *loc, unsigned short size) {
  size_t s = sizeof(rbs_loc_list) + sizeof(rbs_loc_entry) * size;
  loc->list = malloc(s);

  loc->list->len = 0;
  loc->list->required_p = 0;
  loc->list->cap = size;
}

void rbs_loc_alloc_adding_children(rbs_loc *loc) {
  if (loc->list == NULL) {
    rbs_loc_alloc_children(loc, 1);
  } else {
    if (loc->list->len == loc->list->cap) {
      size_t s = sizeof(rbs_loc_list) + sizeof(rbs_loc_entry) * (++loc->list->cap);
      loc->list = realloc(loc->list, s);
    }
  }
}

void rbs_loc_add_required_child(rbs_loc *loc, ID name, range r) {
  rbs_loc_alloc_adding_children(loc);

  unsigned short i = loc->list->len++;
  loc->list->entries[i].name = name;
  loc->list->entries[i].rg = r;

  loc->list->required_p |= 1 << i;
}

void rbs_loc_add_optional_child(rbs_loc *loc, ID name, range r) {
  rbs_loc_alloc_adding_children(loc);

  unsigned short i = loc->list->len++;
  loc->list->entries[i].name = name;
  loc->list->entries[i].rg = r;
}

void rbs_loc_init(rbs_loc *loc, VALUE buffer, range rg) {
  loc->buffer = buffer;
  loc->rg = rg;
  loc->list = NULL;
}

void rbs_loc_free(rbs_loc *loc) {
  free(loc->list);
  ruby_xfree(loc);
}

static void rbs_loc_mark(void *ptr)
{
  rbs_loc *loc = ptr;
  rb_gc_mark(loc->buffer);
}

static size_t rbs_loc_memsize(const void *ptr) {
  const rbs_loc *loc = ptr;
  return sizeof(rbs_loc) + sizeof(rbs_loc_list) + sizeof(rbs_loc_entry) * loc->list->cap;
}

static rb_data_type_t location_type = {
  "RBS::Location",
  {rbs_loc_mark, (RUBY_DATA_FUNC)rbs_loc_free, rbs_loc_memsize},
  0, 0, RUBY_TYPED_FREE_IMMEDIATELY
};

static VALUE location_s_allocate(VALUE klass) {
  rbs_loc *loc;
  VALUE obj = TypedData_Make_Struct(klass, rbs_loc, &location_type, loc);

  rbs_loc_init(loc, Qnil, NULL_RANGE);

  return obj;
}

rbs_loc *rbs_check_location(VALUE obj) {
  return rb_check_typeddata(obj, &location_type);
}

static VALUE location_initialize(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos) {
  rbs_loc *loc = rbs_check_location(self);

  position start = rbs_loc_position(FIX2INT(start_pos));
  position end = rbs_loc_position(FIX2INT(end_pos));

  loc->buffer = buffer;
  loc->rg.start = start;
  loc->rg.end = end;

  return Qnil;
}

static VALUE location_initialize_copy(VALUE self, VALUE other) {
  rbs_loc *self_loc = rbs_check_location(self);
  rbs_loc *other_loc = rbs_check_location(other);

  self_loc->buffer = other_loc->buffer;
  self_loc->rg = other_loc->rg;
  rbs_loc_alloc_children(self_loc, other_loc->list->cap);

  return Qnil;
}

static VALUE location_buffer(VALUE self) {
  rbs_loc *loc = rbs_check_location(self);
  return loc->buffer;
}

static VALUE location_start_pos(VALUE self) {
  rbs_loc *loc = rbs_check_location(self);
  return INT2FIX(loc->rg.start.char_pos);
}

static VALUE location_end_pos(VALUE self) {
  rbs_loc *loc = rbs_check_location(self);
  return INT2FIX(loc->rg.end.char_pos);
}

static VALUE location_start_loc(VALUE self) {
  rbs_loc *loc = rbs_check_location(self);

  if (loc->rg.start.line >= 0) {
    VALUE pair = rb_ary_new_capa(2);
    rb_ary_push(pair, INT2FIX(loc->rg.start.line));
    rb_ary_push(pair, INT2FIX(loc->rg.start.column));
    return pair;
  } else {
    return Qnil;
  }
}

static VALUE location_end_loc(VALUE self) {
  rbs_loc *loc = rbs_check_location(self);

  if (loc->rg.end.line >= 0) {
    VALUE pair = rb_ary_new_capa(2);
    rb_ary_push(pair, INT2FIX(loc->rg.end.line));
    rb_ary_push(pair, INT2FIX(loc->rg.end.column));
    return pair;
  } else {
    return Qnil;
  }
}

// TODO: Check if we need to allocate more space
static VALUE location_add_required_child(VALUE self, VALUE name, VALUE start, VALUE end) {
  rbs_loc *loc = rbs_check_location(self);

  range rg;
  rg.start = rbs_loc_position(FIX2INT(start));
  rg.end = rbs_loc_position(FIX2INT(end));

  rbs_loc_add_required_child(loc, SYM2ID(name), rg);

  return Qnil;
}

// TODO: Check if we need to allocate more space
static VALUE location_add_optional_child(VALUE self, VALUE name, VALUE start, VALUE end) {
  rbs_loc *loc = rbs_check_location(self);

  range rg;
  rg.start = rbs_loc_position(FIX2INT(start));
  rg.end = rbs_loc_position(FIX2INT(end));

  rbs_loc_add_optional_child(loc, SYM2ID(name), rg);

  return Qnil;
}

static VALUE location_add_optional_no_child(VALUE self, VALUE name) {
  rbs_loc *loc = rbs_check_location(self);

  rbs_loc_add_optional_child(loc, SYM2ID(name), NULL_RANGE);

  return Qnil;
}

VALUE rbs_new_location(VALUE buffer, range rg) {
  rbs_loc *loc;
  VALUE obj = TypedData_Make_Struct(RBS_Location, rbs_loc, &location_type, loc);

  rbs_loc_init(loc, buffer, rg);

  return obj;
}

static VALUE location_aref(VALUE self, VALUE name) {
  rbs_loc *loc = rbs_check_location(self);

  ID id = SYM2ID(name);

  for (unsigned short i = 0; i < loc->list->len; i++) {
    if (loc->list->entries[i].name == id) {
      range result = loc->list->entries[i].rg;

      if (!(loc->list->required_p & (1 << i)) && null_range_p(result)) {
        return Qnil;
      } else {
        return rbs_new_location(loc->buffer, result);
      }
    }
  }

  VALUE string = rb_funcall(name, rb_intern("to_s"), 0);
  rb_raise(rb_eRuntimeError, "Unknown child name given: %s", RSTRING_PTR(string));
}

static VALUE location_optional_keys(VALUE self) {
  VALUE keys = rb_ary_new();

  rbs_loc *loc = rbs_check_location(self);
  rbs_loc_list list = *loc->list;

  for (unsigned short i = 0; i < list.len; i++) {
    if (!(list.required_p & (1 << i))) {
      rb_ary_push(keys, ID2SYM(list.entries[i].name));
    }
  }

  return keys;
}

static VALUE location_required_keys(VALUE self) {
  VALUE keys = rb_ary_new();

  rbs_loc *loc = rbs_check_location(self);
  rbs_loc_list list = *loc->list;

  for (unsigned short i = 0; i < list.len; i++) {
    if (list.required_p & (1 << i)) {
      rb_ary_push(keys, ID2SYM(list.entries[i].name));
    }
  }

  return keys;
}

VALUE rbs_location_pp(VALUE buffer, const position *start_pos, const position *end_pos) {
  range rg = { *start_pos, *end_pos };
  rg.start = *start_pos;
  rg.end = *end_pos;

  return rbs_new_location(buffer, rg);
}

void rbs__init_location(void) {
  RBS_Location = rb_define_class_under(RBS, "Location", rb_cObject);
  rb_define_alloc_func(RBS_Location, location_s_allocate);
  rb_define_private_method(RBS_Location, "initialize", location_initialize, 3);
  rb_define_private_method(RBS_Location, "initialize_copy", location_initialize_copy, 1);
  rb_define_method(RBS_Location, "buffer", location_buffer, 0);
  rb_define_method(RBS_Location, "start_pos", location_start_pos, 0);
  rb_define_method(RBS_Location, "end_pos", location_end_pos, 0);
  rb_define_private_method(RBS_Location, "_start_loc", location_start_loc, 0);
  rb_define_private_method(RBS_Location, "_end_loc", location_end_loc, 0);
  rb_define_method(RBS_Location, "_add_required_child", location_add_required_child, 3);
  rb_define_method(RBS_Location, "_add_optional_child", location_add_optional_child, 3);
  rb_define_method(RBS_Location, "_add_optional_no_child", location_add_optional_no_child, 1);
  rb_define_method(RBS_Location, "_optional_keys", location_optional_keys, 0);
  rb_define_method(RBS_Location, "_required_keys", location_required_keys, 0);
  rb_define_method(RBS_Location, "[]", location_aref, 1);
}
