/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
   K1OM has no TSX lock elision.  The generic NPTL trylock path defaults to
   non-eliding low-level locks.  The included upstream source is LGPL-2.1-or-later.
*/
#include <nptl/pthread_mutex_trylock.c>
