/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
   K1OM has no TSX lock elision.  Select the generic NPTL timedlock path.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <nptl/pthread_mutex_timedlock.c>
