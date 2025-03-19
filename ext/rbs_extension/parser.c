#include "rbs_extension.h"
#include "rbs/util/rbs_constant_pool.h"

#define INTERN(str)                  \
  rbs_constant_pool_insert_constant( \
    RBS_GLOBAL_CONSTANT_POOL,        \
    (const uint8_t *) str,           \
    strlen(str)                      \
  )

#define INTERN_TOKEN(parserstate, tok) \
  rb_intern3(\
    peek_token(parserstate->lexstate, tok),\
    token_bytes(tok),\
    rb_enc_get(parserstate->lexstate->string)\
  )

#define KEYWORD_CASES \
  case kBOOL:\
  case kBOT: \
  case kCLASS: \
  case kFALSE: \
  case kINSTANCE: \
  case kINTERFACE: \
  case kNIL: \
  case kSELF: \
  case kSINGLETON: \
  case kTOP: \
  case kTRUE: \
  case kVOID: \
  case kTYPE: \
  case kUNCHECKED: \
  case kIN: \
  case kOUT: \
  case kEND: \
  case kDEF: \
  case kINCLUDE: \
  case kEXTEND: \
  case kPREPEND: \
  case kALIAS: \
  case kMODULE: \
  case kATTRREADER: \
  case kATTRWRITER: \
  case kATTRACCESSOR: \
  case kPUBLIC: \
  case kPRIVATE: \
  case kUNTYPED: \
  case kUSE: \
  case kAS: \
  case k__TODO__: \
  case kINHERITS: \
  case kRETURN: \
  case kOVERRIDE: \
  case kGENERIC: \
  case kSKIP: \
  /* nop */

typedef struct {
  VALUE required_positionals;
  VALUE optional_positionals;
  VALUE rest_positionals;
  VALUE trailing_positionals;
  VALUE required_keywords;
  VALUE optional_keywords;
  VALUE rest_keywords;
} method_params;

static VALUE EMPTY_ARRAY;
static VALUE EMPTY_HASH;

static inline void melt_array(VALUE *array) {
  if (*array == EMPTY_ARRAY) {
    *array = rb_ary_new();
  }
}

static inline void melt_hash(VALUE *hash) {
  if (*hash == EMPTY_HASH) {
    *hash = rb_hash_new();
  }
}

static bool rbs_is_untyped_params(method_params *params) {
  return NIL_P(params->required_positionals);
}

// /**
//  * Returns RBS::Location object of `current_token` of a parser state.
//  *
//  * @param state
//  * @return New RBS::Location object.
//  * */
static VALUE rbs_location_current_token(parserstate *state) {
  return rbs_location_pp(
    state->buffer,
    &state->current_token.range.start,
    &state->current_token.range.end
  );
}

static VALUE parse_optional(parserstate *state);
static VALUE parse_simple(parserstate *state);

static VALUE string_of_loc(parserstate *state, position start, position end) {
  return rb_enc_str_new(
    RSTRING_PTR(state->lexstate->string) + start.byte_pos,
      end.byte_pos - start.byte_pos,
      rb_enc_get(state->lexstate->string)
  );
}

/**
 * Raises RuntimeError with "Unexpected error " message.
 * */
static NORETURN(void) rbs_abort(void) {
  rb_raise(
    rb_eRuntimeError,
    "Unexpected error"
  );
}

NORETURN(void) raise_syntax_error(parserstate *state, token tok, const char *fmt, ...) {
  va_list args;
  va_start(args, fmt);
  VALUE message = rb_vsprintf(fmt, args);
  va_end(args);

  VALUE location = rbs_new_location(state->buffer, tok.range);
  VALUE type = rb_str_new_cstr(token_type_str(tok.type));

  VALUE error = rb_funcall(
    RBS_ParsingError,
    rb_intern("new"),
    3,
    location,
    message,
    type
  );

  rb_exc_raise(error);
}

typedef enum {
  CLASS_NAME = 1,
  INTERFACE_NAME = 2,
  ALIAS_NAME = 4
} TypeNameKind;

void parser_advance_no_gap(parserstate *state) {
  if (state->current_token.range.end.byte_pos == state->next_token.range.start.byte_pos) {
    parser_advance(state);
  } else {
    raise_syntax_error(
      state,
      state->next_token,
      "unexpected token"
    );
  }
}

/*
  type_name ::= {`::`} (tUIDENT `::`)* <tXIDENT>
              | {(tUIDENT `::`)*} <tXIDENT>
              | {<tXIDENT>}
*/
static VALUE parse_type_name(parserstate *state, TypeNameKind kind, range *rg) {
  VALUE absolute = Qfalse;
  VALUE path = EMPTY_ARRAY;

  if (rg) {
    rg->start = state->current_token.range.start;
  }

  if (state->current_token.type == pCOLON2) {
    absolute = Qtrue;
    parser_advance_no_gap(state);
  }

  while (
    state->current_token.type == tUIDENT
    && state->next_token.type == pCOLON2
    && state->current_token.range.end.byte_pos == state->next_token.range.start.byte_pos
    && state->next_token.range.end.byte_pos == state->next_token2.range.start.byte_pos
  ) {
    melt_array(&path);
    rb_ary_push(path, ID2SYM(INTERN_TOKEN(state, state->current_token)));

    parser_advance(state);
    parser_advance(state);
  }

  VALUE namespace = rbs_namespace(path, absolute);

  switch (state->current_token.type) {
    case tLIDENT:
      if (kind & ALIAS_NAME) goto success;
      goto error;
    case tULIDENT:
      if (kind & INTERFACE_NAME) goto success;
      goto error;
    case tUIDENT:
      if (kind & CLASS_NAME) goto success;
      goto error;
    default:
      goto error;
  }

  success: {
    if (rg) {
      rg->end = state->current_token.range.end;
    }

    return rbs_type_name(namespace, ID2SYM(INTERN_TOKEN(state, state->current_token)));
  }

  error: {
    VALUE ids = rb_ary_new();
    if (kind & ALIAS_NAME) {
      rb_ary_push(ids, rb_str_new_literal("alias name"));
    }
    if (kind & INTERFACE_NAME) {
      rb_ary_push(ids, rb_str_new_literal("interface name"));
    }
    if (kind & CLASS_NAME) {
      rb_ary_push(ids, rb_str_new_literal("class/module/constant name"));
    }

    VALUE string = rb_funcall(ids, rb_intern("join"), 1, rb_str_new_cstr(", "));

    raise_syntax_error(
      state,
      state->current_token,
      "expected one of %"PRIsVALUE,
      string
    );
  }
}

/*
  type_list ::= {} type `,` ... <`,`> eol
              | {} type `,` ... `,` <type> eol
*/
static void parse_type_list(parserstate *state, enum TokenType eol, VALUE *types) {
  while (true) {
    melt_array(types);
    rb_ary_push(*types, parse_type(state));

    if (state->next_token.type == pCOMMA) {
      parser_advance(state);

      if (state->next_token.type == eol) {
        break;
      }
    } else {
      if (state->next_token.type == eol) {
        break;
      } else {
        raise_syntax_error(
          state,
          state->next_token,
          "comma delimited type list is expected"
        );
      }
    }
  }
}

static bool is_keyword_token(enum TokenType type) {
  switch (type)
  {
  case tLIDENT:
  case tUIDENT:
  case tULIDENT:
  case tULLIDENT:
  case tQIDENT:
  case tBANGIDENT:
  KEYWORD_CASES
    return true;
  default:
    return false;
  }
}

/*
  function_param ::= {} <type>
                   | {} type <param>
*/
static VALUE parse_function_param(parserstate *state) {
  range type_range;
  type_range.start = state->next_token.range.start;
  VALUE type = parse_type(state);
  type_range.end = state->current_token.range.end;

  if (state->next_token.type == pCOMMA || state->next_token.type == pRPAREN) {
    range param_range = type_range;

    VALUE location = rbs_new_location(state->buffer, param_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 1);
    rbs_loc_add_optional_child(loc, INTERN("name"), NULL_RANGE);

    return rbs_function_param(type, Qnil, location);
  } else {
    range name_range = state->next_token.range;

    parser_advance(state);

    range param_range = {
      .start = type_range.start,
      .end = name_range.end,
    };

    if (!is_keyword_token(state->current_token.type)) {
      raise_syntax_error(
        state,
        state->current_token,
        "unexpected token for function parameter name"
      );
    }

    VALUE name = rb_to_symbol(rbs_unquote_string(state, state->current_token.range, 0));
    VALUE location = rbs_new_location(state->buffer, param_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 1);
    rbs_loc_add_optional_child(loc, INTERN("name"), name_range);

    return rbs_function_param(type, name, location);
  }
}

static ID intern_token_start_end(parserstate *state, token start_token, token end_token) {
  return rb_intern3(
    peek_token(state->lexstate, start_token),
    end_token.range.end.byte_pos - start_token.range.start.byte_pos,
    rb_enc_get(state->lexstate->string)
  );
}

/*
  keyword_key ::= {} <keyword> `:`
                | {} keyword <`?`> `:`
*/
static VALUE parse_keyword_key(parserstate *state) {
  parser_advance(state);

  if (state->next_token.type == pQUESTION) {
    VALUE key = ID2SYM(intern_token_start_end(state, state->current_token, state->next_token));
    parser_advance(state);
    return key;
  } else {
    return ID2SYM(INTERN_TOKEN(state, state->current_token));
  }
}

/*
  keyword ::= {} keyword `:` <function_param>
*/
static void parse_keyword(parserstate *state, VALUE *keywords, VALUE memo) {
  VALUE key = parse_keyword_key(state);

  if (!NIL_P(rb_hash_aref(memo, key))) {
    raise_syntax_error(
      state,
      state->current_token,
      "duplicated keyword argument"
    );
  } else {
    rb_hash_aset(memo, key, Qtrue);
  }

  parser_advance_assert(state, pCOLON);
  VALUE param = parse_function_param(state);

  melt_hash(keywords);
  rb_hash_aset(*keywords, key, param);

  return;
}

/*
Returns true if keyword is given.

  is_keyword === {} KEYWORD `:`
*/
static bool is_keyword(parserstate *state) {
  if (is_keyword_token(state->next_token.type)) {
    if (state->next_token2.type == pCOLON && state->next_token.range.end.byte_pos == state->next_token2.range.start.byte_pos) {
      return true;
    }

    if (state->next_token2.type == pQUESTION
        && state->next_token3.type == pCOLON
        && state->next_token.range.end.byte_pos == state->next_token2.range.start.byte_pos
        && state->next_token2.range.end.byte_pos == state->next_token3.range.start.byte_pos) {
      return true;
    }
  }

  return false;
}

/*
  params ::= {} `)`
           | {} `?` `)`               -- Untyped function params (assign params.required = nil)
           | <required_params> `)`
           | <required_params> `,` `)`

  required_params ::= {} function_param `,` <required_params>
                    | {} <function_param>
                    | {} <optional_params>

  optional_params ::= {} `?` function_param `,` <optional_params>
                    | {} `?` <function_param>
                    | {} <rest_params>

  rest_params ::= {} `*` function_param `,` <trailing_params>
                | {} `*` <function_param>
                | {} <trailing_params>

  trailing_params ::= {} function_param `,` <trailing_params>
                    | {} <function_param>
                    | {} <keywords>

  keywords ::= {} required_keyword `,` <keywords>
             | {} `?` optional_keyword `,` <keywords>
             | {} `**` function_param `,` <keywords>
             | {} <required_keyword>
             | {} `?` <optional_keyword>
             | {} `**` <function_param>
*/
static void parse_params(parserstate *state, method_params *params) {
  if (state->next_token.type == pQUESTION && state->next_token2.type == pRPAREN) {
    params->required_positionals = Qnil;
    parser_advance(state);
    return;
  }
  if (state->next_token.type == pRPAREN) {
    return;
  }

  VALUE memo = rb_hash_new();

  while (true) {
    VALUE param;

    switch (state->next_token.type) {
      case pQUESTION:
        goto PARSE_OPTIONAL_PARAMS;
      case pSTAR:
        goto PARSE_REST_PARAM;
      case pSTAR2:
        goto PARSE_KEYWORDS;
      case pRPAREN:
        goto EOP;

      default:
        if (is_keyword(state)) {
          goto PARSE_KEYWORDS;
        }

        param = parse_function_param(state);
        melt_array(&params->required_positionals);
        rb_ary_push(params->required_positionals, param);

        break;
    }

    if (!parser_advance_if(state, pCOMMA)) {
      goto EOP;
    }
  }

PARSE_OPTIONAL_PARAMS:
  while (true) {
    VALUE param;

    switch (state->next_token.type) {
      case pQUESTION:
        parser_advance(state);

        if (is_keyword(state)) {
          parse_keyword(state, &params->optional_keywords, memo);
          parser_advance_if(state, pCOMMA);
          goto PARSE_KEYWORDS;
        }

        param = parse_function_param(state);
        melt_array(&params->optional_positionals);
        rb_ary_push(params->optional_positionals, param);

        break;
      default:
        goto PARSE_REST_PARAM;
    }

    if (!parser_advance_if(state, pCOMMA)) {
      goto EOP;
    }
  }

PARSE_REST_PARAM:
  if (state->next_token.type == pSTAR) {
    parser_advance(state);
    params->rest_positionals = parse_function_param(state);

    if (!parser_advance_if(state, pCOMMA)) {
      goto EOP;
    }
  }
  goto PARSE_TRAILING_PARAMS;

PARSE_TRAILING_PARAMS:
  while (true) {
    VALUE param;

    switch (state->next_token.type) {
      case pQUESTION:
        goto PARSE_KEYWORDS;
      case pSTAR:
        goto EOP;
      case pSTAR2:
        goto PARSE_KEYWORDS;
      case pRPAREN:
        goto EOP;

      default:
        if (is_keyword(state)) {
          goto PARSE_KEYWORDS;
        }

        param = parse_function_param(state);
        melt_array(&params->trailing_positionals);
        rb_ary_push(params->trailing_positionals, param);

        break;
    }

    if (!parser_advance_if(state, pCOMMA)) {
      goto EOP;
    }
  }

PARSE_KEYWORDS:
  while (true) {
    switch (state->next_token.type) {
    case pQUESTION:
      parser_advance(state);
      if (is_keyword(state)) {
        parse_keyword(state, &params->optional_keywords, memo);
      } else {
        raise_syntax_error(
          state,
          state->next_token,
          "optional keyword argument type is expected"
        );
      }
      break;

    case pSTAR2:
      parser_advance(state);
      params->rest_keywords = parse_function_param(state);
      break;

    case tUIDENT:
    case tLIDENT:
    case tQIDENT:
    case tULIDENT:
    case tULLIDENT:
    case tBANGIDENT:
    KEYWORD_CASES
      if (is_keyword(state)) {
        parse_keyword(state, &params->required_keywords, memo);
      } else {
        raise_syntax_error(
          state,
          state->next_token,
          "required keyword argument type is expected"
        );
      }
      break;

    default:
      goto EOP;
    }

    if (!parser_advance_if(state, pCOMMA)) {
      goto EOP;
    }
  }

EOP:
  if (state->next_token.type != pRPAREN) {
    raise_syntax_error(
      state,
      state->next_token,
      "unexpected token for method type parameters"
    );
  }

  return;
}

/*
  optional ::= {} <simple_type>
             | {} simple_type <`?`>
*/
static VALUE parse_optional(parserstate *state) {
  range rg;
  rg.start = state->next_token.range.start;

  VALUE type = parse_simple(state);

  if (state->next_token.type == pQUESTION) {
    parser_advance(state);
    rg.end = state->current_token.range.end;
    VALUE location = rbs_new_location(state->buffer, rg);
    return rbs_optional(type, location);
  } else {
    return type;
  }
}

static void initialize_method_params(method_params *params){
  *params = (method_params) {
    .required_positionals = EMPTY_ARRAY,
    .optional_positionals = EMPTY_ARRAY,
    .rest_positionals = Qnil,
    .trailing_positionals = EMPTY_ARRAY,
    .required_keywords = EMPTY_HASH,
    .optional_keywords = EMPTY_HASH,
    .rest_keywords = Qnil,
  };
}

/*
  self_type_binding ::= {} <>
                      | {} `[` `self` `:` type <`]`>
*/
static VALUE parse_self_type_binding(parserstate *state) {
  if (state->next_token.type == pLBRACKET) {
    parser_advance(state);
    parser_advance_assert(state, kSELF);
    parser_advance_assert(state, pCOLON);
    VALUE type = parse_type(state);
    parser_advance_assert(state, pRBRACKET);
    return type;
  } else {
    return Qnil;
  }
}

/*
  function ::= {} `(` params `)` self_type_binding? `{` `(` params `)` self_type_binding? `->` optional `}` `->` <optional>
             | {} `(` params `)` self_type_binding? `->` <optional>
             | {} self_type_binding? `{` `(` params `)` self_type_binding? `->` optional `}` `->` <optional>
             | {} self_type_binding? `{` self_type_binding `->` optional `}` `->` <optional>
             | {} self_type_binding? `->` <optional>
*/
static void parse_function(parserstate *state, VALUE *function, VALUE *block, VALUE *function_self_type) {
  method_params params;
  initialize_method_params(&params);

  if (state->next_token.type == pLPAREN) {
    parser_advance(state);
    parse_params(state, &params);
    parser_advance_assert(state, pRPAREN);
  }

  // Passing NULL to function_self_type means the function itself doesn't accept self type binding. (== method type)
  if (function_self_type) {
    *function_self_type = parse_self_type_binding(state);
  } else {
    // Parsing method type. untyped_params means it cannot have a block
    if (rbs_is_untyped_params(&params)) {
      if (state->next_token.type != pARROW) {
        raise_syntax_error(state, state->next_token2, "A method type with untyped method parameter cannot have block");
      }
    }
  }

  // Passing `NULL` to `block` means it cannot have block
  if (!block) {
    if (state->next_token.type != pARROW) {
      raise_syntax_error(state, state->next_token2, "Cannot have block");
    }
  }

  VALUE required = Qtrue;
  if (state->next_token.type == pQUESTION && state->next_token2.type == pLBRACE) {
    // Optional block
    required = Qfalse;
    parser_advance(state);
  }
  if (state->next_token.type == pLBRACE) {
    parser_advance(state);

    method_params block_params;
    initialize_method_params(&block_params);

    if (state->next_token.type == pLPAREN) {
      parser_advance(state);
      parse_params(state, &block_params);
      parser_advance_assert(state, pRPAREN);
    }

    VALUE block_self_type = parse_self_type_binding(state);

    parser_advance_assert(state, pARROW);
    VALUE block_return_type = parse_optional(state);

    VALUE block_function = Qnil;
    if (rbs_is_untyped_params(&block_params)) {
      block_function = rbs_untyped_function(block_return_type);
    } else {
      block_function = rbs_function(
        block_params.required_positionals,
        block_params.optional_positionals,
        block_params.rest_positionals,
        block_params.trailing_positionals,
        block_params.required_keywords,
        block_params.optional_keywords,
        block_params.rest_keywords,
        block_return_type
      );
    }

    if (block) {
      *block = rbs_block(block_function, required, block_self_type);
    }

    parser_advance_assert(state, pRBRACE);
  }

  parser_advance_assert(state, pARROW);
  VALUE type = parse_optional(state);

  if (rbs_is_untyped_params(&params)) {
    *function = rbs_untyped_function(type);
  } else {
    *function = rbs_function(
      params.required_positionals,
      params.optional_positionals,
      params.rest_positionals,
      params.trailing_positionals,
      params.required_keywords,
      params.optional_keywords,
      params.rest_keywords,
      type
    );
  }
}

/*
  proc_type ::= {`^`} <function>
*/
static VALUE parse_proc_type(parserstate *state) {
  position start = state->current_token.range.start;
  VALUE function = Qnil;
  VALUE block = Qnil;
  VALUE proc_self = Qnil;
  parse_function(state, &function, &block, &proc_self);
  position end = state->current_token.range.end;
  VALUE loc = rbs_location_pp(state->buffer, &start, &end);

  return rbs_proc(function, block, loc, proc_self);
}

static void check_key_duplication(parserstate *state, VALUE fields, VALUE key) {
  if (!NIL_P(rb_hash_aref(fields, key))) {
    raise_syntax_error(
      state,
      state->current_token,
      "duplicated record key"
    );
  }
}

/**
 * ... `{` ... `}` ...
 *        >   >
 * */
/*
  record_attributes ::= {`{`} record_attribute... <record_attribute> `}`

  record_attribute ::= {} keyword_token `:` <type>
                     | {} literal_type `=>` <type>
*/
static VALUE parse_record_attributes(parserstate *state) {
  VALUE fields = rb_hash_new();

  if (state->next_token.type == pRBRACE) {
    return fields;
  }

  while (true) {
    VALUE key, type,
          value = rb_ary_new(),
          required = Qtrue;

    if (state->next_token.type == pQUESTION) {
      // { ?foo: type } syntax
      required = Qfalse;
      parser_advance(state);
    }

    if (is_keyword(state)) {
      // { foo: type } syntax
      key = parse_keyword_key(state);
      check_key_duplication(state, fields, key);
      parser_advance_assert(state, pCOLON);
    } else {
      // { key => type } syntax
      switch (state->next_token.type) {
      case tSYMBOL:
      case tSQSYMBOL:
      case tDQSYMBOL:
      case tSQSTRING:
      case tDQSTRING:
      case tINTEGER:
      case kTRUE:
      case kFALSE: {
        key = rb_funcall(parse_simple(state), rb_intern("literal"), 0);
        break;
      }
      default:
        raise_syntax_error(
          state,
          state->next_token,
          "unexpected record key token"
        );
      }
      check_key_duplication(state, fields, key);
      parser_advance_assert(state, pFATARROW);
    }
    type = parse_type(state);
    rb_ary_push(value, type);
    rb_ary_push(value, required);
    rb_hash_aset(fields, key, value);

    if (parser_advance_if(state, pCOMMA)) {
      if (state->next_token.type == pRBRACE) {
        break;
      }
    } else {
      break;
    }
  }
  return fields;
}

/*
  symbol ::= {<tSYMBOL>}
*/
static VALUE parse_symbol(parserstate *state) {
  VALUE string = state->lexstate->string;
  rb_encoding *enc = rb_enc_get(string);

  int offset_bytes = rb_enc_codelen(':', enc);
  int bytes = token_bytes(state->current_token) - offset_bytes;

  VALUE literal;

  switch (state->current_token.type)
  {
  case tSYMBOL: {
    char *buffer = peek_token(state->lexstate, state->current_token);
    literal = ID2SYM(rb_intern3(buffer+offset_bytes, bytes, enc));
    break;
  }
  case tDQSYMBOL:
  case tSQSYMBOL: {
    literal = rb_funcall(
      rbs_unquote_string(state, state->current_token.range, offset_bytes),
      rb_intern("to_sym"),
      0
    );
    break;
  }
  default:
    rbs_abort();
  }

  return rbs_literal(
    literal,
    rbs_location_current_token(state)
  );
}

/*
 instance_type ::= {type_name} <type_args>

 type_args ::= {} <> /empty/
             | {} `[` type_list <`]`>
 */
static VALUE parse_instance_type(parserstate *state, bool parse_alias) {
    TypeNameKind expected_kind = INTERFACE_NAME | CLASS_NAME;
    if (parse_alias) {
      expected_kind |= ALIAS_NAME;
    }

    range name_range;
    VALUE typename = parse_type_name(state, expected_kind, &name_range);
    VALUE types = EMPTY_ARRAY;

    TypeNameKind kind;
    if (state->current_token.type == tUIDENT) {
      kind = CLASS_NAME;
    } else if (state->current_token.type == tULIDENT) {
      kind = INTERFACE_NAME;
    } else if (state->current_token.type == tLIDENT) {
      kind = ALIAS_NAME;
    } else {
      rbs_abort();
    }

    range args_range;
    if (state->next_token.type == pLBRACKET) {
      parser_advance(state);
      args_range.start = state->current_token.range.start;
      parse_type_list(state, pRBRACKET, &types);
      parser_advance_assert(state, pRBRACKET);
      args_range.end = state->current_token.range.end;
    } else {
      args_range = NULL_RANGE;
    }

    range type_range = {
      .start = name_range.start,
      .end = nonnull_pos_or(args_range.end, name_range.end),
    };

    VALUE location = rbs_new_location(state->buffer, type_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 2);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_optional_child(loc, INTERN("args"), args_range);

    if (kind == CLASS_NAME) {
      return rbs_class_instance(typename, types, location);
    } else if (kind == INTERFACE_NAME) {
      return rbs_interface(typename, types, location);
    } else if (kind == ALIAS_NAME) {
      return rbs_alias(typename, types, location);
    } else {
      return Qnil;
    }
}

/*
  singleton_type ::= {`singleton`} `(` type_name <`)`>
*/
static VALUE parse_singleton_type(parserstate *state) {
  parser_assert(state, kSINGLETON);

  range type_range;
  type_range.start = state->current_token.range.start;
  parser_advance_assert(state, pLPAREN);
  parser_advance(state);

  range name_range;
  VALUE typename = parse_type_name(state, CLASS_NAME, &name_range);

  parser_advance_assert(state, pRPAREN);
  type_range.end = state->current_token.range.end;

  VALUE location = rbs_new_location(state->buffer, type_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 1);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);

  return rbs_class_singleton(typename, location);
}

/*
  simple ::= {} `(` type <`)`>
           | {} <base type>
           | {} <type_name>
           | {} class_instance `[` type_list <`]`>
           | {} `singleton` `(` type_name <`)`>
           | {} `[` type_list <`]`>
           | {} `{` record_attributes <`}`>
           | {} `^` <function>
*/
static VALUE parse_simple(parserstate *state) {
  parser_advance(state);

  switch (state->current_token.type) {
  case pLPAREN: {
    VALUE type = parse_type(state);
    parser_advance_assert(state, pRPAREN);
    return type;
  }
  case kBOOL: {
    return rbs_bases_bool(rbs_location_current_token(state));
  }
  case kBOT: {
    return rbs_bases_bottom(rbs_location_current_token(state));
  }
  case kCLASS: {
    return rbs_bases_class(rbs_location_current_token(state));
  }
  case kINSTANCE: {
    return rbs_bases_instance(rbs_location_current_token(state));
  }
  case kNIL: {
    return rbs_bases_nil(rbs_location_current_token(state));
  }
  case kSELF: {
    return rbs_bases_self(rbs_location_current_token(state));
  }
  case kTOP: {
    return rbs_bases_top(rbs_location_current_token(state));
  }
  case kVOID: {
    return rbs_bases_void(rbs_location_current_token(state));
  }
  case kUNTYPED: {
    return rbs_bases_any(false, rbs_location_current_token(state));
  }
  case k__TODO__: {
    return rbs_bases_any(true, rbs_location_current_token(state));
  }
  case tINTEGER: {
    VALUE literal = rb_funcall(
      string_of_loc(state, state->current_token.range.start, state->current_token.range.end),
      rb_intern("to_i"),
      0
    );
    return rbs_literal(
      literal,
      rbs_location_current_token(state)
    );
  }
  case kTRUE: {
    return rbs_literal(Qtrue, rbs_location_current_token(state));
  }
  case kFALSE: {
    return rbs_literal(Qfalse, rbs_location_current_token(state));
  }
  case tSQSTRING:
  case tDQSTRING: {
    VALUE literal = rbs_unquote_string(state, state->current_token.range, 0);
    return rbs_literal(
      literal,
      rbs_location_current_token(state)
    );
  }
  case tSYMBOL:
  case tSQSYMBOL:
  case tDQSYMBOL: {
    return parse_symbol(state);
  }
  case tUIDENT: {
    const char *name_str = peek_token(state->lexstate, state->current_token);
    size_t name_len = token_bytes(state->current_token);

    rbs_constant_id_t name = rbs_constant_pool_find(&state->constant_pool, (const uint8_t *) name_str, name_len);

    if (parser_typevar_member(state, name)) {
      ID name = rb_intern3(name_str, name_len, rb_enc_get(state->lexstate->string));
      return rbs_variable(ID2SYM(name), rbs_location_current_token(state));
    }
    // fallthrough for type name
  }
  case tULIDENT: // fallthrough
  case tLIDENT: // fallthrough
  case pCOLON2: {
    return parse_instance_type(state, true);
  }
  case kSINGLETON: {
    return parse_singleton_type(state);
  }
  case pLBRACKET: {
    range rg;
    rg.start = state->current_token.range.start;
    VALUE types = EMPTY_ARRAY;
    if (state->next_token.type != pRBRACKET) {
      parse_type_list(state, pRBRACKET, &types);
    }
    parser_advance_assert(state, pRBRACKET);
    rg.end = state->current_token.range.end;

    return rbs_tuple(types, rbs_new_location(state->buffer, rg));
  }
  case pAREF_OPR: {
    return rbs_tuple(EMPTY_ARRAY, rbs_new_location(state->buffer, state->current_token.range));
  }
  case pLBRACE: {
    position start = state->current_token.range.start;
    VALUE fields = parse_record_attributes(state);
    parser_advance_assert(state, pRBRACE);
    position end = state->current_token.range.end;
    VALUE location = rbs_location_pp(state->buffer, &start, &end);
    return rbs_record(fields, location);
  }
  case pHAT: {
    return parse_proc_type(state);
  }
  default:
    raise_syntax_error(
      state,
      state->current_token,
      "unexpected token for simple type"
    );
  }
}

/*
  intersection ::= {} optional `&` ... '&' <optional>
                 | {} <optional>
*/
static VALUE parse_intersection(parserstate *state) {
  position start = state->next_token.range.start;
  VALUE type = parse_optional(state);
  if (state->next_token.type != pAMP) {
    return type;
  }

  VALUE intersection_types = rb_ary_new();
  rb_ary_push(intersection_types, type);
  while (state->next_token.type == pAMP) {
    parser_advance(state);
    rb_ary_push(intersection_types, parse_optional(state));
  }
  range rg = (range) {
    .start = start,
    .end = state->current_token.range.end,
  };
  VALUE location = rbs_new_location(state->buffer, rg);
  return rbs_intersection(intersection_types, location);
}

/*
  union ::= {} intersection '|' ... '|' <intersection>
          | {} <intersection>
*/
VALUE parse_type(parserstate *state) {
  position start = state->next_token.range.start;
  VALUE type = parse_intersection(state);
  if (state->next_token.type != pBAR) {
    return type;
  }

  VALUE union_types = rb_ary_new();
  rb_ary_push(union_types, type);
  while (state->next_token.type == pBAR) {
    parser_advance(state);
    rb_ary_push(union_types, parse_intersection(state));
  }
  range rg = (range) {
    .start = start,
    .end = state->current_token.range.end,
  };
  VALUE location = rbs_new_location(state->buffer, rg);
  return rbs_union(union_types, location);
}

/*
  type_param ::= {} kUNCHECKED? (kIN|kOUT|) <tUIDENT> <upper_bound?> <default_type?>   (module_type_params == true)

  type_param ::= {} <tUIDENT> <upper_bound?> <default_type?>                           (module_type_params == false)

  `ranges` must be 8-array or more to store ranges for:

  0: all range
  1: unchecked keyword
  2: variance
  3: name
  4: upper_bound_operator
  5: upper_bound
  6: default_type_operator
  7: default_type

  `values` must be 5-array or more to store objects for:

  0: unchecked (Qtrue or Qnil)
  1: variance (:invariant, :covariant, :contravariant, or Qnil)
  2: name (Symbol)
  3: upper_bound (type or Qnil)
  4: default_type (type or Qnil)
*/
static void parse_type_param(parserstate *state, bool module_type_params, bool required_param_allowed, range ranges[], VALUE values[]) {
  range all_range = NULL_RANGE;

  range unchecked_range = NULL_RANGE;
  VALUE unchecked = Qnil;

  parser_advance(state);

  if (module_type_params) {
    if (state->current_token.type == kUNCHECKED) {
      unchecked_range = state->current_token.range;
      unchecked = Qtrue;
      all_range.start = unchecked_range.start;
      parser_advance(state);
    }
  }

  range variance_range = NULL_RANGE;
  VALUE variance = Qnil;
  if (module_type_params) {
    switch (state->current_token.type) {
      case kIN:
        variance = ID2SYM(rb_intern("contravariant"));
        variance_range = state->current_token.range;
        if (null_position_p(all_range.start)) {
          all_range.start = variance_range.start;
        }
        parser_advance(state);
        break;
      case kOUT:
        variance = ID2SYM(rb_intern("covariant"));
        variance_range = state->current_token.range;
        if (null_position_p(all_range.start)) {
          all_range.start = variance_range.start;
        }
        parser_advance(state);
        break;
      default:
        // nop
        break;
    }
  }

  range name_range = state->current_token.range;
  rbs_constant_id_t id = rbs_constant_pool_insert_shared(
    &state->constant_pool,
    (const uint8_t *) peek_token(state->lexstate, state->current_token),
    token_bytes(state->current_token)
  );

  if (null_position_p(all_range.start)) {
    all_range.start = name_range.start;
  }
  all_range.end = name_range.end;
  VALUE name = ID2SYM(INTERN_TOKEN(state, state->current_token));
  parser_insert_typevar(state, id);

  range upper_bound_range = NULL_RANGE;
  range upper_bound_operator_range = NULL_RANGE;
  VALUE upper_bound = Qnil;

  if (state->next_token.type == pLT) {
    parser_advance(state);
    upper_bound_operator_range = state->current_token.range;
    upper_bound = parse_type(state);
    upper_bound_range = (range) {
      .start = upper_bound_operator_range.start,
      .end = state->current_token.range.end
    };
    all_range.end = state->current_token.range.end;
  }

  range default_type_range = NULL_RANGE;
  range default_type_operator_range = NULL_RANGE;
  VALUE default_type = Qnil;

  if (state->next_token.type == pEQ) {
    parser_advance(state);
    default_type_operator_range = state->current_token.range;
    default_type = parse_type(state);
    default_type_range = (range) {
      .start = default_type_operator_range.start,
      .end = state->current_token.range.end
    };
    all_range.end = state->current_token.range.end;
  } else {
    if (!required_param_allowed) {
      raise_syntax_error(
        state,
        state->current_token,
        "required type parameter is not allowed after optional type parameter"
      );
    }
  }

  ranges[0] = all_range;
  ranges[1] = unchecked_range;
  ranges[2] = variance_range;
  ranges[3] = name_range;
  ranges[4] = upper_bound_operator_range;
  ranges[5] = upper_bound_range;
  ranges[6] = default_type_operator_range;
  ranges[7] = default_type_range;

  values[0] = unchecked;
  values[1] = variance;
  values[2] = name;
  values[3] = upper_bound;
  values[4] = default_type;
}

/*
  type_params ::= {} `[` type_param `,` ... <`]`>
                | {<>}

  type_param ::= kUNCHECKED? (kIN|kOUT|) tUIDENT upper_bound? default_type?   (module_type_params == true)

  type_param ::= tUIDENT upper_bound? default_type?                           (module_type_params == false)
*/
static VALUE parse_type_params(parserstate *state, range *rg, bool module_type_params) {
  VALUE params = EMPTY_ARRAY;

  bool required_param_allowed = true;

  if (state->next_token.type == pLBRACKET) {
    rg->start = state->next_token.range.start;

    parser_advance(state);

    while (true) {
      range ranges[8];
      VALUE values[5];

      parse_type_param(state, module_type_params, required_param_allowed, ranges, values);

      range param_range = ranges[0];
      range unchecked_range = ranges[1];
      range variance_range = ranges[2];
      range name_range = ranges[3];
      range upper_bound_range = ranges[5];
      range default_type_range = ranges[7];

      VALUE unchecked = values[0];
      VALUE variance = RB_TEST(values[1]) ? values[1] : ID2SYM(rb_intern("invariant"));
      VALUE name = values[2];
      VALUE upper_bound = values[3];
      VALUE default_type = values[4];

      VALUE location = rbs_new_location(state->buffer, param_range);
      rbs_loc *loc = rbs_check_location(location);
      rbs_loc_alloc_children(loc, 5);
      rbs_loc_add_required_child(loc, INTERN("name"), name_range);
      rbs_loc_add_optional_child(loc, INTERN("variance"), variance_range);
      rbs_loc_add_optional_child(loc, INTERN("unchecked"), unchecked_range);
      rbs_loc_add_optional_child(loc, INTERN("upper_bound"), upper_bound_range);
      rbs_loc_add_optional_child(loc, INTERN("default"), default_type_range);

      VALUE param = rbs_ast_type_param(name, variance, upper_bound, default_type, unchecked, location);

      if (RB_TEST(default_type)) {
        required_param_allowed = false;
      }

      if (RB_TEST(unchecked)) {
        rb_funcall(param, rb_intern("unchecked!"), 0);
      }

      melt_array(&params);
      rb_ary_push(params, param);

      if (state->next_token.type == pCOMMA) {
        parser_advance(state);
      }

      if (state->next_token.type == pRBRACKET) {
        break;
      }
    }

    parser_advance_assert(state, pRBRACKET);
    rg->end = state->current_token.range.end;
  } else {
    *rg = NULL_RANGE;
  }

  rb_funcall(
    RBS_AST_TypeParam,
    rb_intern("resolve_variables"),
    1,
    params
  );

  return params;
}

/*
  method_type ::= {} type_params <function>
  */
VALUE parse_method_type(parserstate *state) {
  parser_push_typevar_table(state, false);

  range rg;
  rg.start = state->next_token.range.start;

  range params_range = NULL_RANGE;
  VALUE type_params = parse_type_params(state, &params_range, false);

  range type_range;
  type_range.start = state->next_token.range.start;

  VALUE function = Qnil;
  VALUE block = Qnil;
  parse_function(state, &function, &block, NULL);

  rg.end = state->current_token.range.end;
  type_range.end = rg.end;

  parser_pop_typevar_table(state);

  VALUE location = rbs_new_location(state->buffer, rg);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 2);
  rbs_loc_add_required_child(loc, INTERN("type"), type_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), params_range);

  return rbs_method_type(
    type_params,
    function,
    block,
    location
  );
}

/*
  global_decl ::= {tGIDENT} `:` <type>
*/
static VALUE parse_global_decl(parserstate *state, VALUE annotations) {
  range decl_range;
  decl_range.start = state->current_token.range.start;

  VALUE comment = get_comment(state, decl_range.start.line);
  range name_range = state->current_token.range;
  VALUE typename = ID2SYM(INTERN_TOKEN(state, state->current_token));

  parser_advance_assert(state, pCOLON);
  range colon_range = state->current_token.range;

  VALUE type = parse_type(state);
  decl_range.end = state->current_token.range.end;

  VALUE location = rbs_new_location(state->buffer, decl_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 2);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);

  return rbs_ast_decl_global(typename, type, location, comment, annotations);
}

/*
  const_decl ::= {const_name} `:` <type>
*/
static VALUE parse_const_decl(parserstate *state, VALUE annotations) {
  range decl_range;

  decl_range.start = state->current_token.range.start;
  VALUE comment = get_comment(state, decl_range.start.line);

  range name_range;
  VALUE typename = parse_type_name(state, CLASS_NAME, &name_range);

  parser_advance_assert(state, pCOLON);
  range colon_range = state->current_token.range;

  VALUE type = parse_type(state);
  decl_range.end = state->current_token.range.end;

  VALUE location = rbs_new_location(state->buffer, decl_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 2);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);

  return rbs_ast_decl_constant(typename, type, location, comment, annotations);
}

/*
  type_decl ::= {kTYPE} alias_name `=` <type>
*/
static VALUE parse_type_decl(parserstate *state, position comment_pos, VALUE annotations) {
  parser_push_typevar_table(state, true);

  range decl_range;
  decl_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, decl_range.start);

  range keyword_range = state->current_token.range;

  parser_advance(state);

  range name_range;
  VALUE typename = parse_type_name(state, ALIAS_NAME, &name_range);

  range params_range;
  VALUE type_params = parse_type_params(state, &params_range, true);

  parser_advance_assert(state, pEQ);
  range eq_range = state->current_token.range;

  VALUE type = parse_type(state);
  decl_range.end = state->current_token.range.end;

  VALUE location = rbs_new_location(state->buffer, decl_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 4);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), params_range);
  rbs_loc_add_required_child(loc, INTERN("eq"), eq_range);

  parser_pop_typevar_table(state);

  return rbs_ast_decl_type_alias(
    typename,
    type_params,
    type,
    annotations,
    location,
    get_comment(state, comment_pos.line)
  );
}

/*
  annotation ::= {<tANNOTATION>}
*/
static VALUE parse_annotation(parserstate *state) {
  VALUE content = rb_funcall(state->buffer, rb_intern("content"), 0);
  rb_encoding *enc = rb_enc_get(content);

  range rg = state->current_token.range;

  int offset_bytes = rb_enc_codelen('%', enc) + rb_enc_codelen('a', enc);

  unsigned int open_char = rb_enc_mbc_to_codepoint(
    RSTRING_PTR(state->lexstate->string) + rg.start.byte_pos + offset_bytes,
    RSTRING_END(state->lexstate->string),
    enc
  );

  unsigned int close_char;

  switch (open_char) {
  case '{':
    close_char = '}';
    break;
  case '(':
    close_char = ')';
    break;
  case '[':
    close_char = ']';
    break;
  case '<':
    close_char = '>';
    break;
  case '|':
    close_char = '|';
    break;
  default:
    rbs_abort();
  }

  int open_bytes = rb_enc_codelen(open_char, enc);
  int close_bytes = rb_enc_codelen(close_char, enc);

  char *buffer = RSTRING_PTR(state->lexstate->string) + rg.start.byte_pos + offset_bytes + open_bytes;
  VALUE string = rb_enc_str_new(
    buffer,
    rg.end.byte_pos - rg.start.byte_pos - offset_bytes - open_bytes - close_bytes,
    enc
  );
  rb_funcall(string, rb_intern("strip!"), 0);

  VALUE location = rbs_location_current_token(state);

  return rbs_ast_annotation(string, location);
}

/*
  annotations ::= {} annotation ... <annotation>
                | {<>}
*/
static void parse_annotations(parserstate *state, VALUE *annotations, position *annot_pos) {
  *annot_pos = NullPosition;

  while (true) {
    if (state->next_token.type == tANNOTATION) {
      parser_advance(state);

      if (null_position_p((*annot_pos))) {
        *annot_pos = state->current_token.range.start;
      }

      melt_array(annotations);
      rb_ary_push(*annotations, parse_annotation(state));
    } else {
      break;
    }
  }
}

/*
  method_name ::= {} <IDENT | keyword>
                | {} (IDENT | keyword)~<`?`>
*/
static VALUE parse_method_name(parserstate *state, range *range) {
  parser_advance(state);

  switch (state->current_token.type)
  {
  case tUIDENT:
  case tLIDENT:
  case tULIDENT:
  case tULLIDENT:
  KEYWORD_CASES
    if (state->next_token.type == pQUESTION && state->current_token.range.end.byte_pos == state->next_token.range.start.byte_pos) {
      range->start = state->current_token.range.start;
      range->end = state->next_token.range.end;
      parser_advance(state);

      ID id = rb_intern3(
        RSTRING_PTR(state->lexstate->string) + range->start.byte_pos,
        range->end.byte_pos - range->start.byte_pos,
        rb_enc_get(state->lexstate->string)
      );

      return ID2SYM(id);
    } else {
      *range = state->current_token.range;
      return ID2SYM(INTERN_TOKEN(state, state->current_token));
    }

  case tBANGIDENT:
  case tEQIDENT:
    *range = state->current_token.range;
    return ID2SYM(INTERN_TOKEN(state, state->current_token));

  case tQIDENT: {
    return rb_to_symbol(rbs_unquote_string(state, state->current_token.range, 0));
  }

  case pBAR:
  case pHAT:
  case pAMP:
  case pSTAR:
  case pSTAR2:
  case pLT:
  case pAREF_OPR:
  case tOPERATOR:
    *range = state->current_token.range;
    return ID2SYM(INTERN_TOKEN(state, state->current_token));

  default:
    raise_syntax_error(
      state,
      state->current_token,
      "unexpected token for method name"
    );
  }
}

typedef enum {
  INSTANCE_KIND,
  SINGLETON_KIND,
  INSTANCE_SINGLETON_KIND
} InstanceSingletonKind;

/*
  instance_singleton_kind ::= {<>}
                            | {} kSELF <`.`>
                            | {} kSELF~`?` <`.`>

  @param allow_selfq `true` to accept `self?` kind.
*/
static InstanceSingletonKind parse_instance_singleton_kind(parserstate *state, bool allow_selfq, range *rg) {
  InstanceSingletonKind kind = INSTANCE_KIND;

  if (state->next_token.type == kSELF) {
    range self_range = state->next_token.range;

    if (state->next_token2.type == pDOT) {
      parser_advance(state);
      parser_advance(state);
      kind = SINGLETON_KIND;
    } else if (
      state->next_token2.type == pQUESTION
    && state->next_token.range.end.char_pos == state->next_token2.range.start.char_pos
    && state->next_token3.type == pDOT
    && allow_selfq) {
      parser_advance(state);
      parser_advance(state);
      parser_advance(state);
      kind = INSTANCE_SINGLETON_KIND;
    }

    *rg = (range) {
      .start = self_range.start,
      .end = state->current_token.range.end,
    };
  } else {
    *rg = NULL_RANGE;
  }

  return kind;
}

/**
 * def_member ::= {kDEF} method_name `:` <method_types>
 *              | {kPRIVATE} kDEF method_name `:` <method_types>
 *              | {kPUBLIC} kDEF method_name `:` <method_types>
 *
 * method_types ::= {} <method_type>
 *                | {} <`...`>
 *                | {} method_type `|` <method_types>
 *
 * @param instance_only `true` to reject singleton method definition.
 * @param accept_overload `true` to accept overloading (...) definition.
 * */
static VALUE parse_member_def(parserstate *state, bool instance_only, bool accept_overload, position comment_pos, VALUE annotations) {
  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);

  VALUE comment = get_comment(state, comment_pos.line);

  range visibility_range;
  VALUE visibility;
  switch (state->current_token.type)
  {
  case kPRIVATE: {
    visibility_range = state->current_token.range;
    visibility = ID2SYM(rb_intern("private"));
    member_range.start = visibility_range.start;
    parser_advance(state);
    break;
  }
  case kPUBLIC: {
    visibility_range = state->current_token.range;
    visibility = ID2SYM(rb_intern("public"));
    member_range.start = visibility_range.start;
    parser_advance(state);
    break;
  }
  default:
    visibility_range = NULL_RANGE;
    visibility = Qnil;
    break;
  }

  range keyword_range = state->current_token.range;

  range kind_range;
  InstanceSingletonKind kind;
  if (instance_only) {
    kind_range = NULL_RANGE;
    kind = INSTANCE_KIND;
  } else {
    kind = parse_instance_singleton_kind(state, NIL_P(visibility), &kind_range);
  }

  range name_range;
  VALUE name = parse_method_name(state, &name_range);
  VALUE overloads = rb_ary_new();
  VALUE overloading = Qfalse;

  if (state->next_token.type == pDOT && RB_SYM2ID(name) == rb_intern("self?")) {
    raise_syntax_error(
      state,
      state->next_token,
      "`self?` method cannot have visibility"
    );
  } else {
    parser_advance_assert(state, pCOLON);
  }

  parser_push_typevar_table(state, kind != INSTANCE_KIND);

  range overloading_range = NULL_RANGE;
  bool loop = true;
  while (loop) {
    VALUE annotations = EMPTY_ARRAY;
    position overload_annot_pos = NullPosition;

    if (state->next_token.type == tANNOTATION) {
      parse_annotations(state, &annotations, &overload_annot_pos);
    }

    switch (state->next_token.type) {
    case pLPAREN:
    case pARROW:
    case pLBRACE:
    case pLBRACKET:
    case pQUESTION:
      {
        VALUE method_type = parse_method_type(state);
        rb_ary_push(overloads, rbs_ast_members_method_definition_overload(annotations, method_type));
        member_range.end = state->current_token.range.end;
        break;
      }

    case pDOT3:
      if (accept_overload) {
        overloading = Qtrue;
        parser_advance(state);
        loop = false;
        overloading_range = state->current_token.range;
        member_range.end = overloading_range.end;
        break;
      } else {
        raise_syntax_error(
          state,
          state->next_token,
          "unexpected overloading method definition"
        );
      }

    default:
      raise_syntax_error(
        state,
        state->next_token,
        "unexpected token for method type"
      );
    }

    if (state->next_token.type == pBAR) {
      parser_advance(state);
    } else {
      loop = false;
    }
  }

  parser_pop_typevar_table(state);

  VALUE k;
  switch (kind) {
  case INSTANCE_KIND:
    k = ID2SYM(rb_intern("instance"));
    break;
  case SINGLETON_KIND:
    k = ID2SYM(rb_intern("singleton"));
    break;
  case INSTANCE_SINGLETON_KIND:
    k = ID2SYM(rb_intern("singleton_instance"));
    break;
  default:
    rbs_abort();
  }

  VALUE location = rbs_new_location(state->buffer, member_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 5);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_optional_child(loc, INTERN("kind"), kind_range);
  rbs_loc_add_optional_child(loc, INTERN("overloading"), overloading_range);
  rbs_loc_add_optional_child(loc, INTERN("visibility"), visibility_range);

  return rbs_ast_members_method_definition(
    name,
    k,
    overloads,
    annotations,
    location,
    comment,
    overloading,
    visibility
  );
}

/**
 * class_instance_name ::= {} <class_name>
 *                       | {} class_name `[` type args <`]`>
 *
 * @param kind
 * */
void class_instance_name(parserstate *state, TypeNameKind kind, VALUE *name, VALUE *args, range *name_range, range *args_range) {
  parser_advance(state);

  *name = parse_type_name(state, kind, name_range);

  if (state->next_token.type == pLBRACKET) {
    parser_advance(state);
    args_range->start = state->current_token.range.start;
    parse_type_list(state, pRBRACKET, args);
    parser_advance_assert(state, pRBRACKET);
    args_range->end = state->current_token.range.end;
  } else {
    *args_range = NULL_RANGE;
  }
}

/**
 *  mixin_member ::= {kINCLUDE} <class_instance_name>
 *                 | {kPREPEND} <class_instance_name>
 *                 | {kEXTEND} <class_instance_name>
 *
 * @param from_interface `true` when the member is in an interface.
 * */
static VALUE parse_mixin_member(parserstate *state, bool from_interface, position comment_pos, VALUE annotations) {
  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);

  enum TokenType type = state->current_token.type;
  range keyword_range = state->current_token.range;

  bool reset_typevar_scope;
  switch (type)
  {
  case kINCLUDE:
    reset_typevar_scope = false;
    break;
  case kEXTEND:
    reset_typevar_scope = true;
    break;
  case kPREPEND:
    reset_typevar_scope = false;
    break;
  default:
    rbs_abort();
  }

  if (from_interface) {
    if (state->current_token.type != kINCLUDE) {
      raise_syntax_error(
        state,
        state->current_token,
        "unexpected mixin in interface declaration"
      );
    }
  }

  parser_push_typevar_table(state, reset_typevar_scope);

  VALUE name;
  VALUE args = EMPTY_ARRAY;
  range name_range;
  range args_range = NULL_RANGE;
  class_instance_name(
    state,
    from_interface ? INTERFACE_NAME : (INTERFACE_NAME | CLASS_NAME),
    &name, &args, &name_range, &args_range
  );

  parser_pop_typevar_table(state);

  member_range.end = state->current_token.range.end;

  VALUE location = rbs_new_location(state->buffer, member_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 3);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_optional_child(loc, INTERN("args"), args_range);

  VALUE comment = get_comment(state, comment_pos.line);
  switch (type)
  {
  case kINCLUDE:
    return rbs_ast_members_include(name, args, annotations, location, comment);
  case kEXTEND:
    return rbs_ast_members_extend(name, args, annotations, location, comment);
  case kPREPEND:
    return rbs_ast_members_prepend(name, args, annotations, location, comment);
  default:
    rbs_abort();
  }
}

/**
 * @code
 * alias_member ::= {kALIAS} method_name <method_name>
 *                | {kALIAS} kSELF `.` method_name kSELF `.` <method_name>
 * @endcode
 *
 * @param[in] instance_only `true` to reject `self.` alias.
 * */
static VALUE parse_alias_member(parserstate *state, bool instance_only, position comment_pos, VALUE annotations) {
  range member_range;
  member_range.start = state->current_token.range.start;
  range keyword_range = state->current_token.range;

  comment_pos = nonnull_pos_or(comment_pos, member_range.start);
  VALUE comment = get_comment(state, comment_pos.line);

  VALUE kind, new_name, old_name;
  range new_kind_range, old_kind_range, new_name_range, old_name_range;
  if (!instance_only && state->next_token.type == kSELF) {
    kind = ID2SYM(rb_intern("singleton"));

    new_kind_range.start = state->next_token.range.start;
    new_kind_range.end = state->next_token2.range.end;
    parser_advance_assert(state, kSELF);
    parser_advance_assert(state, pDOT);
    new_name = parse_method_name(state, &new_name_range);

    old_kind_range.start = state->next_token.range.start;
    old_kind_range.end = state->next_token2.range.end;
    parser_advance_assert(state, kSELF);
    parser_advance_assert(state, pDOT);
    old_name = parse_method_name(state, &old_name_range);
  } else {
    kind = ID2SYM(rb_intern("instance"));
    new_name = parse_method_name(state, &new_name_range);
    old_name = parse_method_name(state, &old_name_range);

    new_kind_range = NULL_RANGE;
    old_kind_range = NULL_RANGE;
  }

  member_range.end = state->current_token.range.end;
  VALUE location = rbs_new_location(state->buffer, member_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 5);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("new_name"), new_name_range);
  rbs_loc_add_required_child(loc, INTERN("old_name"), old_name_range);
  rbs_loc_add_optional_child(loc, INTERN("new_kind"), new_kind_range);
  rbs_loc_add_optional_child(loc, INTERN("old_kind"), old_kind_range);

  return rbs_ast_members_alias(
    new_name,
    old_name,
    kind,
    annotations,
    location,
    comment
  );
}

/*
  variable_member ::= {tAIDENT} `:` <type>
                    | {kSELF} `.` tAIDENT `:` <type>
                    | {tA2IDENT} `:` <type>
*/
static VALUE parse_variable_member(parserstate *state, position comment_pos, VALUE annotations) {
  if (rb_array_len(annotations) > 0) {
    raise_syntax_error(
      state,
      state->current_token,
      "annotation cannot be given to variable members"
    );
  }

  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);
  VALUE comment = get_comment(state, comment_pos.line);

  switch (state->current_token.type)
  {
  case tAIDENT:
  case kATRBS:
  {
    range name_range = state->current_token.range;
    VALUE name = ID2SYM(INTERN_TOKEN(state, state->current_token));

    parser_advance_assert(state, pCOLON);
    range colon_range = state->current_token.range;

    VALUE type = parse_type(state);
    member_range.end = state->current_token.range.end;

    VALUE location = rbs_new_location(state->buffer, member_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 3);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);
    rbs_loc_add_optional_child(loc, INTERN("kind"), NULL_RANGE);

    return rbs_ast_members_instance_variable(name, type, location, comment);
  }
  case tA2IDENT: {
    range name_range = state->current_token.range;
    VALUE name = ID2SYM(INTERN_TOKEN(state, state->current_token));

    parser_advance_assert(state, pCOLON);
    range colon_range = state->current_token.range;

    parser_push_typevar_table(state, true);
    VALUE type = parse_type(state);
    parser_pop_typevar_table(state);
    member_range.end = state->current_token.range.end;

    VALUE location = rbs_new_location(state->buffer, member_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 3);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);
    rbs_loc_add_optional_child(loc, INTERN("kind"), NULL_RANGE);

    return rbs_ast_members_class_variable(name, type, location, comment);
  }
  case kSELF: {
    range kind_range = {
      .start = state->current_token.range.start,
      .end = state->next_token.range.end
    };

    parser_advance_assert(state, pDOT);
    if (state->next_token.type == tAIDENT || state->next_token.type == kATRBS) {
      parser_advance(state);
    } else {
      raise_syntax_error(
        state,
        state->current_token,
        "expected a instance variable name"
      );
    }

    range name_range = state->current_token.range;
    VALUE name = ID2SYM(INTERN_TOKEN(state, state->current_token));

    parser_advance_assert(state, pCOLON);
    range colon_range = state->current_token.range;

    parser_push_typevar_table(state, true);
    VALUE type = parse_type(state);
    parser_pop_typevar_table(state);
    member_range.end = state->current_token.range.end;

    VALUE location = rbs_new_location(state->buffer, member_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 3);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);
    rbs_loc_add_optional_child(loc, INTERN("kind"), kind_range);

    return rbs_ast_members_class_instance_variable(name, type, location, comment);
  }
  default:
    rbs_abort();
  }
}

/*
  visibility_member ::= {<`public`>}
                      | {<`private`>}
*/
static VALUE parse_visibility_member(parserstate *state, VALUE annotations) {
  if (rb_array_len(annotations) > 0) {
    raise_syntax_error(
      state,
      state->current_token,
      "annotation cannot be given to visibility members"
    );
  }

  VALUE location = rbs_new_location(state->buffer, state->current_token.range);

  switch (state->current_token.type)
  {
  case kPUBLIC:
    return rbs_ast_members_public(location);
  case kPRIVATE:
    return rbs_ast_members_private(location);
  default:
    rbs_abort();
  }
}

/*
  attribute_member ::= {attr_keyword} attr_name attr_var `:` <type>
                     | {visibility} attr_keyword attr_name attr_var `:` <type>
                     | {attr_keyword} `self` `.` attr_name attr_var `:` <type>
                     | {visibility} attr_keyword `self` `.` attr_name attr_var `:` <type>

  attr_keyword ::= `attr_reader` | `attr_writer` | `attr_accessor`

  visibility ::= `public` | `private`

  attr_var ::=                    # empty
             | `(` tAIDENT `)`    # Ivar name
             | `(` `)`            # No variable
*/
static VALUE parse_attribute_member(parserstate *state, position comment_pos, VALUE annotations) {
  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);
  VALUE comment = get_comment(state, comment_pos.line);

  VALUE visibility;
  range visibility_range;
  switch (state->current_token.type)
  {
  case kPRIVATE:
    visibility = ID2SYM(rb_intern("private"));
    visibility_range = state->current_token.range;
    parser_advance(state);
    break;
  case kPUBLIC:
    visibility = ID2SYM(rb_intern("public"));
    visibility_range = state->current_token.range;
    parser_advance(state);
    break;
  default:
    visibility = Qnil;
    visibility_range = NULL_RANGE;
    break;
  }

  enum TokenType attr_type = state->current_token.type;
  range keyword_range = state->current_token.range;

  range kind_range;
  InstanceSingletonKind is_kind = parse_instance_singleton_kind(state, false, &kind_range);
  VALUE kind = ID2SYM(rb_intern((is_kind == INSTANCE_KIND) ? "instance" : "singleton"));

  range name_range;
  VALUE attr_name = parse_method_name(state, &name_range);

  VALUE ivar_name;
  range ivar_range, ivar_name_range;
  if (state->next_token.type == pLPAREN) {
    parser_advance_assert(state, pLPAREN);
    ivar_range.start = state->current_token.range.start;

    if (parser_advance_if(state, tAIDENT)) {
      ivar_name = ID2SYM(INTERN_TOKEN(state, state->current_token));
      ivar_name_range = state->current_token.range;
    } else {
      ivar_name = Qfalse;
      ivar_name_range = NULL_RANGE;
    }

    parser_advance_assert(state, pRPAREN);
    ivar_range.end = state->current_token.range.end;
  } else {
    ivar_range = NULL_RANGE;
    ivar_name = Qnil;
    ivar_name_range = NULL_RANGE;
  }

  parser_advance_assert(state, pCOLON);
  range colon_range = state->current_token.range;

  parser_push_typevar_table(state, is_kind == SINGLETON_KIND);
  VALUE type = parse_type(state);
  parser_pop_typevar_table(state);
  member_range.end = state->current_token.range.end;

  VALUE location = rbs_new_location(state->buffer, member_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 7);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);
  rbs_loc_add_optional_child(loc, INTERN("kind"), kind_range);
  rbs_loc_add_optional_child(loc, INTERN("ivar"), ivar_range);
  rbs_loc_add_optional_child(loc, INTERN("ivar_name"), ivar_name_range);
  rbs_loc_add_optional_child(loc, INTERN("visibility"), visibility_range);

  switch (attr_type)
  {
  case kATTRREADER:
    return rbs_ast_members_attr_reader(attr_name, type, ivar_name, kind, annotations, location, comment, visibility);
  case kATTRWRITER:
    return rbs_ast_members_attr_writer(attr_name, type, ivar_name, kind, annotations, location, comment, visibility);
  case kATTRACCESSOR:
    return rbs_ast_members_attr_accessor(attr_name, type, ivar_name, kind, annotations, location, comment, visibility);
  default:
    rbs_abort();
  }
}

/*
  interface_members ::= {} ...<interface_member> kEND

  interface_member ::= def_member     (instance method only && no overloading)
                     | mixin_member   (interface only)
                     | alias_member   (instance only)
*/
static VALUE parse_interface_members(parserstate *state) {
  VALUE members = EMPTY_ARRAY;

  while (state->next_token.type != kEND) {
    VALUE annotations = EMPTY_ARRAY;
    position annot_pos = NullPosition;

    parse_annotations(state, &annotations, &annot_pos);

    parser_advance(state);

    VALUE member;
    switch (state->current_token.type) {
    case kDEF: {
      member = parse_member_def(state, true, true, annot_pos, annotations);
      break;
    }

    case kINCLUDE:
    case kEXTEND:
    case kPREPEND: {
      member = parse_mixin_member(state, true, annot_pos, annotations);
      break;
    }

    case kALIAS: {
      member = parse_alias_member(state, true, annot_pos, annotations);
      break;
    }

    default:
      raise_syntax_error(
        state,
        state->current_token,
        "unexpected token for interface declaration member"
      );
    }

    melt_array(&members);
    rb_ary_push(members, member);
  }

  return members;
}

/*
  interface_decl ::= {`interface`} interface_name module_type_params interface_members <kEND>
*/
static VALUE parse_interface_decl(parserstate *state, position comment_pos, VALUE annotations) {
  parser_push_typevar_table(state, true);

  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);

  range keyword_range = state->current_token.range;

  parser_advance(state);

  range name_range;
  VALUE name = parse_type_name(state, INTERFACE_NAME, &name_range);
  range type_params_range;
  VALUE params = parse_type_params(state, &type_params_range, true);
  VALUE members = parse_interface_members(state);

  parser_advance_assert(state, kEND);
  range end_range = state->current_token.range;
  member_range.end = end_range.end;

  parser_pop_typevar_table(state);

  VALUE location = rbs_new_location(state->buffer, member_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 4);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("end"), end_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), type_params_range);

  return rbs_ast_decl_interface(
    name,
    params,
    members,
    annotations,
    location,
    get_comment(state, comment_pos.line)
  );
}

/**
  module_self_type ::= {} <module_name>
                     | {} module_name `[` type_list <`]`>


 * @param state
 * @param module_name Pointer to VALUE to store a TypeName object
 * @param type_args Pointer to an array to store type arguments
 * @param ranges An array of 4-range to store three ranges: module name, open paren, type args, and the close paren.
 */
static void parse_module_self(parserstate *state, VALUE *module_name, VALUE *type_args, range ranges[4]) {
  parser_advance(state);

  ranges[0].start = state->current_token.range.start;
  *module_name = parse_type_name(state, CLASS_NAME | INTERFACE_NAME, &ranges[0]);
  ranges[0].end = state->current_token.range.end;

  if (state->next_token.type == pLBRACKET) {
    parser_advance(state);
    ranges[1] = state->current_token.range;
    ranges[2].start = state->next_token.range.start;
    parse_type_list(state, pRBRACKET, type_args);
    ranges[2].end = state->next_token.range.end;
    parser_advance_assert(state, pRBRACKET);
    ranges[3] = state->current_token.range;
  } else {
    ranges[1] = NULL_RANGE;
    ranges[2] = NULL_RANGE;
    ranges[3] = NULL_RANGE;
  }
}

/*
  module_self_types ::= {`:`} module_self_type `,` ... `,` <module_self_type>
*/
static void parse_module_self_types(parserstate *state, VALUE *array) {
  while (true) {
    range ranges[4];
    VALUE module_name;
    VALUE type_args = EMPTY_ARRAY;

    range self_range = state->current_token.range;
    parse_module_self(state, &module_name, &type_args, ranges);

    range name_range = ranges[0];
    range args_range = ranges[2];
    self_range.end = state->current_token.range.end;

    VALUE location = rbs_new_location(state->buffer, self_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 2);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_optional_child(loc, INTERN("args"), args_range);

    VALUE self_type = rbs_ast_decl_module_self(module_name, type_args, location);
    melt_array(array);
    rb_ary_push(*array, self_type);

    if (state->next_token.type == pCOMMA) {
      parser_advance(state);
    } else {
      break;
    }
  }
}

static VALUE parse_nested_decl(parserstate *state, const char *nested_in, position annot_pos, VALUE annotations);

/*
  module_members ::= {} module_member ... <module_member> kEND
                   | {<>} kEND

  module_member ::= def_member
                  | variable_member
                  | mixin_member
                  | alias_member
                  | attribute_member
                  | `public`
                  | `private`
*/
static VALUE parse_module_members(parserstate *state) {
  VALUE members = EMPTY_ARRAY;

  while (state->next_token.type != kEND) {
    VALUE annotations = EMPTY_ARRAY;
    position annot_pos = NullPosition;
    parse_annotations(state, &annotations, &annot_pos);

    parser_advance(state);

    VALUE member;
    switch (state->current_token.type)
    {
    case kDEF: {
      member = parse_member_def(state, false, true, annot_pos, annotations);
      break;
    }

    case kINCLUDE:
    case kEXTEND:
    case kPREPEND: {
      member = parse_mixin_member(state, false, annot_pos, annotations);
      break;
    }

    case kALIAS: {
      member = parse_alias_member(state, false, annot_pos, annotations);
      break;
    }

    case tAIDENT:
    case kATRBS:
    case tA2IDENT:
    case kSELF: {
      member = parse_variable_member(state, annot_pos, annotations);
      break;
    }

    case kATTRREADER:
    case kATTRWRITER:
    case kATTRACCESSOR: {
      member = parse_attribute_member(state, annot_pos, annotations);
      break;
    }

    case kPUBLIC:
    case kPRIVATE:
      if (state->next_token.range.start.line == state->current_token.range.start.line) {
        switch (state->next_token.type)
        {
        case kDEF: {
          member = parse_member_def(state, false, true, annot_pos, annotations);
          break;
        }
        case kATTRREADER:
        case kATTRWRITER:
        case kATTRACCESSOR: {
          member = parse_attribute_member(state, annot_pos, annotations);
          break;
        }
        default:
          raise_syntax_error(state, state->next_token, "method or attribute definition is expected after visibility modifier");
        }
      } else {
        member = parse_visibility_member(state, annotations);
      }
      break;

    default:
      member = parse_nested_decl(state, "module", annot_pos, annotations);
      break;
    }

    melt_array(&members);
    rb_ary_push(members, member);
  }

  return members;
}

/*
  module_decl ::= {module_name} module_type_params module_members <kEND>
                | {module_name} module_name module_type_params `:` module_self_types module_members <kEND>
*/
static VALUE parse_module_decl0(parserstate *state, range keyword_range, VALUE module_name, range name_range, VALUE comment, VALUE annotations) {
  parser_push_typevar_table(state, true);

  range decl_range;
  decl_range.start = keyword_range.start;
  range type_params_range;
  VALUE type_params = parse_type_params(state, &type_params_range, true);

  VALUE self_types = EMPTY_ARRAY;
  range colon_range;
  range self_types_range;
  if (state->next_token.type == pCOLON) {
    parser_advance(state);
    colon_range = state->current_token.range;
    self_types_range.start = state->next_token.range.start;
    parse_module_self_types(state, &self_types);
    self_types_range.end = state->current_token.range.end;
  } else {
    colon_range = NULL_RANGE;
    self_types_range = NULL_RANGE;
  }

  VALUE members = parse_module_members(state);

  parser_advance_assert(state, kEND);
  range end_range = state->current_token.range;
  decl_range.end = state->current_token.range.end;

  VALUE location = rbs_new_location(state->buffer, decl_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 6);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("end"), end_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), type_params_range);
  rbs_loc_add_optional_child(loc, INTERN("colon"), colon_range);
  rbs_loc_add_optional_child(loc, INTERN("self_types"), self_types_range);

  parser_pop_typevar_table(state);

  return rbs_ast_decl_module(
    module_name,
    type_params,
    self_types,
    members,
    annotations,
    location,
    comment
  );
}

/*
  module_decl ::= {`module`} module_name `=` old_module_name <kEND>
                | {`module`} module_name module_decl0 <kEND>

*/
static VALUE parse_module_decl(parserstate *state, position comment_pos, VALUE annotations) {
  range keyword_range = state->current_token.range;

  comment_pos = nonnull_pos_or(comment_pos, state->current_token.range.start);
  VALUE comment = get_comment(state, comment_pos.line);

  parser_advance(state);
  range module_name_range;
  VALUE module_name = parse_type_name(state, CLASS_NAME, &module_name_range);

  if (state->next_token.type == pEQ) {
    range eq_range = state->next_token.range;
    parser_advance(state);
    parser_advance(state);

    range old_name_range;
    VALUE old_name = parse_type_name(state, CLASS_NAME, &old_name_range);

    range decl_range = {
      .start = keyword_range.start,
      .end = old_name_range.end
    };

    VALUE location = rbs_new_location(state->buffer, decl_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 4);
    rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
    rbs_loc_add_required_child(loc, INTERN("new_name"), module_name_range);
    rbs_loc_add_required_child(loc, INTERN("eq"), eq_range);
    rbs_loc_add_optional_child(loc, INTERN("old_name"), old_name_range);

    return rbs_ast_decl_module_alias(module_name, old_name, location, comment, annotations);
  } else {
    VALUE decl = parse_module_decl0(state, keyword_range, module_name, module_name_range, comment, annotations);
    return decl;
  }
}

/*
  class_decl_super ::= {} `<` <class_instance_name>
                     | {<>}
*/
static VALUE parse_class_decl_super(parserstate *state, range *lt_range) {
  if (parser_advance_if(state, pLT)) {
    *lt_range = state->current_token.range;

    range super_range;
    super_range.start = state->next_token.range.start;

    VALUE name;
    VALUE args = EMPTY_ARRAY;
    range name_range, args_range;
    class_instance_name(state, CLASS_NAME, &name, &args, &name_range, &args_range);

    super_range.end = state->current_token.range.end;

    VALUE location = rbs_new_location(state->buffer, super_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 2);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_optional_child(loc, INTERN("args"), args_range);

    return rbs_ast_decl_class_super(name, args, location);
  } else {
    *lt_range = NULL_RANGE;
    return Qnil;
  }
}

/*
  class_decl ::= {class_name} type_params class_decl_super class_members <`end`>
*/
static VALUE parse_class_decl0(parserstate *state, range keyword_range, VALUE name, range name_range, VALUE comment, VALUE annotations) {
  parser_push_typevar_table(state, true);

  range decl_range;
  decl_range.start = keyword_range.start;

  range type_params_range;
  VALUE type_params = parse_type_params(state, &type_params_range, true);

  range lt_range;
  VALUE super = parse_class_decl_super(state, &lt_range);

  VALUE members = parse_module_members(state);

  parser_advance_assert(state, kEND);

  range end_range = state->current_token.range;

  decl_range.end = end_range.end;

  parser_pop_typevar_table(state);

  VALUE location = rbs_new_location(state->buffer, decl_range);
  rbs_loc *loc = rbs_check_location(location);
  rbs_loc_alloc_children(loc, 5);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("end"), end_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), type_params_range);
  rbs_loc_add_optional_child(loc, INTERN("lt"), lt_range);

  return rbs_ast_decl_class(
    name,
    type_params,
    super,
    members,
    annotations,
    location,
    comment
  );
}

/*
  class_decl ::= {`class`} class_name `=` <class_name>
               | {`class`} class_name <class_decl0>
*/
static VALUE parse_class_decl(parserstate *state, position comment_pos, VALUE annotations) {
  range keyword_range = state->current_token.range;

  comment_pos = nonnull_pos_or(comment_pos, state->current_token.range.start);
  VALUE comment = get_comment(state, comment_pos.line);

  parser_advance(state);
  range class_name_range;
  VALUE class_name = parse_type_name(state, CLASS_NAME, &class_name_range);

  if (state->next_token.type == pEQ) {
    range eq_range = state->next_token.range;
    parser_advance(state);
    parser_advance(state);

    range old_name_range;
    VALUE old_name = parse_type_name(state, CLASS_NAME, &old_name_range);

    range decl_range = {
      .start = keyword_range.start,
      .end = old_name_range.end,
    };

    VALUE location = rbs_new_location(state->buffer, decl_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 4);
    rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
    rbs_loc_add_required_child(loc, INTERN("new_name"), class_name_range);
    rbs_loc_add_required_child(loc, INTERN("eq"), eq_range);
    rbs_loc_add_optional_child(loc, INTERN("old_name"), old_name_range);

    return rbs_ast_decl_class_alias(class_name, old_name, location, comment, annotations);
  } else {
    return parse_class_decl0(state, keyword_range, class_name, class_name_range, comment, annotations);
  }
}

/*
  nested_decl ::= {<const_decl>}
                | {<class_decl>}
                | {<interface_decl>}
                | {<module_decl>}
                | {<class_decl>}
*/
static VALUE parse_nested_decl(parserstate *state, const char *nested_in, position annot_pos, VALUE annotations) {
  parser_push_typevar_table(state, true);

  VALUE decl;
  switch (state->current_token.type) {
  case tUIDENT:
  case pCOLON2: {
    decl = parse_const_decl(state, annotations);
    break;
  }
  case tGIDENT: {
    decl = parse_global_decl(state, annotations);
    break;
  }
  case kTYPE: {
    decl = parse_type_decl(state, annot_pos, annotations);
    break;
  }
  case kINTERFACE: {
    decl = parse_interface_decl(state, annot_pos, annotations);
    break;
  }
  case kMODULE: {
    decl = parse_module_decl(state, annot_pos, annotations);
    break;
  }
  case kCLASS: {
    decl = parse_class_decl(state, annot_pos, annotations);
    break;
  }
  default:
    raise_syntax_error(
      state,
      state->current_token,
      "unexpected token for class/module declaration member"
    );
  }

  parser_pop_typevar_table(state);

  return decl;
}

static VALUE parse_decl(parserstate *state) {
  VALUE annotations = EMPTY_ARRAY;
  position annot_pos = NullPosition;

  parse_annotations(state, &annotations, &annot_pos);

  parser_advance(state);
  switch (state->current_token.type) {
  case tUIDENT:
  case pCOLON2: {
    return parse_const_decl(state, annotations);
  }
  case tGIDENT: {
    return parse_global_decl(state, annotations);
  }
  case kTYPE: {
    return parse_type_decl(state, annot_pos, annotations);
  }
  case kINTERFACE: {
    return parse_interface_decl(state, annot_pos, annotations);
  }
  case kMODULE: {
    return parse_module_decl(state, annot_pos, annotations);
  }
  case kCLASS: {
    return parse_class_decl(state, annot_pos, annotations);
  }
  default:
    raise_syntax_error(
      state,
      state->current_token,
      "cannot start a declaration"
    );
  }
}

/*
  namespace ::= {} (`::`)? (`tUIDENT` `::`)* `tUIDENT` <`::`>
              | {} <>                                            (empty -- returns empty namespace)
*/
static VALUE parse_namespace(parserstate *state, range *rg) {
  bool is_absolute = false;

  if (state->next_token.type == pCOLON2) {
    *rg = (range) {
      .start = state->next_token.range.start,
      .end = state->next_token.range.end,
    };
    is_absolute = true;

    parser_advance(state);
  }

  VALUE path = EMPTY_ARRAY;

  while (true) {
    if (state->next_token.type == tUIDENT && state->next_token2.type == pCOLON2) {
      melt_array(&path);
      rb_ary_push(path, ID2SYM(INTERN_TOKEN(state, state->next_token)));
      if (null_position_p(rg->start)) {
        rg->start = state->next_token.range.start;
      }
      rg->end = state->next_token2.range.end;
      parser_advance(state);
      parser_advance(state);
    } else {
      break;
    }
  }

  return rbs_namespace(path, is_absolute ? Qtrue : Qfalse);
}

/*
  use_clauses ::= {} use_clause `,` ... `,` <use_clause>

  use_clause ::= {} namespace <tUIDENT>
               | {} namespace tUIDENT `as` <tUIDENT>
               | {} namespace <tSTAR>
*/
static void parse_use_clauses(parserstate *state, VALUE clauses) {
  while (true) {
    range namespace_range = NULL_RANGE;
    VALUE namespace = parse_namespace(state, &namespace_range);

    switch (state->next_token.type)
    {
      case tLIDENT:
      case tULIDENT:
      case tUIDENT: {
        parser_advance(state);

        enum TokenType ident_type = state->current_token.type;

        range type_name_range = null_range_p(namespace_range)
          ? state->current_token.range
          : (range) { .start = namespace_range.start, .end = state->current_token.range.end };

        VALUE type_name = rbs_type_name(namespace, ID2SYM(INTERN_TOKEN(state, state->current_token)));

        range keyword_range = NULL_RANGE;
        range new_name_range = NULL_RANGE;

        VALUE new_name = Qnil;
        range clause_range = type_name_range;
        if (state->next_token.type == kAS) {
          parser_advance(state);
          keyword_range = state->current_token.range;

          if (ident_type == tUIDENT) parser_advance_assert(state, tUIDENT);
          if (ident_type == tLIDENT) parser_advance_assert(state, tLIDENT);
          if (ident_type == tULIDENT) parser_advance_assert(state, tULIDENT);

          new_name = ID2SYM(INTERN_TOKEN(state, state->current_token));
          new_name_range = state->current_token.range;
          clause_range.end = new_name_range.end;
        }

        VALUE location = rbs_new_location(state->buffer, clause_range);
        rbs_loc *loc = rbs_check_location(location);
        rbs_loc_alloc_children(loc, 3);
        rbs_loc_add_required_child(loc, INTERN("type_name"), type_name_range);
        rbs_loc_add_optional_child(loc, INTERN("keyword"), keyword_range);
        rbs_loc_add_optional_child(loc, INTERN("new_name"), new_name_range);

        rb_ary_push(clauses, rbs_ast_directives_use_single_clause(type_name, new_name, location));

        break;
      }
      case pSTAR:
      {
        range clause_range = namespace_range;
        parser_advance(state);

        range star_range = state->current_token.range;
        clause_range.end = star_range.end;

        VALUE location = rbs_new_location(state->buffer, clause_range);
        rbs_loc *loc = rbs_check_location(location);
        rbs_loc_alloc_children(loc, 2);
        rbs_loc_add_required_child(loc, INTERN("namespace"), namespace_range);
        rbs_loc_add_required_child(loc, INTERN("star"), star_range);

        rb_ary_push(clauses, rbs_ast_directives_use_wildcard_clause(namespace, location));

        break;
      }
      default:
        raise_syntax_error(
          state,
          state->next_token,
          "use clause is expected"
        );
    }

    if (state->next_token.type == pCOMMA) {
      parser_advance(state);
    } else {
      break;
    }
  }

  return;
}

/*
  use_directive ::= {} `use` <clauses>
 */
static VALUE parse_use_directive(parserstate *state) {
  if (state->next_token.type == kUSE) {
    parser_advance(state);

    range keyword_range = state->current_token.range;

    VALUE clauses = rb_ary_new();
    parse_use_clauses(state, clauses);

    range directive_range = keyword_range;
    directive_range.end = state->current_token.range.end;

    VALUE location = rbs_new_location(state->buffer, directive_range);
    rbs_loc *loc = rbs_check_location(location);
    rbs_loc_alloc_children(loc, 1);
    rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);

    return rbs_ast_directives_use(clauses, location);
  } else {
    return Qnil;
  }
}

VALUE parse_signature(parserstate *state) {
  VALUE dirs = EMPTY_ARRAY;
  VALUE decls = EMPTY_ARRAY;

  while (state->next_token.type == kUSE) {
    melt_array(&dirs);
    rb_ary_push(dirs, parse_use_directive(state));
  }

  while (state->next_token.type != pEOF) {
    melt_array(&decls);
    rb_ary_push(decls, parse_decl(state));
  }

  VALUE ret = rb_ary_new();
  rb_ary_push(ret, dirs);
  rb_ary_push(ret, decls);
  return ret;
}

/*
inline_comment ::= {}                  // nil
                 | {} <`--` any string> // comment
*/
VALUE parse_inline_comment(parserstate *state) {
  if (state->next_token.type != pMINUS2) {
    return Qnil;
  }

  parser_advance(state);

  return rbs_new_location(state->buffer, state->current_token.range);
}

/*
  annotated_method_type ::= {} annotations <method_type>

  Returns a pair of an array of annotation and method type.
*/
VALUE parse_annotated_method_type(parserstate *state) {
  VALUE annotations = EMPTY_ARRAY;
  position annot_pos = NullPosition;

  parse_annotations(state, &annotations, &annot_pos);

  VALUE method_type = parse_method_type(state);

  return rbs_ast_ruby_annotation_method_types_annotation_overload(annotations, method_type);
}

/**
  inline_skip_annotation ::= {} <`skip`>
                           | {} `skip` <inline_comment>
 */
VALUE parse_inline_skip_annotation(parserstate *state, range rbs_range) {
  range skip_range = state->next_token.range;
  parser_advance(state);

  range location_range = {
    .start = rbs_range.start,
    .end = skip_range.end
  };
  VALUE rbs_location = rbs_new_location(state->buffer, rbs_range);
  VALUE skip_location = rbs_new_location(state->buffer, skip_range);

  VALUE comment = parse_inline_comment(state);

  return rbs_ast_ruby_annotation_skip_annotation(
    rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
    comment,
    rbs_location,
    skip_location
  );
}

/**
  inline_override_annotation ::= {} <`override`>
 */
VALUE parse_override_annotation(parserstate *state, range rbs_range) {
  range override_range = state->next_token.range;
  parser_advance(state);

  return rbs_ast_ruby_annotation_override_annotation(
    rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
    rbs_new_location(state->buffer, rbs_range),
    rbs_new_location(state->buffer, override_range)
  );
}

/**
  inline_return_type_annotation ::= {} `return` `:` <type>
                                  | {} `return` `:` type <inline_comment>
 */
VALUE parse_inline_return_type_annotation(parserstate *state, range rbs_range) {
  range return_range = state->next_token.range;
  parser_advance(state);

  range colon_range = state->next_token.range;
  parser_advance(state);

  VALUE type = parse_type(state);
  VALUE comment = parse_inline_comment(state);

  return rbs_ast_ruby_annotation_return_type_annotation(
    rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
    rbs_new_location(state->buffer, rbs_range),
    rbs_new_location(state->buffer, return_range),
    rbs_new_location(state->buffer, colon_range),
    type,
    comment
  );
}

/**
 * inline_block_param_type_annotation ::= {} `& ident `:` <block>
 *                                      | {} `& ident `:` block <inline_comment>
 */
VALUE parse_inline_block_param_type_annotation(parserstate *state, range rbs_range) {
  range operator_range = state->next_token.range;
  parser_advance(state);

  range param_name_range = NULL_RANGE;
  if (state->next_token.type != pCOLON) {
    param_name_range = state->next_token.range;
    parser_advance(state);
  }

  range colon_range = state->next_token.range;
  parser_advance(state);

  range question_mark_range = NULL_RANGE;
  if (state->next_token.type == pQUESTION) {
    question_mark_range = state->next_token.range;
    parser_advance(state);
  }

  VALUE function = Qnil;
  VALUE function_self_type = Qnil;
  parse_function(state, &function, NULL, &function_self_type);

  VALUE comment = parse_inline_comment(state);

  position end_pos = state->current_token.range.end;

  return rbs_ast_ruby_annotation_block_param_type_annotation(
    rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = end_pos }),
    rbs_new_location(state->buffer, rbs_range),
    rbs_new_location(state->buffer, operator_range),
    null_range_p(param_name_range) ? Qnil : rbs_new_location(state->buffer, param_name_range),
    rbs_new_location(state->buffer, colon_range),
    null_range_p(question_mark_range) ? Qnil : rbs_new_location(state->buffer, question_mark_range),
    rbs_block(function, null_range_p(question_mark_range) ? Qtrue : Qfalse, function_self_type),
    comment
  );
}

/**
  inline-generic-annotation ::= {} `generic` <type_param> <inline_comment?>
 */
VALUE parse_generic_annotation(parserstate *state, range rbs_range) {
  range generic_range = state->next_token.range;
  parser_advance_assert(state, kGENERIC);

  range ranges[8];
  VALUE values[5];

  parse_type_param(state, true, true, ranges, values);
  VALUE comment = parse_inline_comment(state);

  range annotation_range = {
    .start = rbs_range.start,
    .end = state->current_token.range.end
  };
  range unchecked_range = ranges[1];
  range variance_range = ranges[2];
  range name_range = ranges[3];
  range upper_bound_operator_range = ranges[4];
  range default_type_operator_range = ranges[6];

  VALUE upper_bound = values[3];
  VALUE default_type = values[4];

  return rbs_ast_ruby_annotation_generic_annotation(
    rbs_new_location(state->buffer, annotation_range),
    rbs_new_location(state->buffer, rbs_range),
    rbs_new_location(state->buffer, generic_range),
    null_range_p(unchecked_range) ? Qnil : rbs_new_location(state->buffer, unchecked_range),
    null_range_p(variance_range) ? Qnil : rbs_new_location(state->buffer, variance_range),
    rbs_new_location(state->buffer, name_range),
    null_range_p(upper_bound_operator_range) ? Qnil : rbs_new_location(state->buffer, upper_bound_operator_range),
    upper_bound,
    null_range_p(default_type_operator_range) ? Qnil : rbs_new_location(state->buffer, default_type_operator_range),
    default_type,
    comment
  );
}

VALUE parse_inline_annotation(parserstate *state) {
  switch (state->next_token.type) {
    case kATRBS: {
      // @rbs
      range rbs_range = state->next_token.range;
      parser_advance(state);

      switch (state->next_token.type) {
        case tLIDENT:
        KEYWORD_CASES {
          if (state->next_token.type == kSKIP && state->next_token2.type != pCOLON) {
            return parse_inline_skip_annotation(state, rbs_range);
          }
          if (state->next_token.type == kRETURN && state->next_token2.type == pCOLON) {
            return parse_inline_return_type_annotation(state, rbs_range);
          }
          if (state->next_token.type == kOVERRIDE && state->next_token2.type != pCOLON) {
            return parse_override_annotation(state, rbs_range);
          }
          if (state->next_token.type == kGENERIC && state->next_token2.type != pCOLON) {
            return parse_generic_annotation(state, rbs_range);
          }

          // @rbs x: type

          range param_name_range = state->next_token.range;
          parser_advance(state);

          range colon_range = state->next_token.range;
          parser_advance_assert(state, pCOLON);

          VALUE type = parse_type(state);
          VALUE comment = parse_inline_comment(state);

          return rbs_ast_ruby_annotation_param_type_annotation(
            rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
            rbs_new_location(state->buffer, rbs_range),
            rbs_new_location(state->buffer, param_name_range),
            rbs_new_location(state->buffer, colon_range),
            type,
            comment
          );
        }
        case pSTAR: {
          // @rbs *args: String
          range operator_range = state->next_token.range;
          parser_advance(state);

          range param_name_range = NULL_RANGE;
          if (state->next_token.type != pCOLON) {
            param_name_range = state->next_token.range;
            parser_advance(state);
          }

          range colon_range = state->next_token.range;
          parser_advance_assert(state, pCOLON);

          VALUE type = parse_type(state);
          VALUE comment = parse_inline_comment(state);

          return rbs_ast_ruby_annotation_splat_param_type_annotation(
            rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
            rbs_new_location(state->buffer, rbs_range),
            rbs_new_location(state->buffer, operator_range),
            null_range_p(param_name_range) ? Qnil : rbs_new_location(state->buffer, param_name_range),
            rbs_new_location(state->buffer, colon_range),
            type,
            comment
          );
        }
        case pSTAR2: {
          // @rbs **args: String
          range operator_range = state->next_token.range;
          parser_advance(state);

          range param_name_range = NULL_RANGE;
          if (state->next_token.type != pCOLON) {
            param_name_range = state->next_token.range;
            parser_advance(state);
          }

          range colon_range = state->next_token.range;
          parser_advance_assert(state, pCOLON);

          VALUE type = parse_type(state);
          VALUE comment = parse_inline_comment(state);

          return rbs_ast_ruby_annotation_double_splat_param_type_annotation(
            rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
            rbs_new_location(state->buffer, rbs_range),
            rbs_new_location(state->buffer, operator_range),
            null_range_p(param_name_range) ? Qnil : rbs_new_location(state->buffer, param_name_range),
            rbs_new_location(state->buffer, colon_range),
            type,
            comment
          );
        }
        case pAMP: {
          // @rbs &block: type
          return parse_inline_block_param_type_annotation(state, rbs_range);
        }
        case tANNOTATION: {
          // @rbs %a{foo}

          position annot_pos = NullPosition;

          VALUE annotations = EMPTY_ARRAY;
          parse_annotations(state, &annotations, &annot_pos);

          if (state->next_token.type == pEOF) {
            return rbs_ast_ruby_annotation_rbs_annotation_annotation(
              rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
              rbs_new_location(state->buffer, rbs_range),
              annotations
            );
          } else {
            VALUE method_type = parse_method_type(state);

            VALUE overloads = rb_ary_new();
            VALUE bar_locations = rb_ary_new();
            rb_ary_push(overloads, rbs_ast_ruby_annotation_method_types_annotation_overload(annotations, method_type));

            if (state->next_token.type == pBAR) {
              rb_ary_push(bar_locations, rbs_new_location(state->buffer, state->next_token.range));

              while (true) {
                VALUE overload = parse_annotated_method_type(state);
                rb_ary_push(overloads, overload);

                if (state->next_token.type == pBAR) {
                  rb_ary_push(bar_locations, rbs_new_location(state->buffer, state->next_token.range));
                  parser_advance(state);
                } else {
                  break;
                }
              }
            }

            position end_pos = state->current_token.range.end;

            return rbs_ast_ruby_annotation_method_types_annotation(
              rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = end_pos }),
              rbs_new_location(state->buffer, rbs_range),
              overloads,
              bar_locations
            );
          }
        }
        case kMODULESELF: {
          // @rbs module-self TypeName `[` args `]` -- comment

          parser_advance_assert(state, kMODULESELF);

          range module_self_range = state->current_token.range;

          VALUE type_name;
          VALUE type_args = EMPTY_ARRAY;
          range ranges[4];

          parse_module_self(state, &type_name, &type_args, ranges);

          range module_name_range = ranges[0];
          range open_paren_range = ranges[1];
          range close_paren_range = ranges[3];

          VALUE comment = parse_inline_comment(state);

          return rbs_ast_ruby_annotation_module_self_annotation(
            rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = state->current_token.range.end }),
            rbs_new_location(state->buffer, rbs_range),
            rbs_new_location(state->buffer, module_self_range),
            type_name,
            rbs_new_location(state->buffer, module_name_range),
            null_range_p(open_paren_range) ? Qnil : rbs_new_location(state->buffer, open_paren_range),
            type_args,
            null_range_p(close_paren_range) ? Qnil : rbs_new_location(state->buffer, close_paren_range),
            comment
          );
        }
        default: {
          VALUE overloads = rb_ary_new();
          VALUE bar_locations = rb_ary_new();

          while (true) {
            VALUE overload = parse_annotated_method_type(state);
            rb_ary_push(overloads, overload);

            if (state->next_token.type == pBAR) {
              rb_ary_push(bar_locations, rbs_new_location(state->buffer, state->next_token.range));
              parser_advance(state);
            } else {
              break;
            }
          }

          position end_pos = state->current_token.range.end;

          return rbs_ast_ruby_annotation_method_types_annotation(
            rbs_new_location(state->buffer, (range) { .start = rbs_range.start, .end = end_pos }),
            rbs_new_location(state->buffer, rbs_range),
            overloads,
            bar_locations
          );
        }
      }
    }
    case kATRBSB: {
      // @rbs!
    }
    case pCOLON: {
      // :
      range colon_range = state->next_token.range;
      parser_advance(state);

      VALUE annotations = EMPTY_ARRAY;
      position annot_pos = NullPosition;

      if (state->next_token.type == tANNOTATION) {
        parse_annotations(state, &annotations, &annot_pos);
      }

      switch (state->next_token.type) {
        case pLPAREN:
        case pLBRACKET:
        case pLBRACE:
        case tANNOTATION: {
          VALUE method_type = parse_method_type(state);

          range location_range = {
            .start = colon_range.start,
            .end = state->current_token.range.end
          };

          return rbs_ast_ruby_annotation_colon_method_type_annotation(
            rbs_new_location(state->buffer, location_range),
            rbs_new_location(state->buffer, colon_range),
            annotations,
            method_type
          );
          default: {
            raise_syntax_error(
              state,
              state->next_token,
              "unexpected token for method type annotation"
            );
          }
        }
      }
    }
  }
}

static VALUE parse_inline_assertion(parserstate *state) {
  range prefix_range = state->next_token.range;

  switch (state->next_token.type) {
    case pCOLON: {
      parser_advance(state);

      VALUE type = parse_type(state);

      return rbs_ast_ruby_annotation_node_type_assertion(
        rbs_new_location(state->buffer, (range) { .start = prefix_range.start, .end = state->current_token.range.end }),
        rbs_new_location(state->buffer, prefix_range),
        type
      );
    }
    case pLBRACKET: {
      parser_advance_assert(state, pLBRACKET);

      VALUE types = rb_ary_new();
      parse_type_list(state, pRBRACKET, &types);

      parser_advance_assert(state, pRBRACKET);

      return rbs_ast_ruby_annotation_node_application(
        rbs_new_location(state->buffer, (range) { .start = prefix_range.start, .end = state->current_token.range.end }),
        rbs_new_location(state->buffer, prefix_range),
        types,
        rbs_new_location(state->buffer, state->current_token.range)
      );
    }
    default: {
      raise_syntax_error(
        state,
        state->next_token,
        "unexpected token for inline assertion"
      );
    }
  }
}

struct parse_type_arg {
  parserstate *parser;
  VALUE require_eof;
};

static VALUE
ensure_free_parser(VALUE parser) {
  free_parser((parserstate *)parser);
  return Qnil;
}

static VALUE
parse_type_try(VALUE a) {
  struct parse_type_arg *arg = (struct parse_type_arg *)a;

  if (arg->parser->next_token.type == pEOF) {
    return Qnil;
  }

  VALUE type = parse_type(arg->parser);

  if (RB_TEST(arg->require_eof)) {
    parser_advance_assert(arg->parser, pEOF);
  }

  return type;
}

static VALUE
rbsparser_parse_type(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos, VALUE variables, VALUE require_eof)
{
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  lexstate *lexer = alloc_lexer(string, FIX2INT(start_pos), FIX2INT(end_pos));
  parserstate *parser = alloc_parser(buffer, lexer, FIX2INT(start_pos), FIX2INT(end_pos), variables);
  struct parse_type_arg arg = {
    parser,
    require_eof
  };
  return rb_ensure(parse_type_try, (VALUE)&arg, ensure_free_parser, (VALUE)parser);
}

static VALUE
parse_method_type_try(VALUE a) {
  struct parse_type_arg *arg = (struct parse_type_arg *)a;

  if (arg->parser->next_token.type == pEOF) {
    return Qnil;
  }

  VALUE method_type = parse_method_type(arg->parser);

  if (RB_TEST(arg->require_eof)) {
    parser_advance_assert(arg->parser, pEOF);
  }

  return method_type;
}

static VALUE
rbsparser_parse_method_type(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos, VALUE variables, VALUE require_eof)
{
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  lexstate *lexer = alloc_lexer(string, FIX2INT(start_pos), FIX2INT(end_pos));
  parserstate *parser = alloc_parser(buffer, lexer, FIX2INT(start_pos), FIX2INT(end_pos), variables);
  struct parse_type_arg arg = {
    parser,
    require_eof
  };
  return rb_ensure(parse_method_type_try, (VALUE)&arg, ensure_free_parser, (VALUE)parser);
}

static VALUE
parse_signature_try(VALUE a) {
  parserstate *parser = (parserstate *)a;
  return parse_signature(parser);
}

static VALUE
rbsparser_parse_signature(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos)
{
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  lexstate *lexer = alloc_lexer(string, FIX2INT(start_pos), FIX2INT(end_pos));
  parserstate *parser = alloc_parser(buffer, lexer, FIX2INT(start_pos), FIX2INT(end_pos), Qnil);
  return rb_ensure(parse_signature_try, (VALUE)parser, ensure_free_parser, (VALUE)parser);
}

static VALUE parse_inline_try(VALUE a) {
  parserstate *parser = (parserstate *)a;
  return parse_inline_annotation(parser);
}

static VALUE
rbsparser_parse_inline(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos, VALUE variables)
{
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  lexstate *lexer = alloc_lexer(string, FIX2INT(start_pos), FIX2INT(end_pos));
  parserstate *parser = alloc_parser(buffer, lexer, FIX2INT(start_pos), FIX2INT(end_pos), variables);
  return rb_ensure(parse_inline_try, (VALUE)parser, ensure_free_parser, (VALUE)parser);
}

static VALUE parse_inline_assertion_try(VALUE a) {
  parserstate *parser = (parserstate *)a;
  return parse_inline_assertion(parser);
}

static VALUE rbsparser_parse_inline_assertion(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos, VALUE variables) {
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  lexstate *lexer = alloc_lexer(string, FIX2INT(start_pos), FIX2INT(end_pos));
  parserstate *parser = alloc_parser(buffer, lexer, FIX2INT(start_pos), FIX2INT(end_pos), variables);
  return rb_ensure(parse_inline_assertion_try, (VALUE)parser, ensure_free_parser, (VALUE)parser);
}

static VALUE
rbsparser_lex(VALUE self, VALUE buffer, VALUE end_pos) {
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  lexstate *lexer = alloc_lexer(string, 0, FIX2INT(end_pos));
  VALUE results = rb_ary_new();

  token token = NullToken;
  while (token.type != pEOF) {
    token = rbsparser_next_token(lexer);
    VALUE type = ID2SYM(rb_intern(token_type_str(token.type)));
    VALUE location = rbs_new_location(buffer, token.range);
    VALUE pair = rb_ary_new3(2, type, location);
    rb_ary_push(results, pair);
  }

  free(lexer);

  return results;
}

void rbs__init_parser(void) {
  RBS_Parser = rb_define_class_under(RBS, "Parser", rb_cObject);
  rb_gc_register_mark_object(RBS_Parser);

  VALUE empty_array = rb_obj_freeze(rb_ary_new());
  rb_gc_register_mark_object(empty_array);
  EMPTY_ARRAY = empty_array;

  VALUE empty_hash = rb_obj_freeze(rb_hash_new());
  rb_gc_register_mark_object(empty_hash);
  EMPTY_HASH = empty_hash;

  rb_define_singleton_method(RBS_Parser, "_parse_type", rbsparser_parse_type, 5);
  rb_define_singleton_method(RBS_Parser, "_parse_method_type", rbsparser_parse_method_type, 5);
  rb_define_singleton_method(RBS_Parser, "_parse_signature", rbsparser_parse_signature, 3);
  rb_define_singleton_method(RBS_Parser, "_parse_inline", rbsparser_parse_inline, 4);
  rb_define_singleton_method(RBS_Parser, "_parse_inline_assertion", rbsparser_parse_inline_assertion, 4);
  rb_define_singleton_method(RBS_Parser, "_lex", rbsparser_lex, 2);
}
