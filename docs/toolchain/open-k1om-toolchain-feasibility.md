# Open K1OM Toolchain Feasibility

This note is a first-pass feasibility map. It does not begin a compiler port.

## Local Findings

- Host binutils can inspect K1OM ELF files:
  - `readelf` reports `Intel K1OM`
  - `objdump` reports `elf64-k1om`
  - `/usr/include/bfd.h` includes `bfd_arch_k1om`
- Local MPSS RPM manifests include `mpss-sdk-k1om`, which appears to provide:
  - `k1om-mpss-linux-as`
  - `k1om-mpss-linux-ld`
  - `k1om-mpss-linux-gcc`
  - `k1om-mpss-linux-g++`
  - `k1om-mpss-linux-objdump`
  - a K1OM sysroot under `/opt/mpss/<version>/sysroots/k1om-mpss-linux`
- `mpss-sdk-k1om-3.4.10-1.x86_64` is now installed on the CentOS host.
- The working tool prefix is `k1om-mpss-linux-*`; the
  `x86_64-k1om-linux-*` aliases were not observed.
- The stock uOS has runtime libraries but appears to lack startup objects
  needed for normal libc-linked builds.
- `mpss-sdk-k1om` provides startup objects such as `crt1.o`, `crti.o`, and
  `crtn.o`.

## Source History Pointers

Binutils:

- GNU binutils is the right first upstream family to investigate because local
  BFD already knows `bfd_arch_k1om`.
- Sourceware binutils mailing-list history shows `elfedit` recognizing machine
  strings including `k1om`, and readelf logic references `EM_K1OM`.
- Official binutils project page: https://www.sourceware.org/binutils/

GCC:

- Public reports of working MPSS-era GCC identify target names such as
  `k1om-mpss-linux` and tools such as `x86_64-k1om-linux-gcc`.
- One reported MPSS GCC was based on GCC 4.7.0 and configured as a cross
  Canadian toolchain targeting `k1om-mpss-linux`.
- Modern GCC Xeon Phi notes usually concern Knights Landing/Knights Mill
  AVX-512 CPU targets, not Knights Corner K1OM. GCC 15 removes KNL/KNM options,
  which is separate from KNC/K1OM but shows upstream Xeon Phi support is aging.
- GCC 4.7 manuals: https://gcc.gnu.org/onlinedocs/4.7.0/

glibc:

- Stock uOS runtime reports glibc 2.14.1.
- A buildable sysroot likely needs matching headers, startup objects, and
  libraries from an MPSS SDK/compiler package, not only the running uOS image.
- Official glibc sources: https://www.sourceware.org/glibc/sources.html

Linux:

- Stock card kernel is `2.6.38.8+mpss3.4.10`.
- The MPSS kernel and modules are K1OM ELF relocatables in the stock uOS.
- Treat Linux work as uOS/rootfs research after userland and toolchain basics.

LLVM:

- No local LLVM K1OM toolchain was found.
- Do not assume AVX-512 or x86-64 LLVM targets can emit valid KNC/K1OM code.

musl:

- No local musl K1OM support was found.
- A musl port would require ABI, syscall, startup, TLS, and dynamic loader work.

## Smallest Plausible Open Bootstrap

Stage 1: K1OM-capable binutils

- Build or recover `as`, `ld`, `objdump`, and `readelf` for K1OM.
- Validate by assembling or linking the smallest relocatable object.
- Validate `file`/`readelf` reports K1OM, not ordinary x86-64.
- Historical K1OM binutils should be able to assemble and link a freestanding
  ELF without glibc if the target assembler/linker are present. This has now
  been validated with `tests/native/start-exit42.S`: the built ELF reported
  `e_machine = 181`, executed on `mic0`, and returned exit code `42`.
- In the MPSS 3.4.10 SDK, direct `k1om-mpss-linux-as` defaults can produce
  ordinary x86-64 objects for x86-looking assembly. Assemble `.S` tests through
  `k1om-mpss-linux-gcc -c` unless the exact assembler `-march=k1om` path is
  being tested.

Stage 2: Freestanding compiler

- Use a GCC 4.7-era or compatible source path if K1OM target support can be
  recovered.
- Disable libc assumptions at first.
- Produce a relocatable object and verify `e_machine = 181`.

Stage 3: Startup objects and sysroot

- Obtain or rebuild `crt1.o`, `crti.o`, `crtn.o`, headers, and linker scripts.
- Keep proprietary or user-provided sysroot contents local and ignored.

Stage 4: libc-linked program

- Link `hello-libc.c` dynamically against the stock-compatible runtime.
- Verify interpreter `/lib64/ld-linux-k1om.so.2`.
- Run only through the dry-run-safe execution harness.
- This has now been validated with `tests/native/hello-libc.c`: the built ELF
  reported `e_machine = 181`, requested `/lib64/ld-linux-k1om.so.2`, executed
  on `mic0`, printed `hello from k1om libc`, and returned exit code `0`.

Stage 5: BusyBox

- Rebuild a tiny BusyBox or BusyBox applet set only after normal C, libc, and
  pthread smoke tests pass.

## Current Recommendation

The safest next technical action is controlled smoke-test expansion using the
installed MPSS SDK: return-value probes, file I/O, pthreads, math, and small
vector-code tests. Intel Composer XE remains a historical reference lane, not a
blocker for first native execution.
