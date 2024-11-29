#include <stdbool.h>

#include "ruby.h"
#include "ruby/re.h"
#include "ruby/encoding.h"

#include "class_constants.h"
#include "rbs.h"
#include "lexer.h"
#include "parser.h"

/**
 * Receives `parserstate` and `range`, which represents a string token or symbol token, and returns a string VALUE.
 *
 *    Input token | Output string
 *    ------------+-------------
 *    "foo\\n"    | foo\n
 *    'foo'       | foo
 *    `bar`       | bar
 *    :"baz\\t"   | baz\t
 *    :'baz'      | baz
 * */
VALUE rbs_unquote_string(parserstate *state, range rg, int offset_bytes);

PRINTF_ARGS(void set_error(parserstate *state, token tok, bool syntax_error, const char *fmt, ...), 4, 5);

/**
 * Raises RBS::ParsingError on `tok` with message constructed with given `fmt`.
 *
 * ```
 * foo.rbs:11:21...11:25: Syntax error: {message}, token=`{tok source}` ({tok type})
 * ```
 * */
NORETURN(void) raise_error(parserstate *state, error *error);
