/*
   K1OM has no TSX lock elision.  Select the generic NPTL mutex algorithm
   rather than the x86 wrapper, which unconditionally pulls in TSX helpers.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <nptl/pthread_mutex_lock.c>
