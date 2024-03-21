#include "rbs_extension.h"

static VALUE unquote_common(parserstate *state, range rg, int offset_bytes, int is_symbol) {
  VALUE string = state->lexstate->string;
  rb_encoding *enc = rb_enc_get(string);

  unsigned int first_char = rb_enc_mbc_to_codepoint(
    RSTRING_PTR(string) + rg.start.byte_pos + offset_bytes,
    RSTRING_END(string),
    enc
  );
  int is_quoted = first_char == '"' || first_char == '\'' || first_char == '`';
  int byte_length = rg.end.byte_pos - rg.start.byte_pos - offset_bytes;

  if (is_quoted) {
    int bs = rb_enc_codelen(first_char, enc);
    offset_bytes += bs;
    byte_length -= 2 * bs;
  }

  char *buffer = RSTRING_PTR(state->lexstate->string) + rg.start.byte_pos + offset_bytes;

  if (!is_quoted) {
    return is_symbol ? ID2SYM(rb_intern3(buffer, byte_length, enc)) : rb_enc_str_new(buffer, byte_length, enc);
  }

  VALUE str = rb_enc_str_new(buffer, byte_length, enc);
  VALUE unescaped_str = rb_funcall(
    RBS_Types_Literal,
    rb_intern("unescape_string"),
    2,
    str,
    first_char == '\"' ? Qtrue : Qfalse
  );
  return is_symbol ? rb_to_symbol(unescaped_str) : unescaped_str;
}

VALUE rbs_unquote_string(parserstate *state, range rg, int offset_bytes) {
  return unquote_common(state, rg, offset_bytes, 0);
}

VALUE rbs_unquote_symbol(parserstate *state, range rg, int offset_bytes) {
  return unquote_common(state, rg, offset_bytes, 1);
}
