/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
   K1OM has the x87 floating-point environment but no scalar SSE divss.
   Reuse eglibc's x87 exception-raising implementation.
   The included upstream source is LGPL-2.1-or-later.
*/
#include <sysdeps/i386/fpu/fraiseexcpt.c>
