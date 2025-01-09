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

  rbs_constant_pool_init(RBS_GLOBAL_CONSTANT_POOL, 0);
  ruby_vm_at_exit(Deinit_rbs_extension);
}
