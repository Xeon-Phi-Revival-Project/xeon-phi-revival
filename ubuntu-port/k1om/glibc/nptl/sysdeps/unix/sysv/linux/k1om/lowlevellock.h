/* SPDX-License-Identifier: LGPL-2.1-or-later */
/* K1OM low-level lock overrides for eglibc 2.19.  */
#ifndef _K1OM_LOWLEVELLOCK_H
#define _K1OM_LOWLEVELLOCK_H 1

#include_next <lowlevellock.h>

/* The inherited x86-64 header declares TSX elision helper calls.  K1OM does
   not implement those instructions, so let the generic pthread sources use
   their non-elision fallbacks.  */
#undef lll_lock_elision
#undef lll_unlock_elision
#undef lll_trylock_elision
#undef lll_timedlock_elision

/* Force pthread_cond_signal.c to use the plain futex wake fallback.  */
#undef lll_futex_wake_unlock
#define lll_futex_wake_unlock(futexp, nr_wake, nr_wake2, futexp2, private) 1

#endif
