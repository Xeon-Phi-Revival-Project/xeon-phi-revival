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

/* The i386 x87 helper set already implements the required rounding context,
   but exposes the two no-SSE aliases only for long double.  K1OM has the
   same x87 control-word state, so expose those existing x87 helpers under
   the generic names instead of selecting x86-64 SSE code.  */
static __always_inline void
libc_fesetenv_387_ctx (struct rm_ctx *ctx)
{
  libc_fesetenv_387 (&ctx->env);
}
#define libc_fesetenv_ctx libc_fesetenv_387_ctx
#define libc_fesetenvf_ctx libc_fesetenv_387_ctx
#define libc_fesetenvl_ctx libc_fesetenv_387_ctx
#define libc_feholdsetround_ctx libc_feholdsetround_387_ctx

#include <sysdeps/generic/math_private.h>

#endif /* XPR_K1OM_MATH_PRIVATE_H */
