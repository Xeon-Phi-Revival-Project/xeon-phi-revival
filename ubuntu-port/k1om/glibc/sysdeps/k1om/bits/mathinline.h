/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
   K1OM uses out-of-line x86-64 fpu helper objects for eglibc's internal
   long-double operations.  Do not import the x86 inline bodies here: they
   conflict with the x86-64 private helper definitions selected for K1OM.

   This file is an XPR K1OM sysdeps override.  It intentionally provides no
   public inline math implementation.
*/
#ifndef _MATH_H
# error "Never use <bits/mathinline.h> directly; include <math.h> instead."
#endif
