#include "rbs_extension.h"

#include "rbs_string_bridging.h"
#include "rbs/rbs_buffer.h"

#define RESET_TABLE_P(table) (table->size == 0)

id_table *alloc_empty_table(rbs_allocator_t *allocator) {
  id_table *table = rbs_allocator_alloc(allocator, id_table);

  *table = (id_table) {
    .size = 10,
    .count = 0,
    .ids = rbs_allocator_calloc(allocator, 10, rbs_constant_id_t),
    .next = NULL,
  };

  return table;
}

id_table *alloc_reset_table(rbs_allocator_t *allocator) {
  id_table *table = rbs_allocator_alloc(allocator, id_table);

  *table = (id_table) {
    .size = 0,
    .count = 0,
    .ids = NULL,
    .next = NULL,
  };

  return table;
}

id_table *parser_push_typevar_table(parserstate *state, bool reset) {
  if (reset) {
    id_table *table = alloc_reset_table(&state->allocator);
    table->next = state->vars;
    state->vars = table;
  }

  id_table *table = alloc_empty_table(&state->allocator);
  table->next = state->vars;
  state->vars = table;

  return table;
}

void parser_pop_typevar_table(parserstate *state) {
  id_table *table;

  if (state->vars) {
    table = state->vars;
    state->vars = table->next;
  } else {
    rb_raise(rb_eRuntimeError, "Cannot pop empty table");
  }

  if (state->vars && RESET_TABLE_P(state->vars)) {
    table = state->vars;
    state->vars = table->next;
  }
}

void parser_insert_typevar(parserstate *state, rbs_constant_id_t id) {
  id_table *table = state->vars;

  if (RESET_TABLE_P(table)) {
    rb_raise(rb_eRuntimeError, "Cannot insert to reset table");
  }

  if (table->size == table->count) {
    // expand
    rbs_constant_id_t *ptr = table->ids;
    table->size += 10;
    table->ids = rbs_allocator_calloc(&state->allocator, table->size, rbs_constant_id_t);
    memcpy(table->ids, ptr, sizeof(rbs_constant_id_t) * table->count);
  }

  table->ids[table->count++] = id;
}

bool parser_typevar_member(parserstate *state, rbs_constant_id_t id) {
  id_table *table = state->vars;

  while (table && !RESET_TABLE_P(table)) {
    for (size_t i = 0; i < table->count; i++) {
      if (table->ids[i] == id) {
        return true;
      }
    }

    table = table->next;
  }

  return false;
}

void print_parser(parserstate *state) {
  printf("  current_token = %s (%d...%d)\n", token_type_str(state->current_token.type), state->current_token.range.start.char_pos, state->current_token.range.end.char_pos);
  printf("     next_token = %s (%d...%d)\n", token_type_str(state->next_token.type), state->next_token.range.start.char_pos, state->next_token.range.end.char_pos);
  printf("    next_token2 = %s (%d...%d)\n", token_type_str(state->next_token2.type), state->next_token2.range.start.char_pos, state->next_token2.range.end.char_pos);
  printf("    next_token3 = %s (%d...%d)\n", token_type_str(state->next_token3.type), state->next_token3.range.start.char_pos, state->next_token3.range.end.char_pos);
}

void parser_advance(parserstate *state) {
  state->current_token = state->next_token;
  state->next_token = state->next_token2;
  state->next_token2 = state->next_token3;

  while (true) {
    if (state->next_token3.type == pEOF) {
      break;
    }

    state->next_token3 = rbsparser_next_token(state->lexstate);

    if (state->next_token3.type == tCOMMENT) {
      // skip
    } else if (state->next_token3.type == tLINECOMMENT) {
      insert_comment_line(state, state->next_token3);
    } else if (state->next_token3.type == tTRIVIA) {
      //skip
    } else {
      break;
    }
  }
}

/**
 * Advance token if _next_ token is `type`.
 * Ensures one token advance and `state->current_token.type == type`, or current token not changed.
 *
 * @returns true if token advances, false otherwise.
 **/
bool parser_advance_if(parserstate *state, enum TokenType type) {
  if (state->next_token.type == type) {
    parser_advance(state);
    return true;
  } else {
    return false;
  }
}

void parser_assert(parserstate *state, enum TokenType type) {
  if (state->current_token.type != type) {
    set_error(
      state,
      state->current_token,
      true,
      "expected a token `%s`",
      token_type_str(type)
    );
    raise_error(state, state->error);
  }
}

void parser_advance_assert(parserstate *state, enum TokenType type) {
  parser_advance(state);
  parser_assert(state, type);
}

void print_token(token tok) {
  printf(
    "%s char=%d...%d\n",
    token_type_str(tok.type),
    tok.range.start.char_pos,
    tok.range.end.char_pos
  );
}

void insert_comment_line(parserstate *state, token tok) {
  int prev_line = tok.range.start.line - 1;

  comment *com = comment_get_comment(state->last_comment, prev_line);

  if (com) {
    comment_insert_new_line(&state->allocator, com, tok);
  } else {
    state->last_comment = alloc_comment(&state->allocator, tok, state->last_comment);
  }
}

static rbs_ast_comment_t *parse_comment_lines(rbs_allocator_t *allocator, comment *com, VALUE buffer) {
  VALUE content = rb_funcall(buffer, rb_intern("content"), 0);
  rb_encoding *enc = rb_enc_get(content);

  int hash_bytes = rb_enc_codelen('#', enc);
  int space_bytes = rb_enc_codelen(' ', enc);

  rbs_buffer_t rbs_buffer;
  rbs_buffer_init(&rbs_buffer);

  for (size_t i = 0; i < com->line_count; i++) {
    token tok = com->tokens[i];

    char *comment_start = RSTRING_PTR(content) + tok.range.start.byte_pos + hash_bytes;
    int comment_bytes = RANGE_BYTES(tok.range) - hash_bytes;
    unsigned char c = rb_enc_mbc_to_codepoint(comment_start, RSTRING_END(content), enc);

    if (c == ' ') {
      comment_start += space_bytes;
      comment_bytes -= space_bytes;
    }

    rbs_buffer_append_string(&rbs_buffer, comment_start, comment_bytes);
    rbs_buffer_append_cstr(&rbs_buffer, "\n");
  }

  return rbs_ast_comment_new(
    allocator,
    rbs_buffer_to_string(&rbs_buffer),
    rbs_location_pp(&com->start, &com->end)
  );
}

rbs_ast_comment_t *get_comment(parserstate *state, int subject_line) {
  int comment_line = subject_line - 1;

  comment *com = comment_get_comment(state->last_comment, comment_line);

  if (com) {
    return parse_comment_lines(&state->allocator, com, state->buffer);
  } else {
    return NULL;
  }
}

comment *alloc_comment(rbs_allocator_t *allocator, token comment_token, comment *last_comment) {
  comment *new_comment = rbs_allocator_alloc(allocator, comment);

  *new_comment = (comment) {
    .start = comment_token.range.start,
    .end = comment_token.range.end,

    .line_size = 0,
    .line_count = 0,
    .tokens = NULL,

    .next_comment = last_comment,
  };

  comment_insert_new_line(allocator, new_comment, comment_token);

  return new_comment;
}

void comment_insert_new_line(rbs_allocator_t *allocator, comment *com, token comment_token) {
  if (com->line_count == 0) {
    com->start = comment_token.range.start;
  }

  if (com->line_count == com->line_size) {
    com->line_size += 10;

    if (com->tokens) {
      token *p = com->tokens;
      com->tokens = rbs_allocator_calloc(allocator, com->line_size, token);
      memcpy(com->tokens, p, sizeof(token) * com->line_count);
    } else {
      com->tokens = rbs_allocator_calloc(allocator, com->line_size, token);
    }
  }

  com->tokens[com->line_count++] = comment_token;
  com->end = comment_token.range.end;
}

comment *comment_get_comment(comment *com, int line) {
  if (com == NULL) {
    return NULL;
  }

  if (com->end.line < line) {
    return NULL;
  }

  if (com->end.line == line) {
    return com;
  }

  return comment_get_comment(com->next_comment, line);
}

lexstate *alloc_lexer(rbs_allocator_t *allocator, VALUE string, int start_pos, int end_pos) {
  if (start_pos < 0 || end_pos < 0) {
    rb_raise(rb_eArgError, "negative position range: %d...%d", start_pos, end_pos);
  }

  rb_encoding *ruby_encoding = rb_enc_get(string);
  const char *encoding_name = rb_enc_name(ruby_encoding);
  const char *encoding_name_end = encoding_name + strlen(encoding_name);
  const rbs_encoding_t *encoding = rbs_encoding_find((const uint8_t *) encoding_name, (const uint8_t *) encoding_name_end);

  lexstate *lexer = rbs_allocator_alloc(allocator, lexstate);

  position start_position = (position) {
    .byte_pos = 0,
    .char_pos = 0,
    .line = 1,
    .column = 0,
  };

  *lexer = (lexstate) {
    .string = rbs_string_from_ruby_string(string),
    .start_pos = start_pos,
    .end_pos = end_pos,
    .current = start_position,
    .start = { 0 },
    .first_token_of_line = false,
    .last_char = 0,
    .encoding = encoding,
  };

  skipn(lexer, start_pos);
  lexer->start = lexer->current;
  lexer->first_token_of_line = lexer->current.column == 0;

  return lexer;
}

parserstate *alloc_parser(VALUE buffer, VALUE string, int start_pos, int end_pos, VALUE variables) {
  rbs_allocator_t allocator;
  rbs_allocator_init(&allocator);

  lexstate *lexer = alloc_lexer(&allocator, string, start_pos, end_pos);
  parserstate *parser = rbs_allocator_alloc(&allocator, parserstate);

  *parser = (parserstate) {
    .lexstate = lexer,

    .current_token = NullToken,
    .next_token = NullToken,
    .next_token2 = NullToken,
    .next_token3 = NullToken,
    .buffer = buffer,
    .encoding = rb_enc_get(buffer),

    .vars = NULL,
    .last_comment = NULL,

    .constant_pool = {},
    .allocator = allocator,
    .error = NULL,
  };

  // The parser's constant pool is mainly used for storing the names of type variables, which usually aren't many.
  // Below are some statistics gathered from the current test suite. We can see that 56% of parsers never add to their
  // constant pool at all. The initial capacity needs to be a power of 2. Picking 2 means that we won't need to realloc
  // in 85% of cases.
  //
  // TODO: recalculate these statistics based on a real world codebase, rather than the test suite.
  //
  // | Size | Count | Cumulative | % Coverage |
  // |------|-------|------------|------------|
  // |   0  | 7,862 |      7,862 |     56%    |
  // |   1  | 3,196 |     11,058 |     79%    |
  // |   2  |   778 |     12,719 |     85%    |
  // |   3  |   883 |     11,941 |     91%    |
  // |   4  |   478 |     13,197 |     95%    |
  // |   5  |   316 |     13,513 |     97%    |
  // |   6  |   288 |     13,801 |     99%    |
  // |   7  |   144 |     13,945 |    100%    |
  const size_t initial_pool_capacity = 2;
  rbs_constant_pool_init(&parser->constant_pool, initial_pool_capacity);

  parser_advance(parser);
  parser_advance(parser);
  parser_advance(parser);

  if (!NIL_P(variables)) {
    if (!RB_TYPE_P(variables, T_ARRAY)) {
      rb_raise(rb_eTypeError,
               "wrong argument type %"PRIsVALUE" (must be array or nil)",
               rb_obj_class(variables));
    }

    parser_push_typevar_table(parser, true);

    for (long i = 0; i < rb_array_len(variables); i++) {
      VALUE symbol = rb_ary_entry(variables, i);
      VALUE name = rb_sym2str(symbol);

      rbs_constant_id_t id = rbs_constant_pool_insert_shared(
        &parser->constant_pool,
        (const uint8_t *) RSTRING_PTR(name),
        RSTRING_LEN(name)
      );

      parser_insert_typevar(parser, id);
    }
  }

  return parser;
}

void free_parser(parserstate *parser) {
  rbs_constant_pool_free(&parser->constant_pool);
  rbs_allocator_free(&parser->allocator);
}
