#include "location.h"
#include "rbs_extension.h"
#include "rbs/util/rbs_constant_pool.h"
#include "rbs/ast.h"
#include "rbs/rbs_string.h"
#include "ast_translation.h"
#include "rbs/rbs_unescape.h"
#include "rbs_string_bridging.h"

#define INTERN(str)                  \
  rbs_constant_pool_insert_constant( \
    RBS_GLOBAL_CONSTANT_POOL,        \
    (const uint8_t *) str,           \
    strlen(str)                      \
  )

#define INTERN_TOKEN(parserstate, tok)                       \
  rbs_constant_pool_insert_shared_with_encoding(             \
    &parserstate->constant_pool,                             \
    (const uint8_t *) peek_token(parserstate->lexstate, tok),\
    token_bytes(tok),                                        \
    (void *) rb_enc_get(parserstate->lexstate->string)       \
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
  /* nop */

typedef struct {
  rbs_node_list_t *required_positionals;
  rbs_node_list_t *optional_positionals;
  rbs_node_t *rest_positionals;
  rbs_node_list_t *trailing_positionals;
  rbs_hash_t *required_keywords;
  rbs_hash_t *optional_keywords;
  rbs_node_t *rest_keywords;
} method_params;

static bool rbs_is_untyped_params(method_params *params) {
  return params->required_positionals == NULL;
}

// /**
//  * Returns RBS::Location object of `current_token` of a parser state.
//  *
//  * @param state
//  * @return New RBS::Location object.
//  * */
static rbs_location_t *rbs_location_current_token(parserstate *state) {
  return rbs_location_pp(
    state->buffer,
    &state->current_token.range.start,
    &state->current_token.range.end
  );
}

static rbs_node_t *parse_optional(parserstate *state);
static rbs_node_t *parse_simple(parserstate *state);

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
static rbs_typename_t *parse_type_name(parserstate *state, TypeNameKind kind, range *rg) {
  bool absolute = false;

  if (rg) {
    rg->start = state->current_token.range.start;
  }

  if (state->current_token.type == pCOLON2) {
    absolute = true;
    parser_advance_no_gap(state);
  }

  rbs_node_list_t *path = rbs_node_list_new(&state->allocator);

  while (
    state->current_token.type == tUIDENT
    && state->next_token.type == pCOLON2
    && state->current_token.range.end.byte_pos == state->next_token.range.start.byte_pos
    && state->next_token.range.end.byte_pos == state->next_token2.range.start.byte_pos
  ) {
    rbs_constant_id_t symbol_value = INTERN_TOKEN(state, state->current_token);
    rbs_ast_symbol_t *symbol = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, symbol_value);
    rbs_node_list_append(path, (rbs_node_t *)symbol);

    parser_advance(state);
    parser_advance(state);
  }

  rbs_namespace_t *namespace = rbs_namespace_new(&state->allocator, path, absolute);

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

    rbs_constant_id_t name = INTERN_TOKEN(state, state->current_token);
    rbs_ast_symbol_t *symbol = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, name);
    return rbs_typename_new(&state->allocator, namespace, symbol);
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
static void parse_type_list(parserstate *state, enum TokenType eol, rbs_node_list_t *types) {
  while (true) {
    rbs_node_t *type = parse_type(state);
    rbs_node_list_append(types, type);

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
static rbs_types_function_param_t *parse_function_param(parserstate *state) {
  range type_range;
  type_range.start = state->next_token.range.start;
  rbs_node_t *type = parse_type(state);
  type_range.end = state->current_token.range.end;

  if (state->next_token.type == pCOMMA || state->next_token.type == pRPAREN) {
    range param_range = type_range;

    rbs_location_t *loc = rbs_location_new(state->buffer, param_range);
    rbs_loc_alloc_children(loc, 1);
    rbs_loc_add_optional_child(loc, INTERN("name"), NULL_RANGE);

    return rbs_types_function_param_new(&state->allocator, type, NULL, loc);
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

    VALUE name_str = rbs_unquote_string(state, state->current_token.range, 0);
    rbs_constant_id_t constant_id = rbs_constant_pool_insert_shared(
      &state->constant_pool,
      (const uint8_t *) RSTRING_PTR(name_str),
      RSTRING_LEN(name_str)
    );
    rbs_ast_symbol_t *name = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, constant_id);

    rbs_location_t *loc = rbs_location_new(state->buffer, param_range);
    rbs_loc_alloc_children(loc, 1);
    rbs_loc_add_optional_child(loc, INTERN("name"), name_range);

    return rbs_types_function_param_new(&state->allocator, type, name, loc);
  }
}

static rbs_constant_id_t intern_token_start_end(parserstate *state, token start_token, token end_token) {
  return rbs_constant_pool_insert_shared_with_encoding(
    &state->constant_pool,
    (const uint8_t *) peek_token(state->lexstate, start_token),
    end_token.range.end.byte_pos - start_token.range.start.byte_pos,
    (void *) rb_enc_get(state->lexstate->string)
  );
}

/*
  keyword_key ::= {} <keyword> `:`
                | {} keyword <`?`> `:`
*/
static rbs_ast_symbol_t *parse_keyword_key(parserstate *state) {
  parser_advance(state);
  if (state->next_token.type == pQUESTION) {
    rbs_ast_symbol_t *key = rbs_ast_symbol_new(
      &state->allocator,
      &state->constant_pool,
      intern_token_start_end(state, state->current_token, state->next_token)
    );
    parser_advance(state);
    return key;
  } else {
    return rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));
  }
}

/*
  keyword ::= {} keyword `:` <function_param>
*/
static void parse_keyword(parserstate *state, rbs_hash_t *keywords, rbs_hash_t *memo) {
  rbs_ast_symbol_t *key = parse_keyword_key(state);

  if (rbs_hash_find(memo, (rbs_node_t *) key)) {
    raise_syntax_error(
      state,
      state->current_token,
      "duplicated keyword argument"
    );
  } else {
    rbs_hash_set(memo, (rbs_node_t *) key, (rbs_node_t *) rbs_ast_bool_new(&state->allocator, true));
  }

  parser_advance_assert(state, pCOLON);
  rbs_types_function_param_t *param = parse_function_param(state);

  rbs_hash_set(keywords, (rbs_node_t *) key, (rbs_node_t *) param);

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
    params->required_positionals = NULL;
    parser_advance(state);
    return;
  }
  if (state->next_token.type == pRPAREN) {
    return;
  }

  rbs_hash_t *memo = rbs_hash_new(&state->allocator);

  while (true) {
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

        rbs_types_function_param_t *param = parse_function_param(state);
        rbs_node_list_append(params->required_positionals, (rbs_node_t *)param);

        break;
    }

    if (!parser_advance_if(state, pCOMMA)) {
      goto EOP;
    }
  }

PARSE_OPTIONAL_PARAMS:
  while (true) {
    switch (state->next_token.type) {
      case pQUESTION:
        parser_advance(state);

        if (is_keyword(state)) {
          parse_keyword(state, params->optional_keywords, memo);
          parser_advance_if(state, pCOMMA);
          goto PARSE_KEYWORDS;
        }

        rbs_types_function_param_t *param = parse_function_param(state);
        rbs_node_list_append(params->optional_positionals, (rbs_node_t *)param);

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
    rbs_types_function_param_t *param = parse_function_param(state);
    params->rest_positionals = (rbs_node_t *) param;

    if (!parser_advance_if(state, pCOMMA)) {
      goto EOP;
    }
  }
  goto PARSE_TRAILING_PARAMS;

PARSE_TRAILING_PARAMS:
  while (true) {
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

        rbs_types_function_param_t *param = parse_function_param(state);
        rbs_node_list_append(params->trailing_positionals, (rbs_node_t *)param);

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
        parse_keyword(state, params->optional_keywords, memo);
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
      rbs_types_function_param_t *param = parse_function_param(state);
      params->rest_keywords = (rbs_node_t *) param;
      break;

    case tUIDENT:
    case tLIDENT:
    case tQIDENT:
    case tULIDENT:
    case tULLIDENT:
    case tBANGIDENT:
    KEYWORD_CASES
      if (is_keyword(state)) {
        parse_keyword(state, params->required_keywords, memo);
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
static rbs_node_t *parse_optional(parserstate *state) {
  range rg;
  rg.start = state->next_token.range.start;
  rbs_node_t *type = parse_simple(state);

  if (state->next_token.type == pQUESTION) {
    parser_advance(state);
    rg.end = state->current_token.range.end;
    rbs_location_t *location = rbs_location_new(state->buffer, rg);
    return (rbs_node_t *) rbs_types_optional_new(&state->allocator, type, location);
  } else {
    return type;
  }
}

static void initialize_method_params(method_params *params, rbs_allocator_t *allocator) {
  *params = (method_params) {
    .required_positionals = rbs_node_list_new(allocator),
    .optional_positionals = rbs_node_list_new(allocator),
    .rest_positionals = NULL,
    .trailing_positionals = rbs_node_list_new(allocator),
    .required_keywords = rbs_hash_new(allocator),
    .optional_keywords = rbs_hash_new(allocator),
    .rest_keywords = NULL,
  };
}

/*
  self_type_binding ::= {} <>
                      | {} `[` `self` `:` type <`]`>
*/
static rbs_node_t *parse_self_type_binding(parserstate *state) {
  if (state->next_token.type == pLBRACKET) {
    parser_advance(state);
    parser_advance_assert(state, kSELF);
    parser_advance_assert(state, pCOLON);
    rbs_node_t *type = parse_type(state);
    parser_advance_assert(state, pRBRACKET);
    return type;
  } else {
    return NULL;
  }
}

typedef struct {
  rbs_node_t *function;
  rbs_types_block_t *block;
  rbs_node_t *function_self_type;
} parse_function_result;

/*
  function ::= {} `(` params `)` self_type_binding? `{` `(` params `)` self_type_binding? `->` optional `}` `->` <optional>
             | {} `(` params `)` self_type_binding? `->` <optional>
             | {} self_type_binding? `{` `(` params `)` self_type_binding? `->` optional `}` `->` <optional>
             | {} self_type_binding? `{` self_type_binding `->` optional `}` `->` <optional>
             | {} self_type_binding? `->` <optional>
*/
static parse_function_result parse_function(parserstate *state, bool accept_type_binding) {
  rbs_node_t *function = NULL;
  rbs_types_block_t *block = NULL;
  rbs_node_t *function_self_type = NULL;
  method_params params;
  initialize_method_params(&params, &state->allocator);

  if (state->next_token.type == pLPAREN) {
    parser_advance(state);
    parse_params(state, &params);
    parser_advance_assert(state, pRPAREN);
  }

  // Untyped method parameter means it cannot have block
  if (rbs_is_untyped_params(&params)) {
    if (state->next_token.type != pARROW) {
      raise_syntax_error(state, state->next_token2, "A method type with untyped method parameter cannot have block");
    }
  }

  // Passing NULL to function_self_type means the function itself doesn't accept self type binding. (== method type)
  if (accept_type_binding) {
    function_self_type = parse_self_type_binding(state);
  }

  bool required = true;
  if (state->next_token.type == pQUESTION && state->next_token2.type == pLBRACE) {
    // Optional block
    required = false;
    parser_advance(state);
  }
  if (state->next_token.type == pLBRACE) {
    parser_advance(state);

    method_params block_params;
    initialize_method_params(&block_params, &state->allocator);

    if (state->next_token.type == pLPAREN) {
      parser_advance(state);
      parse_params(state, &block_params);
      parser_advance_assert(state, pRPAREN);
    }

    rbs_node_t *self_type = parse_self_type_binding(state);

    parser_advance_assert(state, pARROW);
    rbs_node_t *block_return_type = parse_optional(state);

    rbs_node_t *block_function = NULL;
    if (rbs_is_untyped_params(&block_params)) {
      block_function = (rbs_node_t *) rbs_types_untypedfunction_new(&state->allocator, block_return_type);
    } else {
      block_function = (rbs_node_t *) rbs_types_function_new(
        &state->allocator,
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

    block = rbs_types_block_new(&state->allocator, block_function, required, self_type);

    parser_advance_assert(state, pRBRACE);
  }

  parser_advance_assert(state, pARROW);
  rbs_node_t *type = parse_optional(state);

  if (rbs_is_untyped_params(&params)) {
    function = (rbs_node_t *) rbs_types_untypedfunction_new(&state->allocator, type);
  } else {
    function = (rbs_node_t *) rbs_types_function_new(
      &state->allocator,
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

  parse_function_result result;
  result.function = function;
  result.block = block;
  result.function_self_type = function_self_type;
  return result;
}

/*
  proc_type ::= {`^`} <function>
*/
static rbs_types_proc_t *parse_proc_type(parserstate *state) {
  position start = state->current_token.range.start;
  parse_function_result result = parse_function(state, true);
  position end = state->current_token.range.end;
  rbs_location_t *loc = rbs_location_pp(state->buffer, &start, &end);
  return rbs_types_proc_new(&state->allocator, result.function, result.block, loc, result.function_self_type);
}

static void check_key_duplication(parserstate *state, rbs_hash_t *fields, rbs_node_t *key) {
  if (rbs_hash_find(fields, ((rbs_node_t *) key))) {
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
static rbs_hash_t *parse_record_attributes(parserstate *state) {
  rbs_hash_t *fields = rbs_hash_new(&state->allocator);

  if (state->next_token.type == pRBRACE) {
    return fields;
  }

  while (true) {
    rbs_node_t *key;
    bool required = true;

    if (state->next_token.type == pQUESTION) {
      // { ?foo: type } syntax
      required = false;
      parser_advance(state);
    }

    if (is_keyword(state)) {
      // { foo: type } syntax
      key = (rbs_node_t *) parse_keyword_key(state);
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
        key = (rbs_node_t *) ((rbs_types_literal_t *) parse_simple(state))->literal;
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
    rbs_node_t *type = parse_type(state);
    rbs_hash_set(fields, (rbs_node_t *) key, (rbs_node_t *) rbs_types_record_fieldtype_new(&state->allocator, type, required));

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
static rbs_types_literal_t *parse_symbol(parserstate *state, rbs_location_t *location) {
  VALUE string = state->lexstate->string;
  rb_encoding *enc = rb_enc_get(string);

  int offset_bytes = rb_enc_codelen(':', enc);
  int bytes = token_bytes(state->current_token) - offset_bytes;

  rbs_ast_symbol_t *literal;

  switch (state->current_token.type)
  {
  case tSYMBOL: {
    char *buffer = peek_token(state->lexstate, state->current_token);
    rbs_constant_id_t constant_id = rbs_constant_pool_insert_shared(
      &state->constant_pool,
      (const uint8_t *) buffer+offset_bytes,
      bytes
    );
    literal = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, constant_id);
    break;
  }
  case tDQSYMBOL:
  case tSQSYMBOL: {
    VALUE ruby_str = rbs_unquote_string(state, state->current_token.range, offset_bytes);
    rbs_constant_id_t constant_id = rbs_constant_pool_insert_shared(
      &state->constant_pool,
      (const uint8_t *) RSTRING_PTR(ruby_str),
      RSTRING_LEN(ruby_str)
    );
    literal = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, constant_id);
    break;
  }
  default:
    state->aborted = true;
    return NULL;
  }

  return rbs_types_literal_new(&state->allocator, (rbs_node_t *) literal, location);
}

/*
 instance_type ::= {type_name} <type_args>

 type_args ::= {} <> /empty/
             | {} `[` type_list <`]`>
 */
static rbs_node_t *parse_instance_type(parserstate *state, bool parse_alias) {
    TypeNameKind expected_kind = INTERFACE_NAME | CLASS_NAME;
    if (parse_alias) {
      expected_kind |= ALIAS_NAME;
    }

    range name_range;
    rbs_typename_t *typename = parse_type_name(state, expected_kind, &name_range);
    rbs_node_list_t *types = rbs_node_list_new(&state->allocator);

    TypeNameKind kind;
    if (state->current_token.type == tUIDENT) {
      kind = CLASS_NAME;
    } else if (state->current_token.type == tULIDENT) {
      kind = INTERFACE_NAME;
    } else if (state->current_token.type == tLIDENT) {
      kind = ALIAS_NAME;
    } else {
      state->aborted = true;
      return NULL;
    }

    range args_range;
    if (state->next_token.type == pLBRACKET) {
      parser_advance(state);
      args_range.start = state->current_token.range.start;
      parse_type_list(state, pRBRACKET, types);
      parser_advance_assert(state, pRBRACKET);
      args_range.end = state->current_token.range.end;
    } else {
      args_range = NULL_RANGE;
    }

    range type_range = {
      .start = name_range.start,
      .end = nonnull_pos_or(args_range.end, name_range.end),
    };

    rbs_location_t *loc = rbs_location_new(state->buffer, type_range);
    rbs_loc_alloc_children(loc, 2);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_optional_child(loc, INTERN("args"), args_range);

    if (kind == CLASS_NAME) {
      return (rbs_node_t *) rbs_types_classinstance_new(&state->allocator, typename, types, loc);
    } else if (kind == INTERFACE_NAME) {
      return (rbs_node_t *) rbs_types_interface_new(&state->allocator, typename, types, loc);
    } else if (kind == ALIAS_NAME) {
      return (rbs_node_t *) rbs_types_alias_new(&state->allocator, typename, types, loc);
    } else {
      return NULL;
    }
}

/*
  singleton_type ::= {`singleton`} `(` type_name <`)`>
*/
static rbs_types_classsingleton_t *parse_singleton_type(parserstate *state) {
  parser_assert(state, kSINGLETON);

  range type_range;
  type_range.start = state->current_token.range.start;
  parser_advance_assert(state, pLPAREN);
  parser_advance(state);

  range name_range;
  rbs_typename_t *typename = parse_type_name(state, CLASS_NAME, &name_range);

  parser_advance_assert(state, pRPAREN);
  type_range.end = state->current_token.range.end;

  rbs_location_t *loc = rbs_location_new(state->buffer, type_range);
  rbs_loc_alloc_children(loc, 1);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);

  return rbs_types_classsingleton_new(&state->allocator, typename, loc);
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
static rbs_node_t *parse_simple(parserstate *state) {
  parser_advance(state);

  switch (state->current_token.type) {
  case pLPAREN: {
    rbs_node_t *type = parse_type(state);
    parser_advance_assert(state, pRPAREN);
    return type;
  }
  case kBOOL: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_bool_new(&state->allocator, loc);
  }
  case kBOT: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_bottom_new(&state->allocator, loc);
  }
  case kCLASS: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_class_new(&state->allocator, loc);
  }
  case kINSTANCE: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_instance_new(&state->allocator, loc);
  }
  case kNIL: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_nil_new(&state->allocator, loc);
  }
  case kSELF: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_self_new(&state->allocator, loc);
  }
  case kTOP: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_top_new(&state->allocator, loc);
  }
  case kVOID: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_void_new(&state->allocator, loc);
  }
  case kUNTYPED: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_any_new(&state->allocator, false, loc);
  }
  case k__TODO__: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_bases_any_new(&state->allocator, true, loc);
  }
  case tINTEGER: {
    rbs_location_t *loc = rbs_location_current_token(state);

    rbs_string_t string = rbs_string_from_ruby_string(state->lexstate->string);
    rbs_string_drop_first(&string, state->current_token.range.start.byte_pos);
    rbs_string_limit_length(&string, state->current_token.range.end.byte_pos - state->current_token.range.start.byte_pos);
    rbs_string_strip_whitespace(&string);
    rbs_string_ensure_owned(&string);

    rbs_node_t *literal = (rbs_node_t *) rbs_ast_integer_new(&state->allocator, string);
    return (rbs_node_t *) rbs_types_literal_new(&state->allocator, literal, loc);
  }
  case kTRUE: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_literal_new(&state->allocator, (rbs_node_t *) rbs_ast_bool_new(&state->allocator, true), loc);
  }
  case kFALSE: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) rbs_types_literal_new(&state->allocator, (rbs_node_t *) rbs_ast_bool_new(&state->allocator, false), loc);
  }
  case tSQSTRING:
  case tDQSTRING: {
    rbs_location_t *loc = rbs_location_current_token(state);

    rbs_string_t string = rbs_string_from_ruby_string(state->lexstate->string);
    rbs_string_drop_first(&string, state->current_token.range.start.byte_pos);
    rbs_string_limit_length(&string, state->current_token.range.end.byte_pos - state->current_token.range.start.byte_pos);
    rbs_string_ensure_owned(&string);

    rbs_string_t unquoted_str = rbs_unquote_string2(string);
    rbs_string_ensure_owned(&unquoted_str);

    rbs_node_t *literal = (rbs_node_t *) rbs_ast_string_new(&state->allocator, unquoted_str);
    return (rbs_node_t *) rbs_types_literal_new(&state->allocator, literal, loc);
  }
  case tSYMBOL:
  case tSQSYMBOL:
  case tDQSYMBOL: {
    rbs_location_t *loc = rbs_location_current_token(state);
    return (rbs_node_t *) parse_symbol(state, loc);
  }
  case tUIDENT: {
    const char *name_str = peek_token(state->lexstate, state->current_token);
    size_t name_len = token_bytes(state->current_token);

    rbs_constant_id_t name = rbs_constant_pool_find(&state->constant_pool, (const uint8_t *) name_str, name_len);

    if (parser_typevar_member(state, name)) {
      rbs_location_t *loc = rbs_location_current_token(state);
      rbs_ast_symbol_t *symbol = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, name);
      return (rbs_node_t *) rbs_types_variable_new(&state->allocator, symbol, loc);
    }
    // fallthrough for type name
  }
  case tULIDENT: // fallthrough
  case tLIDENT: // fallthrough
  case pCOLON2: {
    return parse_instance_type(state, true);
  }
  case kSINGLETON: {
    return (rbs_node_t *) parse_singleton_type(state);
  }
  case pLBRACKET: {
    range rg;
    rg.start = state->current_token.range.start;
    rbs_node_list_t *types = rbs_node_list_new(&state->allocator);
    if (state->next_token.type != pRBRACKET) {
      parse_type_list(state, pRBRACKET, types);
    }
    parser_advance_assert(state, pRBRACKET);
    rg.end = state->current_token.range.end;

    rbs_location_t *loc = rbs_location_new(state->buffer, rg);
    return (rbs_node_t *) rbs_types_tuple_new(&state->allocator, types, loc);
  }
  case pAREF_OPR: {
    rbs_location_t *loc = rbs_location_current_token(state);
    rbs_node_list_t *types = rbs_node_list_new(&state->allocator);
    return (rbs_node_t *) rbs_types_tuple_new(&state->allocator, types, loc);
  }
  case pLBRACE: {
    position start = state->current_token.range.start;
    rbs_hash_t *fields = parse_record_attributes(state);
    parser_advance_assert(state, pRBRACE);
    position end = state->current_token.range.end;
    rbs_location_t *loc = rbs_location_pp(state->buffer, &start, &end);
    return (rbs_node_t *) rbs_types_record_new(&state->allocator, fields, loc);
  }
  case pHAT: {
    rbs_types_proc_t *value = parse_proc_type(state);
    return (rbs_node_t *) value;
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
static rbs_node_t *parse_intersection(parserstate *state) {
  range rg;
  rg.start = state->next_token.range.start;
  rbs_node_t *type = parse_optional(state);
  rbs_node_list_t *intersection_types = rbs_node_list_new(&state->allocator);

  rbs_node_list_append(intersection_types, type);
  while (state->next_token.type == pAMP) {
    parser_advance(state);
    rbs_node_list_append(intersection_types, parse_optional(state));
  }

  rg.end = state->current_token.range.end;

  if (intersection_types->length > 1) {
    rbs_location_t *location = rbs_location_new(state->buffer, rg);
    type = (rbs_node_t *) rbs_types_intersection_new(&state->allocator, intersection_types, location);
  }

  return type;
}

/*
  union ::= {} intersection '|' ... '|' <intersection>
          | {} <intersection>
*/
rbs_node_t *parse_type(parserstate *state) {
  range rg;
  rg.start = state->next_token.range.start;

  rbs_node_t *type = parse_intersection(state);
  rbs_node_list_t *union_types = rbs_node_list_new(&state->allocator);

  rbs_node_list_append(union_types, type);
  while (state->next_token.type == pBAR) {
    parser_advance(state);
    rbs_node_list_append(union_types, parse_intersection(state));
  }

  rg.end = state->current_token.range.end;

  if (union_types->length > 1) {
    rbs_location_t *location = rbs_location_new(state->buffer, rg);
    type = (rbs_node_t *) rbs_types_union_new(&state->allocator, union_types, location);
  }

  return type;
}

/*
  type_params ::= {} `[` type_param `,` ... <`]`>
                | {<>}

  type_param ::= kUNCHECKED? (kIN|kOUT|) tUIDENT upper_bound? default_type?   (module_type_params == true)

  type_param ::= tUIDENT upper_bound? default_type?                           (module_type_params == false)
*/
static rbs_node_list_t *parse_type_params(parserstate *state, range *rg, bool module_type_params) {
  rbs_node_list_t *params = rbs_node_list_new(&state->allocator);

  bool required_param_allowed = true;

  if (state->next_token.type == pLBRACKET) {
    parser_advance(state);

    rg->start = state->current_token.range.start;

    while (true) {
      bool unchecked = false;
      rbs_keyword_t *variance = rbs_keyword_new(&state->allocator, INTERN("invariant"));
      rbs_node_t *upper_bound = NULL;
      rbs_node_t *default_type = NULL;

      range param_range;
      param_range.start = state->next_token.range.start;

      range unchecked_range = NULL_RANGE;
      range variance_range = NULL_RANGE;
      if (module_type_params) {
        if (state->next_token.type == kUNCHECKED) {
          unchecked = Qtrue;
          parser_advance(state);
          unchecked_range = state->current_token.range;
        }

        if (state->next_token.type == kIN || state->next_token.type == kOUT) {
          switch (state->next_token.type) {
          case kIN:
            variance = rbs_keyword_new(&state->allocator, INTERN("contravariant"));
            break;
          case kOUT:
            variance = rbs_keyword_new(&state->allocator, INTERN("covariant"));
            break;
          default:
            state->aborted = true;
            return NULL;
          }

          parser_advance(state);
          variance_range = state->current_token.range;
        }
      }

      parser_advance_assert(state, tUIDENT);
      range name_range = state->current_token.range;

      rbs_constant_id_t id = rbs_constant_pool_insert_shared(
        &state->constant_pool,
        (const uint8_t *) peek_token(state->lexstate, state->current_token),
        token_bytes(state->current_token)
      );

      rbs_ast_symbol_t *name = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, id);

      parser_insert_typevar(state, id);

      range upper_bound_range = NULL_RANGE;
      if (state->next_token.type == pLT) {
        parser_advance(state);
        upper_bound_range.start = state->current_token.range.start;
        upper_bound = parse_type(state);
        upper_bound_range.end = state->current_token.range.end;
      }

      range default_type_range = NULL_RANGE;
      if (module_type_params) {
        if (state->next_token.type == pEQ) {
          parser_advance(state);

          default_type_range.start = state->current_token.range.start;
          default_type = parse_type(state);
          default_type_range.end = state->current_token.range.end;

          required_param_allowed = false;
        } else {
          if (!required_param_allowed) {
            raise_syntax_error(
              state,
              state->current_token,
              "required type parameter is not allowed after optional type parameter"
            );
          }
        }
      }

      param_range.end = state->current_token.range.end;

      rbs_location_t *loc = rbs_location_new(state->buffer, param_range);
      rbs_loc_alloc_children(loc, 5);
      rbs_loc_add_required_child(loc, INTERN("name"), name_range);
      rbs_loc_add_optional_child(loc, INTERN("variance"), variance_range);
      rbs_loc_add_optional_child(loc, INTERN("unchecked"), unchecked_range);
      rbs_loc_add_optional_child(loc, INTERN("upper_bound"), upper_bound_range);
      rbs_loc_add_optional_child(loc, INTERN("default"), default_type_range);

      rbs_ast_typeparam_t *param = rbs_ast_typeparam_new(&state->allocator, name, variance, upper_bound, default_type, unchecked, loc);

      rbs_node_list_append(params, (rbs_node_t *) param);

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

  return params;
}

/*
  method_type ::= {} type_params <function>
  */
rbs_methodtype_t *parse_method_type(parserstate *state) {
  parser_push_typevar_table(state, false);

  range rg;
  rg.start = state->next_token.range.start;

  range params_range = NULL_RANGE;
  rbs_node_list_t *type_params = parse_type_params(state, &params_range, false);

  range type_range;
  type_range.start = state->next_token.range.start;

  parse_function_result result = parse_function(state, false);

  rg.end = state->current_token.range.end;
  type_range.end = rg.end;

  parser_pop_typevar_table(state);

  rbs_location_t *loc = rbs_location_new(state->buffer, rg);
  rbs_loc_alloc_children(loc, 2);
  rbs_loc_add_required_child(loc, INTERN("type"), type_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), params_range);

  return rbs_methodtype_new(&state->allocator, type_params, result.function, result.block, loc);
}

/*
  global_decl ::= {tGIDENT} `:` <type>
*/
static rbs_ast_declarations_global_t *parse_global_decl(parserstate *state) {
  range decl_range;
  decl_range.start = state->current_token.range.start;

  rbs_ast_comment_t *comment = get_comment(state, decl_range.start.line);

  range name_range = state->current_token.range;
  rbs_ast_symbol_t *typename = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));

  parser_advance_assert(state, pCOLON);
  range colon_range = state->current_token.range;

  rbs_node_t *type = parse_type(state);
  decl_range.end = state->current_token.range.end;

  rbs_location_t *loc = rbs_location_new(state->buffer, decl_range);
  rbs_loc_alloc_children(loc, 2);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);

  return rbs_ast_declarations_global_new(&state->allocator, typename, type, loc, comment);
}

/*
  const_decl ::= {const_name} `:` <type>
*/
static rbs_ast_declarations_constant_t *parse_const_decl(parserstate *state) {
  range decl_range;

  decl_range.start = state->current_token.range.start;
  rbs_ast_comment_t *comment = get_comment(state, decl_range.start.line);

  range name_range;
  rbs_typename_t *typename = parse_type_name(state, CLASS_NAME, &name_range);

  parser_advance_assert(state, pCOLON);
  range colon_range = state->current_token.range;

  rbs_node_t *type = parse_type(state);
  decl_range.end = state->current_token.range.end;

  rbs_location_t *loc = rbs_location_new(state->buffer, decl_range);
  rbs_loc_alloc_children(loc, 2);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);

  return rbs_ast_declarations_constant_new(&state->allocator, typename, type, loc, comment);
}

/*
  type_decl ::= {kTYPE} alias_name `=` <type>
*/
static rbs_ast_declarations_typealias_t *parse_type_decl(parserstate *state, position comment_pos, rbs_node_list_t *annotations) {
  parser_push_typevar_table(state, true);

  range decl_range;
  decl_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, decl_range.start);

  range keyword_range = state->current_token.range;

  parser_advance(state);

  range name_range;
  rbs_typename_t *typename = parse_type_name(state, ALIAS_NAME, &name_range);

  range params_range;
  rbs_node_list_t *type_params = parse_type_params(state, &params_range, true);

  parser_advance_assert(state, pEQ);
  range eq_range = state->current_token.range;

  rbs_node_t *type = parse_type(state);
  decl_range.end = state->current_token.range.end;

  rbs_location_t *loc = rbs_location_new(state->buffer, decl_range);
  rbs_loc_alloc_children(loc, 4);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), params_range);
  rbs_loc_add_required_child(loc, INTERN("eq"), eq_range);

  parser_pop_typevar_table(state);

  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);
  return rbs_ast_declarations_typealias_new(&state->allocator, typename, type_params, type, annotations, loc, comment);
}

/*
  annotation ::= {<tANNOTATION>}
*/
static rbs_ast_annotation_t *parse_annotation(parserstate *state) {
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
    state->aborted = true;
    return NULL;
  }

  int open_bytes = rb_enc_codelen(open_char, enc);
  int close_bytes = rb_enc_codelen(close_char, enc);

  rbs_string_t string = rbs_string_from_ruby_string(state->lexstate->string);
  rbs_string_drop_first(&string, rg.start.byte_pos + offset_bytes + open_bytes);
  rbs_string_limit_length(&string, rg.end.byte_pos - rg.start.byte_pos - offset_bytes - open_bytes - close_bytes);
  rbs_string_strip_whitespace(&string);
  rbs_string_ensure_owned(&string);

  rbs_location_t *loc = rbs_location_new(state->buffer, rg);
  return rbs_ast_annotation_new(&state->allocator, string, loc);
}

/*
  annotations ::= {} annotation ... <annotation>
                | {<>}
*/
static void parse_annotations(parserstate *state, rbs_node_list_t *annotations, position *annot_pos) {
  *annot_pos = NullPosition;

  while (true) {
    if (state->next_token.type == tANNOTATION) {
      parser_advance(state);

      if (null_position_p((*annot_pos))) {
        *annot_pos = state->current_token.range.start;
      }

      rbs_node_list_append(annotations, (rbs_node_t *)parse_annotation(state));
    } else {
      break;
    }
  }
}

/*
  method_name ::= {} <IDENT | keyword>
                | {} (IDENT | keyword)~<`?`>
*/
static rbs_ast_symbol_t *parse_method_name(parserstate *state, range *range) {
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

      rbs_constant_id_t constant_id = rbs_constant_pool_insert_shared(
        &state->constant_pool,
        (const uint8_t *) RSTRING_PTR(state->lexstate->string) + range->start.byte_pos,
        range->end.byte_pos - range->start.byte_pos
        // rb_enc_get(state->lexstate->string) // FIXME: Add encoding back
      );

      return rbs_ast_symbol_new(&state->allocator, &state->constant_pool, constant_id);
    } else {
      *range = state->current_token.range;
      return rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));
    }

  case tBANGIDENT:
  case tEQIDENT: {
    *range = state->current_token.range;
    return rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));
  }
  case tQIDENT: {
    VALUE ruby_str = rbs_unquote_string(state, state->current_token.range, 0);
    rbs_constant_id_t constant_id = rbs_constant_pool_insert_shared(
      &state->constant_pool,
      (const uint8_t *) RSTRING_PTR(ruby_str),
      RSTRING_LEN(ruby_str)
    );
    return rbs_ast_symbol_new(&state->allocator, &state->constant_pool, constant_id);
  }

  case pBAR:
  case pHAT:
  case pAMP:
  case pSTAR:
  case pSTAR2:
  case pLT:
  case pAREF_OPR:
  case tOPERATOR: {
    *range = state->current_token.range;
    return rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));
  }

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
static rbs_ast_members_methoddefinition_t *parse_member_def(parserstate *state, bool instance_only, bool accept_overload, position comment_pos, rbs_node_list_t *annotations) {
  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);

  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);

  range visibility_range;
  rbs_keyword_t *visibility;
  switch (state->current_token.type)
  {
  case kPRIVATE: {
    visibility_range = state->current_token.range;
    visibility = rbs_keyword_new(&state->allocator, INTERN("private"));
    member_range.start = visibility_range.start;
    parser_advance(state);
    break;
  }
  case kPUBLIC: {
    visibility_range = state->current_token.range;
    visibility = rbs_keyword_new(&state->allocator, INTERN("public"));
    member_range.start = visibility_range.start;
    parser_advance(state);
    break;
  }
  default:
    visibility_range = NULL_RANGE;
    visibility = NULL;
    break;
  }

  range keyword_range = state->current_token.range;

  range kind_range;
  InstanceSingletonKind kind;
  if (instance_only) {
    kind_range = NULL_RANGE;
    kind = INSTANCE_KIND;
  } else {
    kind = parse_instance_singleton_kind(state, visibility == NULL, &kind_range);
  }

  range name_range;
  rbs_ast_symbol_t *name = parse_method_name(state, &name_range);

  #define SELF_ID rbs_constant_pool_insert_constant(&state->constant_pool, (const unsigned char *) "self?", strlen("self?"))

  if (state->next_token.type == pDOT && name->constant_id == SELF_ID) {
    raise_syntax_error(
      state,
      state->next_token,
      "`self?` method cannot have visibility"
    );
  } else {
    parser_advance_assert(state, pCOLON);
  }

  parser_push_typevar_table(state, kind != INSTANCE_KIND);

  rbs_node_list_t *overloads = rbs_node_list_new(&state->allocator);
  bool overloading = false;
  range overloading_range = NULL_RANGE;
  bool loop = true;
  while (loop) {
    rbs_node_list_t *annotations = rbs_node_list_new(&state->allocator);
    position overload_annot_pos = NullPosition;

    if (state->next_token.type == tANNOTATION) {
      parse_annotations(state, annotations, &overload_annot_pos);
    }

    switch (state->next_token.type) {
    case pLPAREN:
    case pARROW:
    case pLBRACE:
    case pLBRACKET:
    case pQUESTION:
      {
        rbs_node_t *method_type = (rbs_node_t *) parse_method_type(state);
        rbs_node_t *overload = (rbs_node_t *) rbs_ast_members_methoddefinition_overload_new(&state->allocator, annotations, method_type);
        rbs_node_list_append(overloads, overload);
        member_range.end = state->current_token.range.end;
        break;
      }

    case pDOT3:
      if (accept_overload) {
        overloading = true;
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

  rbs_keyword_t *k;
  switch (kind) {
  case INSTANCE_KIND: {
    k = rbs_keyword_new(&state->allocator, INTERN("instance"));
    break;
  }
  case SINGLETON_KIND: {
    k = rbs_keyword_new(&state->allocator, INTERN("singleton"));
    break;
  }
  case INSTANCE_SINGLETON_KIND: {
    k = rbs_keyword_new(&state->allocator, INTERN("singleton_instance"));
    break;
  }
  default:
    state->aborted = true;
    return NULL;
  }

  rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
  rbs_loc_alloc_children(loc, 5);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_optional_child(loc, INTERN("kind"), kind_range);
  rbs_loc_add_optional_child(loc, INTERN("overloading"), overloading_range);
  rbs_loc_add_optional_child(loc, INTERN("visibility"), visibility_range);

  return rbs_ast_members_methoddefinition_new(&state->allocator, name, k, overloads, annotations, loc, comment, overloading, visibility);
}

/**
 * class_instance_name ::= {} <class_name>
 *                       | {} class_name `[` type args <`]`>
 *
 * @param kind
 * */
rbs_typename_t *class_instance_name(parserstate *state, TypeNameKind kind, rbs_node_list_t *args, range *name_range, range *args_range) {
  parser_advance(state);

  rbs_typename_t *name = parse_type_name(state, kind, name_range);

  if (state->next_token.type == pLBRACKET) {
    parser_advance(state);
    args_range->start = state->current_token.range.start;
    parse_type_list(state, pRBRACKET, args);
    parser_advance_assert(state, pRBRACKET);
    args_range->end = state->current_token.range.end;
  } else {
    *args_range = NULL_RANGE;
  }

  return name;
}

/**
 *  mixin_member ::= {kINCLUDE} <class_instance_name>
 *                 | {kPREPEND} <class_instance_name>
 *                 | {kEXTEND} <class_instance_name>
 *
 * @param from_interface `true` when the member is in an interface.
 * */
static rbs_node_t *parse_mixin_member(parserstate *state, bool from_interface, position comment_pos, rbs_node_list_t *annotations) {
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
    state->aborted = true;
    return NULL;
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

  rbs_node_list_t *args = rbs_node_list_new(&state->allocator);
  range name_range;
  range args_range = NULL_RANGE;
  rbs_typename_t *name = class_instance_name(
    state,
    from_interface ? INTERFACE_NAME : (INTERFACE_NAME | CLASS_NAME),
    args, &name_range, &args_range
  );

  parser_pop_typevar_table(state);

  member_range.end = state->current_token.range.end;

  rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
  rbs_loc_alloc_children(loc, 3);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_optional_child(loc, INTERN("args"), args_range);

  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);
  switch (type)
  {
  case kINCLUDE:
    return (rbs_node_t *) rbs_ast_members_include_new(&state->allocator, name, args, annotations, loc, comment);
  case kEXTEND:
    return (rbs_node_t *) rbs_ast_members_extend_new(&state->allocator, name, args, annotations, loc, comment);
  case kPREPEND:
    return (rbs_node_t *) rbs_ast_members_prepend_new(&state->allocator, name, args, annotations, loc, comment);
  default:
    state->aborted = true;
    return NULL;
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
static rbs_ast_members_alias_t *parse_alias_member(parserstate *state, bool instance_only, position comment_pos, rbs_node_list_t *annotations) {
  range member_range;
  member_range.start = state->current_token.range.start;
  range keyword_range = state->current_token.range;

  comment_pos = nonnull_pos_or(comment_pos, member_range.start);
  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);

  rbs_keyword_t *kind;
  rbs_ast_symbol_t *new_name, *old_name;
  range new_kind_range, old_kind_range, new_name_range, old_name_range;

  if (!instance_only && state->next_token.type == kSELF) {
    kind = rbs_keyword_new(&state->allocator, INTERN("singleton"));

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
    kind = rbs_keyword_new(&state->allocator, INTERN("instance"));
    new_name = parse_method_name(state, &new_name_range);
    old_name = parse_method_name(state, &old_name_range);

    new_kind_range = NULL_RANGE;
    old_kind_range = NULL_RANGE;
  }

  member_range.end = state->current_token.range.end;
  rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
  rbs_loc_alloc_children(loc, 5);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("new_name"), new_name_range);
  rbs_loc_add_required_child(loc, INTERN("old_name"), old_name_range);
  rbs_loc_add_optional_child(loc, INTERN("new_kind"), new_kind_range);
  rbs_loc_add_optional_child(loc, INTERN("old_kind"), old_kind_range);

  return rbs_ast_members_alias_new(&state->allocator, new_name, old_name, kind, annotations, loc, comment);
}

/*
  variable_member ::= {tAIDENT} `:` <type>
                    | {kSELF} `.` tAIDENT `:` <type>
                    | {tA2IDENT} `:` <type>
*/
static rbs_node_t *parse_variable_member(parserstate *state, position comment_pos, rbs_node_list_t *annotations) {
  if (annotations->length > 0) {
    raise_syntax_error(
      state,
      state->current_token,
      "annotation cannot be given to variable members"
    );
  }

  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);
  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);

  switch (state->current_token.type)
  {
  case tAIDENT: {
    range name_range = state->current_token.range;
    rbs_ast_symbol_t *name = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));

    parser_advance_assert(state, pCOLON);
    range colon_range = state->current_token.range;

    rbs_node_t *type = parse_type(state);
    member_range.end = state->current_token.range.end;

    rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
    rbs_loc_alloc_children(loc, 3);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);
    rbs_loc_add_optional_child(loc, INTERN("kind"), NULL_RANGE);

    return (rbs_node_t *)rbs_ast_members_instancevariable_new(&state->allocator, name, type, loc, comment);
  }
  case tA2IDENT: {
    range name_range = state->current_token.range;
    rbs_ast_symbol_t *name = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));

    parser_advance_assert(state, pCOLON);
    range colon_range = state->current_token.range;

    parser_push_typevar_table(state, true);
    rbs_node_t *type = parse_type(state);
    parser_pop_typevar_table(state);
    member_range.end = state->current_token.range.end;

    rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
    rbs_loc_alloc_children(loc, 3);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);
    rbs_loc_add_optional_child(loc, INTERN("kind"), NULL_RANGE);

    return (rbs_node_t *) rbs_ast_members_classvariable_new(&state->allocator, name, type, loc, comment);
  }
  case kSELF: {
    range kind_range = {
      .start = state->current_token.range.start,
      .end = state->next_token.range.end
    };

    parser_advance_assert(state, pDOT);
    parser_advance_assert(state, tAIDENT);

    range name_range = state->current_token.range;
    rbs_ast_symbol_t *name = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));

    parser_advance_assert(state, pCOLON);
    range colon_range = state->current_token.range;

    parser_push_typevar_table(state, true);
    rbs_node_t *type = parse_type(state);
    parser_pop_typevar_table(state);
    member_range.end = state->current_token.range.end;

    rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
    rbs_loc_alloc_children(loc, 3);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_required_child(loc, INTERN("colon"), colon_range);
    rbs_loc_add_optional_child(loc, INTERN("kind"), kind_range);

    return (rbs_node_t *)rbs_ast_members_classinstancevariable_new(&state->allocator, name, type, loc, comment);
  }
  default:
    state->aborted = true;
    return NULL;
  }
}

/*
  visibility_member ::= {<`public`>}
                      | {<`private`>}
*/
static rbs_node_t *parse_visibility_member(parserstate *state, rbs_node_list_t *annotations) {
  if (annotations->length > 0) {
    raise_syntax_error(
      state,
      state->current_token,
      "annotation cannot be given to visibility members"
    );
  }

  rbs_location_t *location = rbs_location_new(state->buffer, state->current_token.range);

  switch (state->current_token.type)
  {
  case kPUBLIC:
    return (rbs_node_t *) rbs_ast_members_public_new(&state->allocator, location);
  case kPRIVATE:
    return (rbs_node_t *) rbs_ast_members_private_new(&state->allocator, location);
  default:
    state->aborted = true;
    return NULL;
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
static rbs_node_t *parse_attribute_member(parserstate *state, position comment_pos, rbs_node_list_t *annotations) {
  range member_range;

  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);
  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);

  rbs_keyword_t *visibility;
  range visibility_range;
  switch (state->current_token.type)
  {
  case kPRIVATE: {
    visibility = rbs_keyword_new(&state->allocator, INTERN("private"));
    visibility_range = state->current_token.range;
    parser_advance(state);
    break;
  }
  case kPUBLIC: {
    visibility = rbs_keyword_new(&state->allocator, INTERN("public"));
    visibility_range = state->current_token.range;
    parser_advance(state);
    break;
  }
  default:
    visibility = NULL;
    visibility_range = NULL_RANGE;
    break;
  }

  enum TokenType attr_type = state->current_token.type;
  range keyword_range = state->current_token.range;

  range kind_range;
  InstanceSingletonKind is_kind = parse_instance_singleton_kind(state, false, &kind_range);
  rbs_keyword_t *kind = rbs_keyword_new(&state->allocator, INTERN(((is_kind == INSTANCE_KIND) ? "instance" : "singleton")));

  range name_range;
  rbs_ast_symbol_t *attr_name = parse_method_name(state, &name_range);

  rbs_node_t *ivar_name; // rbs_ast_symbol_t, NULL or rbs_ast_bool_new(&state->allocator, false)
  range ivar_range, ivar_name_range;
  if (state->next_token.type == pLPAREN) {
    parser_advance_assert(state, pLPAREN);
    ivar_range.start = state->current_token.range.start;

    if (parser_advance_if(state, tAIDENT)) {
      ivar_name = (rbs_node_t *) rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));
      ivar_name_range = state->current_token.range;
    } else {
      ivar_name = (rbs_node_t *) rbs_ast_bool_new(&state->allocator, false);
      ivar_name_range = NULL_RANGE;
    }

    parser_advance_assert(state, pRPAREN);
    ivar_range.end = state->current_token.range.end;
  } else {
    ivar_range = NULL_RANGE;
    ivar_name = NULL;
    ivar_name_range = NULL_RANGE;
  }

  parser_advance_assert(state, pCOLON);
  range colon_range = state->current_token.range;

  parser_push_typevar_table(state, is_kind == SINGLETON_KIND);
  rbs_node_t *type = parse_type(state);
  parser_pop_typevar_table(state);
  member_range.end = state->current_token.range.end;

  rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
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
    return (rbs_node_t *) rbs_ast_members_attrreader_new(&state->allocator, attr_name, type, ivar_name, kind, annotations, loc, comment, visibility);
  case kATTRWRITER:
    return (rbs_node_t *) rbs_ast_members_attrwriter_new(&state->allocator, attr_name, type, ivar_name, kind, annotations, loc, comment, visibility);
  case kATTRACCESSOR:
    return (rbs_node_t *) rbs_ast_members_attraccessor_new(&state->allocator, attr_name, type, ivar_name, kind, annotations, loc, comment, visibility);
  default:
    state->aborted = true;
    return NULL;
  }
}

/*
  interface_members ::= {} ...<interface_member> kEND

  interface_member ::= def_member     (instance method only && no overloading)
                     | mixin_member   (interface only)
                     | alias_member   (instance only)
*/
static rbs_node_list_t *parse_interface_members(parserstate *state) {
  rbs_node_list_t *members = rbs_node_list_new(&state->allocator);

  while (state->next_token.type != kEND) {
    rbs_node_list_t *annotations = rbs_node_list_new(&state->allocator);
    position annot_pos = NullPosition;

    parse_annotations(state, annotations, &annot_pos);

    parser_advance(state);

    rbs_node_t *member;
    switch (state->current_token.type) {
    case kDEF: {
      member = (rbs_node_t *) parse_member_def(state, true, true, annot_pos, annotations);
      break;
    }

    case kINCLUDE:
    case kEXTEND:
    case kPREPEND: {
      member = (rbs_node_t *) parse_mixin_member(state, true, annot_pos, annotations);
      break;
    }

    case kALIAS: {
      member = (rbs_node_t *) parse_alias_member(state, true, annot_pos, annotations);
      break;
    }

    default:
      raise_syntax_error(
        state,
        state->current_token,
        "unexpected token for interface declaration member"
      );
    }

    rbs_node_list_append(members, member);
  }

  return members;
}

/*
  interface_decl ::= {`interface`} interface_name module_type_params interface_members <kEND>
*/
static rbs_ast_declarations_interface_t *parse_interface_decl(parserstate *state, position comment_pos, rbs_node_list_t *annotations) {
  parser_push_typevar_table(state, true);

  range member_range;
  member_range.start = state->current_token.range.start;
  comment_pos = nonnull_pos_or(comment_pos, member_range.start);

  range keyword_range = state->current_token.range;

  parser_advance(state);

  range name_range;
  rbs_typename_t *name = parse_type_name(state, INTERFACE_NAME, &name_range);

  range type_params_range;
  rbs_node_list_t *type_params = parse_type_params(state, &type_params_range, true);

  rbs_node_list_t *members = parse_interface_members(state);

  parser_advance_assert(state, kEND);
  range end_range = state->current_token.range;
  member_range.end = end_range.end;

  parser_pop_typevar_table(state);

  rbs_location_t *loc = rbs_location_new(state->buffer, member_range);
  rbs_loc_alloc_children(loc, 4);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("end"), end_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), type_params_range);

  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);

  return rbs_ast_declarations_interface_new(&state->allocator, name, type_params, members, annotations, loc, comment);
}

/*
  module_self_types ::= {`:`} module_self_type `,` ... `,` <module_self_type>

  module_self_type ::= <module_name>
                     | module_name `[` type_list <`]`>
*/
static void parse_module_self_types(parserstate *state, rbs_node_list_t *array) {
  while (true) {
    parser_advance(state);

    range self_range;
    self_range.start = state->current_token.range.start;
    range name_range;
    rbs_typename_t *module_name = parse_type_name(state, CLASS_NAME | INTERFACE_NAME, &name_range);
    self_range.end = name_range.end;

    rbs_node_list_t *args = rbs_node_list_new(&state->allocator);
    range args_range = NULL_RANGE;
    if (state->next_token.type == pLBRACKET) {
      parser_advance(state);
      args_range.start = state->current_token.range.start;
      parse_type_list(state, pRBRACKET, args);
      parser_advance(state);
      self_range.end = args_range.end = state->current_token.range.end;
    }

    rbs_location_t *loc = rbs_location_new(state->buffer, self_range);
    rbs_loc_alloc_children(loc, 2);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_optional_child(loc, INTERN("args"), args_range);

    rbs_ast_declarations_module_self_t *self_type = rbs_ast_declarations_module_self_new(&state->allocator, module_name, args, loc);
    rbs_node_list_append(array, (rbs_node_t *)self_type);

    if (state->next_token.type == pCOMMA) {
      parser_advance(state);
    } else {
      break;
    }
  }
}

static rbs_node_t *parse_nested_decl(parserstate *state, const char *nested_in, position annot_pos, rbs_node_list_t *annotations);

/*
  module_members ::= {} ...<module_member> kEND

  module_member ::= def_member
                  | variable_member
                  | mixin_member
                  | alias_member
                  | attribute_member
                  | `public`
                  | `private`
*/
static rbs_node_list_t *parse_module_members(parserstate *state) {
  rbs_node_list_t *members = rbs_node_list_new(&state->allocator);

  while (state->next_token.type != kEND) {
    rbs_node_list_t *annotations = rbs_node_list_new(&state->allocator);

    position annot_pos = NullPosition;
    parse_annotations(state, annotations, &annot_pos);

    parser_advance(state);

    rbs_node_t *member;
    switch (state->current_token.type)
    {
    case kDEF: {
      member = (rbs_node_t *) parse_member_def(state, false, true, annot_pos, annotations);
      break;
    }

    case kINCLUDE:
    case kEXTEND:
    case kPREPEND: {
      member = (rbs_node_t *) parse_mixin_member(state, false, annot_pos, annotations);
      break;
    }

    case kALIAS: {
      member = (rbs_node_t *) parse_alias_member(state, false, annot_pos, annotations);
      break;
    }

    case tAIDENT:
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
          member = (rbs_node_t *) parse_member_def(state, false, true, annot_pos, annotations);
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

    rbs_node_list_append(members, member);
  }

  return members;
}

/*
  module_decl ::= {module_name} module_type_params module_members <kEND>
                | {module_name} module_name module_type_params `:` module_self_types module_members <kEND>
*/
static rbs_ast_declarations_module_t *parse_module_decl0(parserstate *state, range keyword_range, rbs_typename_t *module_name, range name_range, rbs_ast_comment_t *comment, rbs_node_list_t *annotations) {
  parser_push_typevar_table(state, true);

  range decl_range;
  decl_range.start = keyword_range.start;

  range type_params_range;
  rbs_node_list_t *type_params = parse_type_params(state, &type_params_range, true);

  rbs_node_list_t *self_types = rbs_node_list_new(&state->allocator);
  range colon_range;
  range self_types_range;
  if (state->next_token.type == pCOLON) {
    parser_advance(state);
    colon_range = state->current_token.range;
    self_types_range.start = state->next_token.range.start;
    parse_module_self_types(state, self_types);
    self_types_range.end = state->current_token.range.end;
  } else {
    colon_range = NULL_RANGE;
    self_types_range = NULL_RANGE;
  }

  rbs_node_list_t *members = parse_module_members(state);

  parser_advance_assert(state, kEND);
  range end_range = state->current_token.range;
  decl_range.end = state->current_token.range.end;

  rbs_location_t *loc = rbs_location_new(state->buffer, decl_range);
  rbs_loc_alloc_children(loc, 6);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("end"), end_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), type_params_range);
  rbs_loc_add_optional_child(loc, INTERN("colon"), colon_range);
  rbs_loc_add_optional_child(loc, INTERN("self_types"), self_types_range);

  parser_pop_typevar_table(state);

  return rbs_ast_declarations_module_new(&state->allocator, module_name, type_params, self_types, members, annotations, loc, comment);
}

/*
  module_decl ::= {`module`} module_name `=` old_module_name <kEND>
                | {`module`} module_name module_decl0 <kEND>

*/
static rbs_node_t *parse_module_decl(parserstate *state, position comment_pos, rbs_node_list_t *annotations) {
  range keyword_range = state->current_token.range;

  comment_pos = nonnull_pos_or(comment_pos, state->current_token.range.start);
  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);

  parser_advance(state);
  range module_name_range;
  rbs_typename_t *module_name = parse_type_name(state, CLASS_NAME, &module_name_range);

  if (state->next_token.type == pEQ) {
    range eq_range = state->next_token.range;
    parser_advance(state);
    parser_advance(state);

    range old_name_range;
    rbs_typename_t *old_name = parse_type_name(state, CLASS_NAME, &old_name_range);

    range decl_range = {
      .start = keyword_range.start,
      .end = old_name_range.end
    };

    rbs_location_t *loc = rbs_location_new(state->buffer, decl_range);
    rbs_loc_alloc_children(loc, 4);
    rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
    rbs_loc_add_required_child(loc, INTERN("new_name"), module_name_range);
    rbs_loc_add_required_child(loc, INTERN("eq"), eq_range);
    rbs_loc_add_optional_child(loc, INTERN("old_name"), old_name_range);

    return (rbs_node_t *) rbs_ast_declarations_modulealias_new(&state->allocator, module_name, old_name, loc, comment);
  } else {
    return (rbs_node_t *) parse_module_decl0(state, keyword_range, module_name, module_name_range, comment, annotations);
  }
}

/*
  class_decl_super ::= {} `<` <class_instance_name>
                     | {<>}
*/
static rbs_ast_declarations_class_super_t *parse_class_decl_super(parserstate *state, range *lt_range) {
  if (parser_advance_if(state, pLT)) {
    *lt_range = state->current_token.range;

    range super_range;
    super_range.start = state->next_token.range.start;

    rbs_node_list_t *args = rbs_node_list_new(&state->allocator);
    range name_range, args_range;
    rbs_typename_t *name = class_instance_name(state, CLASS_NAME, args, &name_range, &args_range);

    super_range.end = state->current_token.range.end;

    rbs_location_t *loc = rbs_location_new(state->buffer, super_range);
    rbs_loc_alloc_children(loc, 2);
    rbs_loc_add_required_child(loc, INTERN("name"), name_range);
    rbs_loc_add_optional_child(loc, INTERN("args"), args_range);


    return rbs_ast_declarations_class_super_new(&state->allocator, name, args, loc);
  } else {
    *lt_range = NULL_RANGE;
    return NULL;
  }
}

/*
  class_decl ::= {class_name} type_params class_decl_super class_members <`end`>
*/
static rbs_ast_declarations_class_t *parse_class_decl0(parserstate *state, range keyword_range, rbs_typename_t *name, range name_range, rbs_ast_comment_t *comment, rbs_node_list_t *annotations) {
  parser_push_typevar_table(state, true);

  range decl_range;
  decl_range.start = keyword_range.start;

  range type_params_range;
  rbs_node_list_t *type_params = parse_type_params(state, &type_params_range, true);

  range lt_range;
  rbs_ast_declarations_class_super_t *super = parse_class_decl_super(state, &lt_range);

  struct rbs_node_list *members = parse_module_members(state);
  parser_advance_assert(state, kEND);

  range end_range = state->current_token.range;

  decl_range.end = end_range.end;

  parser_pop_typevar_table(state);

  rbs_location_t *loc = rbs_location_new(state->buffer, decl_range);
  rbs_loc_alloc_children(loc, 5);
  rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
  rbs_loc_add_required_child(loc, INTERN("name"), name_range);
  rbs_loc_add_required_child(loc, INTERN("end"), end_range);
  rbs_loc_add_optional_child(loc, INTERN("type_params"), type_params_range);
  rbs_loc_add_optional_child(loc, INTERN("lt"), lt_range);

  return rbs_ast_declarations_class_new(&state->allocator, name, type_params, super, members, annotations, loc, comment);
}

/*
  class_decl ::= {`class`} class_name `=` <class_name>
               | {`class`} class_name <class_decl0>
*/
static rbs_node_t *parse_class_decl(parserstate *state, position comment_pos, rbs_node_list_t *annotations) {
  range keyword_range = state->current_token.range;

  comment_pos = nonnull_pos_or(comment_pos, state->current_token.range.start);
  rbs_ast_comment_t *comment = get_comment(state, comment_pos.line);

  parser_advance(state);
  range class_name_range;
  rbs_typename_t *class_name = parse_type_name(state, CLASS_NAME, &class_name_range);

  if (state->next_token.type == pEQ) {
    range eq_range = state->next_token.range;
    parser_advance(state);
    parser_advance(state);

    range old_name_range;
    rbs_typename_t *old_name = parse_type_name(state, CLASS_NAME, &old_name_range);

    range decl_range = {
      .start = keyword_range.start,
      .end = old_name_range.end,
    };

    rbs_location_t *loc = rbs_location_new(state->buffer, decl_range);
    rbs_loc_alloc_children(loc, 4);
    rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);
    rbs_loc_add_required_child(loc, INTERN("new_name"), class_name_range);
    rbs_loc_add_required_child(loc, INTERN("eq"), eq_range);
    rbs_loc_add_optional_child(loc, INTERN("old_name"), old_name_range);


    return (rbs_node_t *) rbs_ast_declarations_classalias_new(&state->allocator, class_name, old_name, loc, comment);
  } else {
    return (rbs_node_t *) parse_class_decl0(state, keyword_range, class_name, class_name_range, comment, annotations);
  }
}

/*
  nested_decl ::= {<const_decl>}
                | {<class_decl>}
                | {<interface_decl>}
                | {<module_decl>}
                | {<class_decl>}
*/
static rbs_node_t *parse_nested_decl(parserstate *state, const char *nested_in, position annot_pos, rbs_node_list_t *annotations) {
  parser_push_typevar_table(state, true);

  rbs_node_t *decl;
  switch (state->current_token.type) {
  case tUIDENT:
  case pCOLON2: {
    decl = (rbs_node_t *) parse_const_decl(state);
    break;
  }
  case tGIDENT: {
    decl = (rbs_node_t *) parse_global_decl(state);
    break;
  }
  case kTYPE: {
    decl = (rbs_node_t *) parse_type_decl(state, annot_pos, annotations);
    break;
  }
  case kINTERFACE: {
    decl = (rbs_node_t *) parse_interface_decl(state, annot_pos, annotations);
    break;
  }
  case kMODULE: {
    decl = (rbs_node_t *) parse_module_decl(state, annot_pos, annotations);
    break;
  }
  case kCLASS: {
    decl = (rbs_node_t *) parse_class_decl(state, annot_pos, annotations);
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

static rbs_node_t *parse_decl(parserstate *state) {
  rbs_node_list_t *annotations = rbs_node_list_new(&state->allocator);
  position annot_pos = NullPosition;

  parse_annotations(state, annotations, &annot_pos);

  parser_advance(state);
  switch (state->current_token.type) {
  case tUIDENT:
  case pCOLON2: {
    return (rbs_node_t *) parse_const_decl(state);
  }
  case tGIDENT: {
    return (rbs_node_t *) parse_global_decl(state);
  }
  case kTYPE: {
    return (rbs_node_t *) parse_type_decl(state, annot_pos, annotations);
  }
  case kINTERFACE: {
    return (rbs_node_t *) parse_interface_decl(state, annot_pos, annotations);
  }
  case kMODULE: {
    return (rbs_node_t *) parse_module_decl(state, annot_pos, annotations);
  }
  case kCLASS: {
    return (rbs_node_t *) parse_class_decl(state, annot_pos, annotations);
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
static rbs_namespace_t *parse_namespace(parserstate *state, range *rg) {
  bool is_absolute = false;

  if (state->next_token.type == pCOLON2) {
    *rg = (range) {
      .start = state->next_token.range.start,
      .end = state->next_token.range.end,
    };
    is_absolute = true;

    parser_advance(state);
  }

  rbs_node_list_t *path = rbs_node_list_new(&state->allocator);

  while (true) {
    if (state->next_token.type == tUIDENT && state->next_token2.type == pCOLON2) {
      rbs_ast_symbol_t *symbol = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->next_token));
      rbs_node_list_append(path, (rbs_node_t *)symbol);
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

  return rbs_namespace_new(&state->allocator, path, is_absolute);
}

/*
  use_clauses ::= {} use_clause `,` ... `,` <use_clause>

  use_clause ::= {} namespace <tUIDENT>
               | {} namespace tUIDENT `as` <tUIDENT>
               | {} namespace <tSTAR>
*/
static void parse_use_clauses(parserstate *state, rbs_node_list_t *clauses) {
  while (true) {
    range namespace_range = NULL_RANGE;
    rbs_namespace_t *namespace = parse_namespace(state, &namespace_range);

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

        rbs_ast_symbol_t *symbol = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));
        rbs_typename_t *type_name = rbs_typename_new(&state->allocator, namespace, symbol);

        range keyword_range = NULL_RANGE;
        range new_name_range = NULL_RANGE;
        rbs_ast_symbol_t *new_name = NULL;
        range clause_range = type_name_range;
        if (state->next_token.type == kAS) {
          parser_advance(state);
          keyword_range = state->current_token.range;

          if (ident_type == tUIDENT) parser_advance_assert(state, tUIDENT);
          if (ident_type == tLIDENT) parser_advance_assert(state, tLIDENT);
          if (ident_type == tULIDENT) parser_advance_assert(state, tULIDENT);

          new_name = rbs_ast_symbol_new(&state->allocator, &state->constant_pool, INTERN_TOKEN(state, state->current_token));
          new_name_range = state->current_token.range;
          clause_range.end = new_name_range.end;
        }

        rbs_location_t *loc = rbs_location_new(state->buffer, clause_range);
        rbs_loc_alloc_children(loc, 3);
        rbs_loc_add_required_child(loc, INTERN("type_name"), type_name_range);
        rbs_loc_add_optional_child(loc, INTERN("keyword"), keyword_range);
        rbs_loc_add_optional_child(loc, INTERN("new_name"), new_name_range);

        rbs_ast_directives_use_singleclause_t *clause = rbs_ast_directives_use_singleclause_new(&state->allocator, type_name, new_name, loc);
        rbs_node_list_append(clauses, (rbs_node_t *)clause);

        break;
      }
      case pSTAR:
      {
        range clause_range = namespace_range;
        parser_advance(state);

        range star_range = state->current_token.range;
        clause_range.end = star_range.end;

        rbs_location_t *loc = rbs_location_new(state->buffer, clause_range);
        rbs_loc_alloc_children(loc, 2);
        rbs_loc_add_required_child(loc, INTERN("namespace"), namespace_range);
        rbs_loc_add_required_child(loc, INTERN("star"), star_range);

        rbs_ast_directives_use_wildcardclause_t *clause = rbs_ast_directives_use_wildcardclause_new(&state->allocator, namespace, loc);
        rbs_node_list_append(clauses, (rbs_node_t *)clause);

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
static rbs_ast_directives_use_t *parse_use_directive(parserstate *state) {
  if (state->next_token.type == kUSE) {
    parser_advance(state);

    range keyword_range = state->current_token.range;

    rbs_node_list_t *clauses = rbs_node_list_new(&state->allocator);
    parse_use_clauses(state, clauses);

    range directive_range = keyword_range;
    directive_range.end = state->current_token.range.end;

    rbs_location_t *loc = rbs_location_new(state->buffer, directive_range);
    rbs_loc_alloc_children(loc, 1);
    rbs_loc_add_required_child(loc, INTERN("keyword"), keyword_range);

    return rbs_ast_directives_use_new(&state->allocator, clauses, loc);
  } else {
    return NULL;
  }
}

rbs_signature_t *parse_signature(parserstate *state) {
  rbs_node_list_t *dirs = rbs_node_list_new(&state->allocator);
  rbs_node_list_t *decls = rbs_node_list_new(&state->allocator);

  while (state->next_token.type == kUSE) {
    rbs_ast_directives_use_t *use_node = parse_use_directive(state);
    if (use_node == NULL) {
      rbs_node_list_append(dirs, NULL);
    } else {
      rbs_node_list_append(dirs, (rbs_node_t *)use_node);
    }
  }

  while (state->next_token.type != pEOF) {
    rbs_node_t *decl = parse_decl(state);
    rbs_node_list_append(decls, decl);
  }

  return rbs_signature_new(&state->allocator, dirs, decls);
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
  parserstate *parser = arg->parser;

  if (parser->next_token.type == pEOF) {
    return Qnil;
  }

  rbs_node_t *type = parse_type(parser);

  if (parser->aborted) {
    rb_raise(rb_eRuntimeError, "Unexpected error");
  }

  if (RB_TEST(arg->require_eof)) {
    parser_advance_assert(parser, pEOF);
  }

  rbs_translation_context_t ctx = {
    .constant_pool = &parser->constant_pool,
  };

  return rbs_struct_to_ruby_value(ctx, type);
}

static VALUE
rbsparser_parse_type(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos, VALUE variables, VALUE require_eof)
{
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  parserstate *parser = alloc_parser(buffer, string, FIX2INT(start_pos), FIX2INT(end_pos), variables);
  struct parse_type_arg arg = {
    parser,
    require_eof
  };
  return rb_ensure(parse_type_try, (VALUE)&arg, ensure_free_parser, (VALUE)parser);
}

static VALUE
parse_method_type_try(VALUE a) {
  struct parse_type_arg *arg = (struct parse_type_arg *)a;
  parserstate *parser = arg->parser;

  if (parser->next_token.type == pEOF) {
    return Qnil;
  }

  rbs_methodtype_t *method_type = parse_method_type(parser);

  if (parser->aborted) {
    rb_raise(rb_eRuntimeError, "Unexpected error");
  }

  if (RB_TEST(arg->require_eof)) {
    parser_advance_assert(parser, pEOF);
  }

  rbs_translation_context_t ctx = {
    .constant_pool = &parser->constant_pool,
  };

  return rbs_struct_to_ruby_value(ctx, (rbs_node_t *) method_type);
}

static VALUE
rbsparser_parse_method_type(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos, VALUE variables, VALUE require_eof)
{
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  parserstate *parser = alloc_parser(buffer, string, FIX2INT(start_pos), FIX2INT(end_pos), variables);
  struct parse_type_arg arg = {
    parser,
    require_eof
  };
  return rb_ensure(parse_method_type_try, (VALUE)&arg, ensure_free_parser, (VALUE)parser);
}

static VALUE
parse_signature_try(VALUE a) {
  parserstate *parser = (parserstate *)a;

  rbs_signature_t *signature = parse_signature(parser);

  if (parser->aborted) {
    rb_raise(rb_eRuntimeError, "Unexpected error");
  }

  rbs_translation_context_t ctx = {
    .constant_pool = &parser->constant_pool,
  };

  return rbs_struct_to_ruby_value(ctx, (rbs_node_t *) signature);
}

static VALUE
rbsparser_parse_signature(VALUE self, VALUE buffer, VALUE start_pos, VALUE end_pos)
{
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);
  parserstate *parser = alloc_parser(buffer, string, FIX2INT(start_pos), FIX2INT(end_pos), Qnil);
  return rb_ensure(parse_signature_try, (VALUE)parser, ensure_free_parser, (VALUE)parser);
}

static VALUE
rbsparser_lex(VALUE self, VALUE buffer, VALUE end_pos) {
  VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
  StringValue(string);

  rbs_allocator_t allocator;
  rbs_allocator_init(&allocator);
  lexstate *lexer = alloc_lexer(&allocator, string, 0, FIX2INT(end_pos));

  VALUE results = rb_ary_new();
  token token = NullToken;
  while (token.type != pEOF) {
    token = rbsparser_next_token(lexer);
    VALUE type = ID2SYM(rb_intern(token_type_str(token.type)));
    VALUE location = rbs_new_location(buffer, token.range);
    VALUE pair = rb_ary_new3(2, type, location);
    rb_ary_push(results, pair);
  }

  rbs_allocator_free(&allocator);

  return results;
}

void rbs__init_parser(void) {
  RBS_Parser = rb_define_class_under(RBS, "Parser", rb_cObject);
  rb_gc_register_mark_object(RBS_Parser);
  VALUE empty_array = rb_obj_freeze(rb_ary_new());
  rb_gc_register_mark_object(empty_array);

  rb_define_singleton_method(RBS_Parser, "_parse_type", rbsparser_parse_type, 5);
  rb_define_singleton_method(RBS_Parser, "_parse_method_type", rbsparser_parse_method_type, 5);
  rb_define_singleton_method(RBS_Parser, "_parse_signature", rbsparser_parse_signature, 3);
  rb_define_singleton_method(RBS_Parser, "_lex", rbsparser_lex, 2);
}
