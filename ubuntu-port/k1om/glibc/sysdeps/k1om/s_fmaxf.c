/*
   K1OM has no scalar SSE maxss/ucomiss instructions.  Use eglibc's generic
   C fmaxf implementation instead of the x86-64 SSE assembly selection.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <math/s_fmaxf.c>
