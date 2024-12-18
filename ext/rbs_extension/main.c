#include "rbs_extension.h"
#include "rbs/util/rbs_constant_pool.h"

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
}
