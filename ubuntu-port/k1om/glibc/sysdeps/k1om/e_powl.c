/*
   K1OM lacks the later x87 compare/pop instructions used by the x86-64
   assembly implementation.  Select eglibc's portable long-double pow
   implementation pattern, as used by the upstream m68k long-double port.
   The included upstream source is LGPL-2.1-or-later.
*/
#define SUFF l
#define float_type long double
#include <e_pow.c>
