#include <stdbool.h>

#include "ruby.h"
#include "ruby/re.h"
#include "ruby/encoding.h"

#include "class_constants.h"
#include "rbs.h"
#include "lexer.h"
#include "parser.h"

/**
 * RBS::Parser class
 * */
extern VALUE RBS_Parser;

/**
 * Raises RBS::ParsingError on `tok` with message constructed with given `fmt`.
 *
 * ```
 * foo.rbs:11:21...11:25: Syntax error: {message}, token=`{tok source}` ({tok type})
 * ```
 * */
NORETURN(void) raise_error(parserstate *state, error *error);
