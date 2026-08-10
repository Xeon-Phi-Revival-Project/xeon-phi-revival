/*
   K1OM lacks the conditional x87 instructions used by x86-64 fmaxl assembly.
   Use eglibc's generic C long-double implementation instead.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <math/s_fmaxl.c>
