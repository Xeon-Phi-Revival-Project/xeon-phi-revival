# Xeon Phi Revival Glossary

## Source code

Plain: Human-written program text.
Technical: Text in a programming language that must be compiled or interpreted.
Xeon Phi role: `tests/native/hello-libc.c` is source code.
Example: `puts("hello from k1om libc");`

## Machine code

Plain: Instructions the processor can execute directly.
Technical: Encoded ISA instructions stored in an executable section.
Xeon Phi role: K1OM machine code runs on the 5110P cores.
Example: `/bin/busybox` contains K1OM machine code.

## Binary

Plain: A compiled file rather than plain source.
Technical: Any file containing non-text encoded data, often executable code.
Xeon Phi role: uOS libraries and programs are binaries.
Example: `/lib64/libc-2.14.1.so`.

## Object file

Plain: A half-built compiled file.
Technical: Relocatable ELF containing code/data before final linking.
Xeon Phi role: kernel modules are relocatable K1OM objects.
Example: files ending in `.ko` report ELF type `REL`.

## Executable

Plain: A program you can run.
Technical: ELF type `EXEC` or sometimes `DYN` with an entry point.
Xeon Phi role: `/bin/bash` and `/bin/busybox` run on the card.
Example: `/bin/busybox` is `EXEC`.

## Library

Plain: Shared code used by programs.
Technical: Static archive or shared object supplying symbols to other code.
Xeon Phi role: K1OM programs need K1OM libraries.
Example: `libc.so.6`.

## Static linking

Plain: Put needed library code into the program file.
Technical: Link object code from archives into one executable.
Xeon Phi role: May reduce runtime dependencies for early tests.
Example: future `icc -mmic -static`.

## Dynamic linking

Plain: Load libraries when the program starts.
Technical: ELF interpreter maps shared objects named in `DT_NEEDED`.
Xeon Phi role: stock uOS programs use `/lib64/ld-linux-k1om.so.2`.
Example: BusyBox needs `libc.so.6`.

## Dynamic loader

Plain: The program that loads a dynamic program's libraries.
Technical: ELF interpreter from the `PT_INTERP` program header.
Xeon Phi role: Required for normal dynamically linked K1OM binaries.
Example: `/lib64/ld-linux-k1om.so.2`.

## Compiler

Plain: Turns source code into lower-level code.
Technical: Translates a language into assembly or object code for a target.
Xeon Phi role: The MPSS SDK `k1om-mpss-linux-gcc` now builds native 5110P
smoke tests; Intel `icc -mmic` remains a historical reference lane.
Example: `k1om-mpss-linux-gcc`.

## Assembler

Plain: Turns assembly text into object files.
Technical: Encodes assembly mnemonics into relocatable machine code.
Xeon Phi role: Needed for freestanding K1OM bootstrap and zmm instruction tests.
Example: `k1om-mpss-linux-as`; use `k1om-mpss-linux-gcc -c` for `.S` tests
unless validating assembler target flags directly.

## Linker

Plain: Combines object files into a runnable program.
Technical: Resolves symbols, lays out sections, writes final ELF.
Xeon Phi role: Must emit K1OM ELF and correct interpreter.
Example: `k1om-mpss-linux-ld`.

## ABI

Plain: Rules for binaries to work together.
Technical: Calling convention, ELF format, linker paths, types, TLS, symbols,
and runtime conventions.
Xeon Phi role: K1OM ABI differs from ordinary x86-64.
Example: `e_machine = 181`.

## API

Plain: Rules source code uses to call software.
Technical: Functions, types, headers, and behavior exposed to programmers.
Xeon Phi role: POSIX APIs exist in the uOS through glibc and BusyBox.
Example: `pthread_create`.

## ISA

Plain: The processor's instruction language.
Technical: Instruction set architecture.
Xeon Phi role: Knights Corner uses K1OM plus IMCI vector instructions.
Example: IMCI vector operations.

## Kernel

Plain: Core of the operating system.
Technical: Privileged program managing memory, processes, devices, syscalls.
Xeon Phi role: card runs Linux `2.6.38.8+mpss3.4.10`.
Example: `uname -a` on `mic0`.

## Driver

Plain: Software that controls hardware.
Technical: Kernel component exposing device functions to the OS.
Xeon Phi role: host `mic` driver boots and communicates with the card.
Example: `Kernel driver in use: mic`.

## Firmware

Plain: Low-level software stored on hardware.
Technical: Persistent device control code outside the host OS.
Xeon Phi role: SMC and flash versions are reported by `micinfo`.
Example: SMC firmware `1.15.4830`.

## Bootloader

Plain: Early code that starts the system.
Technical: Code that initializes hardware and loads a kernel or next stage.
Xeon Phi role: card has SMC bootloader and firmware boot stages.
Example: SMC boot loader `1.8.4326`.

## Initramfs

Plain: Compressed early root filesystem.
Technical: Initial RAM filesystem unpacked at boot.
Xeon Phi role: stock uOS uses `initramfs-...cpio.gz`.
Example: 1,787 entries in stock MPSS 3.4.10 initramfs.

## Root filesystem

Plain: The file tree the OS starts from.
Technical: Filesystem mounted as `/`.
Xeon Phi role: card boot command uses `root=ramfs`.
Example: generated overlay under `/var/mpss/mic0`.

## System call

Plain: A request from a program to the kernel.
Technical: ABI boundary for OS services like read, write, mmap, clone.
Xeon Phi role: K1OM glibc wraps card Linux syscalls.
Example: `write` used by `puts`.

## Userspace

Plain: Normal programs outside the kernel.
Technical: Unprivileged process environment.
Xeon Phi role: BusyBox, SSH, and test programs run in userspace.
Example: `/bin/bash` on `mic0`.

## Kernel space

Plain: The privileged OS side.
Technical: Protected CPU mode/address space for kernel and drivers.
Xeon Phi role: K1OM `.ko` modules run there.
Example: `micscif.ko`.

## DMA

Plain: Hardware moving memory without CPU copying everything.
Technical: Direct memory access.
Xeon Phi role: MPSS VNET and SCIF use DMA-related paths.
Example: card command line includes `vnet=dma`.

## Interrupt

Plain: Hardware signal that needs attention.
Technical: Asynchronous event delivered to CPU/OS.
Xeon Phi role: host driver uses MSI/MSI-X for the card.
Example: `mic 0000:82:00.0: irq ... for MSI/MSI-X`.

## Cross-compiler

Plain: Compiler that builds for a different machine.
Technical: Build/host/target differ; output target is not the machine running
the compiler.
Xeon Phi role: CentOS x86-64 host needs a K1OM target compiler.
Example: `x86_64-k1om-linux-gcc`.

## Sysroot

Plain: A fake root folder used by a compiler.
Technical: Target headers, libraries, loader, and startup files for linking.
Xeon Phi role: needed to build K1OM libc programs.
Example: future local MPSS-derived sysroot.

## K1OM

Plain: Knights Corner's binary architecture.
Technical: Intel Xeon Phi coprocessor ELF/ABI architecture, not normal x86-64.
Xeon Phi role: target architecture for 5110P native programs.
Example: `file format elf64-k1om`.

## IMCI

Plain: Knights Corner's wide vector instruction set.
Technical: Initial Many Core Instructions, 512-bit SIMD for KNC.
Xeon Phi role: performance code eventually uses IMCI.
Example: future vector smoke test.

## MPSS

Plain: Intel's software stack for Xeon Phi coprocessors.
Technical: Manycore Platform Software Stack: host driver, daemon, tools, boot
files, uOS integration.
Xeon Phi role: brings `mic0` online.
Example: MPSS 3.4.10.

## SCIF

Plain: Communication channel between host and card.
Technical: Symmetric Communications Interface.
Xeon Phi role: MPSS libraries and services communicate over SCIF.
Example: `libscif.so.0` in uOS dependencies.

## uOS

Plain: The small Linux environment running on the card.
Technical: Coprocessor user operating system image and root filesystem.
Xeon Phi role: runs SSH, BusyBox, libraries, and native programs on `mic0`.
Example: `2.6.38.8+mpss3.4.10`.
