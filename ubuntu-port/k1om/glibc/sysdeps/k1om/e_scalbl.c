/*
   K1OM lacks the later x87 fcomip instruction used by the x86-64 assembly
   implementation.  Select eglibc's generic C scalbl implementation, which
   delegates scaling to the K1OM-safe scalbnl path.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <math/e_scalbl.c>
