/* SPDX-License-Identifier: LGPL-2.1-or-later */
/*
   K1OM long double uses the x86-64 ABI's 80-bit extended representation
   stored in 16 bytes.  This is the eglibc 2.19 x86-64 implementation,
   retained verbatim except for this provenance note.

   Original authors: Joe Keane <jgk@jgk.org>; Andreas Jaeger.
   Source: eglibc 2.19, sysdeps/x86_64/fpu/s_finitel.S.
   License: LGPL-2.1-or-later (as part of GNU C Library/eglibc).
*/

#include <machine/asm.h>

ENTRY(__finitel)
	movl	16(%rsp), %eax
	orl	$0xffff8000, %eax
	incl	%eax
	shrl	$31, %eax
	ret
END(__finitel)
weak_alias(__finitel, finitel)
hidden_def(__finitel)
