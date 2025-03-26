#ifndef RBS_ENCODING_H
#define RBS_ENCODING_H

#include "rbs_string.h"

unsigned int rbs_utf8_to_codepoint(const rbs_string_t string);
int utf8_codelen(unsigned int c);

#endif // RBS_ENCODING_H
