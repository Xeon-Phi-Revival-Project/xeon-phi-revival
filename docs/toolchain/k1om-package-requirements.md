# K1OM Package Requirements

This document records package metadata findings only. It does not authorize
installing proprietary packages, accepting licenses, or publishing Intel-owned
payloads.

## Evidence Sources

- Installed RPM database on the CentOS 7.4 MPSS host.
- Local MPSS 3.4.10 and 3.6.1 RPM manifests, inspected with `rpm -qip` and
  `rpm -qlp`.
- Public-safe stock uOS ELF inventory under `artifacts/public/`.

## Current Installed State

Installed MPSS packages are enough for host/card bring-up, booting, management,
runtime inventory, and first K1OM native program builds after installing the
MPSS K1OM SDK.

Installed MPSS-related packages observed:

- `glibc2.12pkg-libmicmgmt0-3.4.10-1.glibc2.12.x86_64`
- `glibc2.12pkg-mpss-flash-3.4.10-1.glibc2.12.x86_64`
- `glibc2.12pkg-mpss-rasmm-kernel-3.4.10-1.glibc2.12.x86_64`
- `mpss-boot-files-3.4.10-1.glibc2.12.x86_64`
- `mpss-core-3.4.10-1.glibc2.12.x86_64`
- `mpss-daemon-3.4.10-1.glibc2.12.x86_64`
- `mpss-micmgmt-3.4.10-1.glibc2.12.x86_64`
- `mpss-modules-3.10.0-693.el7.x86_64-3.4.10-1.x86_64`
- `mpss-myo-3.4.10-1.glibc2.12.x86_64`
- `mpss-sdk-k1om-3.4.10-1.x86_64`

Observed missing Intel Composer / alternate-prefix commands:

- `icc`
- `icpc`
- `x86_64-k1om-linux-gcc`
- `x86_64-k1om-linux-g++`
- `x86_64-k1om-linux-as`
- `x86_64-k1om-linux-ld`
- `x86_64-k1om-linux-objdump`
- `x86_64-k1om-linux-readelf`

Observed working MPSS SDK commands after sourcing
`/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux`:

- `k1om-mpss-linux-gcc`
- `k1om-mpss-linux-g++`
- `k1om-mpss-linux-as`
- `k1om-mpss-linux-ld`
- `k1om-mpss-linux-objdump`
- `k1om-mpss-linux-readelf`

## Exact Package Candidates

The local MPSS archives contain these relevant packages:

- `mpss-sdk-k1om-3.4.10-1.x86_64.rpm`
- `intel-composerxe-compat-k1om-3.4.10-1.x86_64.rpm`
- `mpss-sdk-k1om-3.6.1-1.x86_64.rpm`
- `intel-composerxe-compat-k1om-3.6.1-1.x86_64.rpm`

`mpss-sdk-k1om-3.4.10-1.x86_64` was installed and validated as the narrowest
observed dependency for a GCC/binutils-style K1OM build path.

## Compiler

Required:

- `k1om-mpss-linux-gcc`
- `k1om-mpss-linux-g++` for C++ tests

Observed provider:

- `mpss-sdk-k1om`

Observed manifest paths:

- `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux/k1om-mpss-linux-gcc`
- `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux/k1om-mpss-linux-g++`

Intel `icc -mmic` remains useful as a historical reference compiler, but no
installed `icc` or `icpc` was found.

## Assembler And Linker

Required:

- K1OM assembler
- K1OM linker
- K1OM `objdump` and `readelf` or equivalent inspection tools

Observed provider:

- `mpss-sdk-k1om`

Observed manifest paths:

- `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux/k1om-mpss-linux-as`
- `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux/k1om-mpss-linux-ld`
- `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux/k1om-mpss-linux-objdump`

## Headers

Required:

- libc headers
- Linux userspace headers
- K1OM/MIC-specific headers where needed
- C++ headers for later C++ work

Observed provider:

- `mpss-sdk-k1om`

Observed manifest paths:

- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/include`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/include/mic/micras.h`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/include/mic/micras_api.h`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/include/c++`

## Startup Objects

Required for normal libc-linked executables:

- `crt1.o`
- `crti.o`
- `crtn.o`

Observed provider:

- `mpss-sdk-k1om`

Observed manifest paths:

- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/crt1.o`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/crti.o`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/crtn.o`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/Scrt1.o`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/Mcrt1.o`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/gcrt1.o`

These were not present in the stock booted uOS initramfs inventory, which is
why the stock uOS alone is not a complete development sysroot.

## Runtime Libraries

Required for dynamically linked C smoke tests:

- `/lib64/ld-linux-k1om.so.2`
- `libc.so.6`
- `libgcc_s.so.1`
- `libpthread.so.0`
- `libm.so.6`
- `libdl.so.2`

Observed in stock uOS and in `mpss-sdk-k1om` sysroot manifests.

Observed manifest paths include:

- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/ld-linux-k1om.so.2`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/libc.so.6`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/libgcc_s.so.1`

## Optional Intel Runtimes

Optional later tracks may need:

- SCIF development/runtime packages such as `libscif-dev`
- COI packages such as `mpss-coi-dev`
- MYO packages such as `mpss-myo-dev`
- Offload packages such as `mpss-offload-dev`
- HStreams packages such as `mpss-hstreams-dev`
- MIC management development packages such as `glibc2.12pkg-libmicmgmt-dev`

These are not required for the first freestanding `_start` test or the first
basic libc `hello` test.

## Narrowest Next Dependency

The first compiler dependency is satisfied by
`mpss-sdk-k1om-3.4.10-1.x86_64`.

The narrowest next dependency is not another package yet. It is a controlled
test matrix that identifies which SDK/runtime pieces are needed for:

- return-value probes;
- file I/O;
- pthreads;
- math library calls;
- vector-code smoke tests.
