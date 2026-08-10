/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
   K1OM uses the generic atomic spinlock algorithm rather than the x86-64
   assembly implementation, which contains unsupported conditional moves.
   The included upstream source is LGPL-2.1-or-later.
*/
#define SPIN_LOCK_READS_BETWEEN_CMPXCHG 1000
#include <nptl/pthread_spin_lock.c>
