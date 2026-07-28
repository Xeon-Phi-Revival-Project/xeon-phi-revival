/*
 * Minimal freestanding K1OM _start experiment.
 *
 * This intentionally avoids libc and startup objects. It is not validated
 * until a K1OM assembler/linker exists and the resulting ELF is inspected.
 */
    .section .text
    .globl _start
    .type _start, @function
_start:
    mov $60, %rax
    mov $42, %rdi
    syscall
    hlt
