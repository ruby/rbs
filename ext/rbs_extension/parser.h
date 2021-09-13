#ifndef RBS__PARSER_H
#define RBS__PARSER_H

#include "ruby.h"
#include "parserstate.h"

/**
 * RBS::Parser class
 * */
extern VALUE RBS_Parser;

/**
 * RBS::Parser::KEYWORDS constant, which stores a hash from keyword string to token type fixnum
 * */
extern VALUE RBS_Parser_KEYWORDS;

VALUE parse_type(parserstate *state);
VALUE parse_method_type(parserstate *state);
VALUE parse_signature(parserstate *state);

void rbs__init_parser();

#endif
