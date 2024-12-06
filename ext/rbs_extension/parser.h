#ifndef RBS__PARSER_H
#define RBS__PARSER_H

#include "ruby.h"
#include "parserstate.h"

/**
 * RBS::Parser class
 * */
extern VALUE RBS_Parser;

bool parse_type(parserstate *state, rbs_node_t **type);
bool parse_method_type(parserstate *state, rbs_methodtype_t **method_type);
bool parse_signature(parserstate *state, rbs_signature_t **signature);

void rbs__init_parser();

#endif
