#ifndef RBS_ASSERT_H
#define RBS_ASSERT_H

#include "rbs/defines.h"
#include <stdbool.h>

void rbs_assert(bool condition, const char *fmt, ...) RBS_ATTRIBUTE_FORMAT(2, 3);

#endif
