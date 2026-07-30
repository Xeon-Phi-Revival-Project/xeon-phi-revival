/* K1OM PLT trampolines for eglibc 2.19.
   Copyright (C) 2004-2014 Free Software Foundation, Inc.

   This file is part of the Xeon Phi Revival Project's eglibc port and is
   derived from eglibc's LGPL-2.1-or-later x86-64 trampoline.

   K1OM uses the x86-64 integer calling convention, but Knights Corner has
   ZMM registers instead of SSE/AVX XMM/YMM registers.  The normal resolver
   follows Intel MPSS glibc 2.14.1's observed register-save sequence.  The
   profiling entry currently resolves normally without LD_AUDIT frame
   instrumentation.
*/

#include <config.h>
#include <sysdep.h>
#include <link-defines.h>

	.text
	.globl _dl_runtime_resolve
	.type _dl_runtime_resolve, @function
	.align 16
	cfi_startproc
_dl_runtime_resolve:
	cfi_adjust_cfa_offset(16)
	subq $56, %rsp
	cfi_adjust_cfa_offset(56)
	movq %rax, 0(%rsp)
	movq %rcx, 8(%rsp)
	movq %rdx, 16(%rsp)
	movq %rsi, 24(%rsp)
	movq %rdi, 32(%rsp)
	movq %r8, 40(%rsp)
	movq %r9, 48(%rsp)
	movq 64(%rsp), %rsi
	movq 56(%rsp), %rdi
	call _dl_fixup
	movq %rax, %r11
	movq 48(%rsp), %r9
	movq 40(%rsp), %r8
	movq 32(%rsp), %rdi
	movq 24(%rsp), %rsi
	movq 16(%rsp), %rdx
	movq 8(%rsp), %rcx
	movq 0(%rsp), %rax
	addq $72, %rsp
	cfi_adjust_cfa_offset(-72)
	jmp *%r11
	cfi_endproc
	.size _dl_runtime_resolve, .-_dl_runtime_resolve

#ifndef PROF
	.globl _dl_runtime_profile
	.type _dl_runtime_profile, @function
	.align 16
	cfi_startproc
_dl_runtime_profile:
	jmp _dl_runtime_resolve
	cfi_endproc
	.size _dl_runtime_profile, .-_dl_runtime_profile
#endif

#ifdef SHARED
	.globl _dl_x86_64_save_sse
	.type _dl_x86_64_save_sse, @function
	.align 16
	cfi_startproc
_dl_x86_64_save_sse:
	vmovaps %zmm0, %fs:RTLD_SAVESPACE_SSE+0*64
	vmovaps %zmm1, %fs:RTLD_SAVESPACE_SSE+1*64
	vmovaps %zmm2, %fs:RTLD_SAVESPACE_SSE+2*64
	vmovaps %zmm3, %fs:RTLD_SAVESPACE_SSE+3*64
	vmovaps %zmm4, %fs:RTLD_SAVESPACE_SSE+4*64
	vmovaps %zmm5, %fs:RTLD_SAVESPACE_SSE+5*64
	vmovaps %zmm6, %fs:RTLD_SAVESPACE_SSE+6*64
	vmovaps %zmm7, %fs:RTLD_SAVESPACE_SSE+7*64
	ret
	cfi_endproc
	.size _dl_x86_64_save_sse, .-_dl_x86_64_save_sse

	.globl _dl_x86_64_restore_sse
	.type _dl_x86_64_restore_sse, @function
	.align 16
	cfi_startproc
_dl_x86_64_restore_sse:
	vmovaps %fs:RTLD_SAVESPACE_SSE+0*64, %zmm0
	vmovaps %fs:RTLD_SAVESPACE_SSE+1*64, %zmm1
	vmovaps %fs:RTLD_SAVESPACE_SSE+2*64, %zmm2
	vmovaps %fs:RTLD_SAVESPACE_SSE+3*64, %zmm3
	vmovaps %fs:RTLD_SAVESPACE_SSE+4*64, %zmm4
	vmovaps %fs:RTLD_SAVESPACE_SSE+5*64, %zmm5
	vmovaps %fs:RTLD_SAVESPACE_SSE+6*64, %zmm6
	vmovaps %fs:RTLD_SAVESPACE_SSE+7*64, %zmm7
	ret
	cfi_endproc
	.size _dl_x86_64_restore_sse, .-_dl_x86_64_restore_sse
#endif
