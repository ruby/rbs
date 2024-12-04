#ifndef RBS_DEFINES_H
#define RBS_DEFINES_H


/***********************************************************************************************************************
 * Copied+modified subset of Prism's `include/prism/defines.h`                                                         *
 **********************************************************************************************************************/

/**
 * Certain compilers support specifying that a function accepts variadic
 * parameters that look like printf format strings to provide a better developer
 * experience when someone is using the function. This macro does that in a
 * compiler-agnostic way.
 */
#if defined(__GNUC__)
#   if defined(__MINGW_PRINTF_FORMAT)
#       define RBS_ATTRIBUTE_FORMAT(string_index, argument_index) __attribute__((format(__MINGW_PRINTF_FORMAT, string_index, argument_index)))
#   else
#       define RBS_ATTRIBUTE_FORMAT(string_index, argument_index) __attribute__((format(printf, string_index, argument_index)))
#   endif
#elif defined(__clang__)
#   define RBS_ATTRIBUTE_FORMAT(string_index, argument_index) __attribute__((__format__(__printf__, string_index, argument_index)))
#else
#   define RBS_ATTRIBUTE_FORMAT(string_index, argument_index)
#endif

/***********************************************************************************************************************
 * Custom defines for RBS                                                                                              *
 **********************************************************************************************************************/

#define NODISCARD __attribute__((warn_unused_result))

#endif
