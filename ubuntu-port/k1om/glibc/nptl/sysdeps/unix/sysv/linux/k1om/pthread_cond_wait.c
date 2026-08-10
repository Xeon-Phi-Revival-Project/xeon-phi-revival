/*
   K1OM cannot assemble the x86-64 optimized condition-variable implementation
   because it uses conditional-move instructions.  Use eglibc's generic NPTL
   implementation instead.  The included upstream source is LGPL-2.1-or-later.
*/
#include <nptl/pthread_cond_wait.c>
