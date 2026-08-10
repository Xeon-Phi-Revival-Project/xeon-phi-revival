/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
   K1OM has no scalar SSE maxsd/ucomisd instructions.  Use eglibc's generic
   C fmax implementation instead of the x86-64 SSE assembly selection.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <math/s_fmax.c>
