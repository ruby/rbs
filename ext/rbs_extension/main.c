#include "rbs_extension.h"
#include "rbs/util/rbs_constant_pool.h"

#include "ruby/vm.h"

static
void Deinit_rbs_extension(ruby_vm_t *_) {
  rbs_constant_pool_free(RBS_GLOBAL_CONSTANT_POOL);
}

void
Init_rbs_extension(void)
{
#ifdef HAVE_RB_EXT_RACTOR_SAFE
  rb_ext_ractor_safe(true);
#endif
  rbs__init_constants();
  rbs__init_location();
  rbs__init_parser();

  /* Calculated based on the number of unique strings used with the `INTERN` macro in `parser.c`.
   *
   * ```bash
   * grep -o 'INTERN("\([^"]*\)")' ext/rbs_extension/parser.c \
   *     | sed 's/INTERN("\(.*\)")/\1/' \
   *     | sort -u \
   *     | wc -l
   * ```
   */
  const size_t num_uniquely_interned_strings = 26;
  rbs_constant_pool_init(RBS_GLOBAL_CONSTANT_POOL, num_uniquely_interned_strings);

  ruby_vm_at_exit(Deinit_rbs_extension);
}
