#include <stdbool.h>

#include "ruby.h"
#include "ruby/re.h"
#include "ruby/encoding.h"

#include "class_constants.h"
#include "rbs.h"
#include "rbs/lexer.h"
#include "parser.h"

/**
 * RBS::Parser class
 * */
extern VALUE RBS_Parser;
