/*
   K1OM needs the x87 fenv implementation but cannot use the x86-64 FPU
   header's SSE register moves for scalar float and double bit access.
   Keep the generic, representation-preserving union accessors instead.

   This is an XPR K1OM sysdeps selection header.  The included upstream
   headers retain their original licensing and notices.
*/
#ifndef XPR_K1OM_MATH_PRIVATE_H
#define XPR_K1OM_MATH_PRIVATE_H 1

#include <sysdeps/i386/fpu/fenv_private.h>
#include <sysdeps/generic/math_private.h>

#endif /* XPR_K1OM_MATH_PRIVATE_H */
