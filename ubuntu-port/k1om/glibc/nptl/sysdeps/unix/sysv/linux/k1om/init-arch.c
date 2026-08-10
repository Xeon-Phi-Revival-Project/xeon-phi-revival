/*
   K1OM uses the x86-64 cpu_features layout for NPTL ABI compatibility but
   has none of the SSE, AVX, xgetbv, or TSX paths that x86-64 probes here.
   Keep every optional feature disabled.

   The imported declaration header is upstream LGPL-covered.
*/
#include <sysdeps/x86_64/multiarch/init-arch.h>

struct cpu_features __cpu_features attribute_hidden =
  { .kind = arch_kind_other };

void
__init_cpu_features (void)
{
}

#undef __get_cpu_features
const struct cpu_features *
__get_cpu_features (void)
{
  return &__cpu_features;
}
