/*
   K1OM has no scalar SSE minss/ucomiss instructions.  Use eglibc's generic
   C fminf implementation instead of the x86-64 SSE assembly selection.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <math/s_fminf.c>
