#ifndef RBS_RBS_UNESCAPE_H
#define RBS_RBS_UNESCAPE_H

#include <stddef.h>

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
 *
 * @returns A new owned string that needs to be freed with `rbs_string_free()`
 * */
rbs_string_t rbs_unquote_string(rbs_string_t input);

#endif // RBS_RBS_UNESCAPE_H
