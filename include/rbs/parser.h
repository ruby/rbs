#ifndef RBS__PARSER_H
#define RBS__PARSER_H

#include "rbs/defines.h"
#include "rbs/util/rbs_allocator.h"
#include "rbs/util/rbs_constant_pool.h"
#include "rbs/lexer.h"
#include "rbs/ast.h"

#include <stdbool.h>
#include <stddef.h>

/**
 * comment represents a sequence of comment lines.
 *
 *     # Comment for the method.
 *     #
 *     # ```rb
 *     # object.foo()  # Do something
 *     # ```
 *     #
 *     def foo: () -> void
 *
 * A comment object represents the six lines of comments.
 * */
typedef struct comment {
  position start;
  position end;

  size_t line_size;
  size_t line_count;
  token *tokens;

  struct comment *next_comment;
} comment;

typedef struct error {
  char *message;
  token token;
  bool syntax_error;
} error;

/**
 * An RBS parser is a LL(3) parser.
 * */
typedef struct {
  lexstate *lexstate;

  token current_token;
  token next_token;       /* The first lookahead token */
  token next_token2;      /* The second lookahead token */
  token next_token3;      /* The third lookahead token */

  struct id_table *vars;  /* Known type variables */
  comment *last_comment;  /* Last read comment */

  rbs_constant_pool_t constant_pool;
  rbs_allocator_t allocator;
  error *error;
} parserstate;

/**
 * Insert new table entry.
 * Setting `reset` inserts a _reset_ entry, which stops searching.
 *
 * ```
 * class Foo[A]
 *          ^^^                      <= push new table with reset
 *   def foo: [B] () -> [A, B]
 *            ^^^                    <= push new table without reset
 *
 *   class Baz[C]
 *            ^^^                    <= push new table with reset
 *   end
 * end
 * ```
 * */
void parser_push_typevar_table(parserstate *state, bool reset);

/**
 * Insert new type variable into the latest table.
 * */
NODISCARD bool parser_insert_typevar(parserstate *state, rbs_constant_id_t id);

/**
 * Allocate new lexstate object.
 *
 * ```
 * VALUE string = rb_funcall(buffer, rb_intern("content"), 0);
 * alloc_lexer(string, 0, 31)    // New lexstate with buffer content
 * ```
 * */
lexstate *alloc_lexer(rbs_allocator_t *, rbs_string_t string, const rbs_encoding_t *encoding, int start_pos, int end_pos);

/**
 * Allocate new parserstate object.
 *
 * ```
 * alloc_parser(buffer, string, encoding, 0, 1);
 * ```
 * */
parserstate *alloc_parser(rbs_string_t string, const rbs_encoding_t *encoding, int start_pos, int end_pos);
void free_parser(parserstate *parser);

/**
 * Advance one token.
 * */
void parser_advance(parserstate *state);

void print_parser(parserstate *state);

/**
 * Returns a RBS::Comment object associated with an subject at `subject_line`.
 *
 * ```rbs
 * # Comment1
 * class Foo           # This is the subject line for Comment1
 *
 *   # Comment2
 *   %a{annotation}    # This is the subject line for Comment2
 *   def foo: () -> void
 * end
 * ```
 * */
rbs_ast_comment_t *get_comment(parserstate *state, int subject_line);

void set_error(parserstate *state, token tok, bool syntax_error, const char *fmt, ...) RBS_ATTRIBUTE_FORMAT(4, 5);

bool parse_type(parserstate *state, rbs_node_t **type);
bool parse_method_type(parserstate *state, rbs_methodtype_t **method_type);
bool parse_signature(parserstate *state, rbs_signature_t **signature);

#endif
