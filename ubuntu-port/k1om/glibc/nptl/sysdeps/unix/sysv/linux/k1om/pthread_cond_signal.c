/*
   K1OM cannot assemble the x86-64 optimized condition-variable signal path.
   Use eglibc's generic NPTL implementation.  The included upstream source is
   LGPL-2.1-or-later.
*/
#include <nptl/pthread_cond_signal.c>
