# Observed K1OM ELF And ABI Notes

This file separates observed facts from specification-derived statements and
untested assumptions.

## Observed From Stock uOS Binaries

- ELF class: ELF64.
- Endianness: little endian.
- ELF machine display name from host `readelf`: `Intel K1OM`.
- ELF `e_machine` numeric value observed from `/bin/busybox`: `181`.
- Host `objdump` reports file format: `elf64-k1om`.
- Host `objdump` reports architecture: `k1om`.
- Typical executable type: `EXEC (Executable file)`.
- Typical shared-library type: `DYN (Shared object file)`.
- Typical kernel module type: `REL (Relocatable file)`.
- Program interpreter for dynamically linked executables:
  `/lib64/ld-linux-k1om.so.2`.
- Most userland binaries are dynamically linked.
- ELF header size observed on `/bin/busybox`: 64 bytes.
- Program header entry size observed on `/bin/busybox`: 56 bytes.
- Section header entry size observed on `/bin/busybox`: 64 bytes.
- `/bin/busybox` entry point observed: `0x405d30`.
- `/bin/busybox` is stripped.
- 403 ELF files were inspected from the stock initramfs:
  - 402 report `Intel K1OM`
  - 1 reports `Intel 80386`
- The single `Intel 80386` ELF is
  `/usr/local/lib/kexec-tools/kexec_test`.
  - ELF32, little-endian, statically linked, unstripped.
  - SHA-256:
    `9c9f986016566044ce4d0ee37c329ef14ba334fdb0572de3947b24e8e3cb9f3e`
  - Likely purpose: a `kexec-tools` test/helper artifact carried in the uOS
    image, not a normal MIC userspace program. This is an inference from path,
    name, ELF type, and package context; it has not been executed.
- 234 ELF files request `/lib64/ld-linux-k1om.so.2`.
- 169 ELF files have no requested interpreter, mostly shared objects and
  relocatable kernel modules.

## Observed Runtime ABI Surface

- Dynamic loader symlink:
  `/lib64/ld-linux-k1om.so.2 -> ld-2.14.1.so`
- C library symlink:
  `/lib64/libc.so.6 -> libc-2.14.1.so`
- Present runtime libraries include:
  - `libc.so.6`
  - `libgcc_s.so.1`
  - `libpthread.so.0`
  - `libm.so.6`
  - `libdl.so.2`
- Missing link-time startup objects in the stock initramfs:
  - `crt1.o`
  - `crti.o`
  - `crtn.o`
- This suggests the stock uOS image is runtime-capable but not a complete
  development sysroot by itself.

## Symbol Versions Observed

Examples:

- BusyBox: `GLIBC_2.14`
- glibc loader: `GLIBC_2.14`, `GLIBC_PRIVATE`
- `libpthread`: `GLIBC_2.11`, `GLIBC_2.12`, `GLIBC_2.14`, older compatibility
  versions, and `GLIBC_PRIVATE`
- `libgcc_s`: GCC symbol versions from `GCC_3.0` through at least `GCC_4.3.0`,
  plus `GLIBC_2.14`

## Specification-Derived Statements

- The K1OM psABI names `/lib64/ld-linux-k1om.so.2` as the expected dynamic
  linker path.
- K1OM must be treated as a distinct ABI target, not as ordinary x86-64.
- Generic x86-64 binaries must not be considered valid for the card merely
  because they are ELF64.

## Assumptions Requiring Testing

- Page alignment requirements for normal user executables need direct linker
  output validation once a compiler/linker exists.
- Startup convention details need inspection of `crt1.o`, `crti.o`, and
  `crtn.o` from a real K1OM sysroot or compiler package.
- Startup convention details are now testable from the installed
  `mpss-sdk-k1om` sysroot.

## Tool Behavior

- CentOS host `file` identifies K1OM ELF files.
- CentOS host `readelf` identifies K1OM ELF headers.
- CentOS host `objdump` identifies `elf64-k1om`.
- Installed MPSS SDK tools use the `k1om-mpss-linux-*` prefix.
- `k1om-mpss-linux-gcc -c tests/native/start-exit42.S` produced a relocatable
  `Intel K1OM` object.
- `k1om-mpss-linux-ld -nostdlib -e _start` linked a statically linked K1OM ELF
  that executed on `mic0` and returned `42`.
- `k1om-mpss-linux-gcc` linked a dynamically linked libc K1OM ELF requesting
  `/lib64/ld-linux-k1om.so.2`; it executed on `mic0`, printed
  `hello from k1om libc`, and returned `0`.
- Direct `k1om-mpss-linux-as` produced an ordinary x86-64 object for the first
  x86-looking assembly test. Use the GCC driver for `.S` assembly unless the
  experiment is specifically validating assembler target flags.
