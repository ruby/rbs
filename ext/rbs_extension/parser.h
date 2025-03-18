#ifndef RBS__PARSER_H
#define RBS__PARSER_H

#include "ruby.h"
#include "parserstate.h"

/**
 * RBS::Parser class
 * */
extern VALUE RBS_Parser;

typedef enum {
  vcNull = 0,
  vcNoVoid = 1,
  vcNoVoidAllowedHere = 2,
  vcNoSelf = 4,
  vcNoClassish = 8,
} ValidationContext;

VALUE parse_type(parserstate *state, ValidationContext vc);
VALUE parse_method_type(parserstate *state, ValidationContext vc);
VALUE parse_signature(parserstate *state);

void rbs__init_parser();

#endif
