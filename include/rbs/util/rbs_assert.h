#ifndef RBS_ASSERT_H
#define RBS_ASSERT_H

#include "rbs/defines.h"
#include <stdbool.h>

void rbs_assert_impl(bool condition, const char *fmt, ...) RBS_ATTRIBUTE_FORMAT(2, 3);

#ifdef NDEBUG
#define rbs_assert(condition, fmt, ...) ((void) 0)
#else
#define rbs_assert(condition, fmt, ...) rbs_assert_impl(condition, fmt, ##__VA_ARGS__)
#endif

#endif
