#include "rbs_string_bridging.h"

rbs_string_t rbs_string_from_ruby_string(VALUE ruby_string) {
    rb_gc_register_mark_object(ruby_string);

    rbs_string_t s = rbs_string_shared_new(StringValueCStr(ruby_string), RSTRING_END(ruby_string));

    rbs_string_ensure_owned(&s); // Copy out the string so we don't need the Ruby object to stay alive.

    return s;
}

VALUE rbs_string_to_ruby_string(rbs_string_t *self, rb_encoding *encoding) {
    VALUE str = rb_str_new_static(self->start, rbs_string_len(*self));
    rb_enc_associate(str, encoding);
    return str;
}
