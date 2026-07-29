# K1OM libffi and CPython ctypes Report

Status: passed on Intel Xeon Phi 5110P.

## Result

Ubuntu Noble libffi 3.4.6 was adapted to K1OM and rebuilt with the MPSS
3.4.10 cross-toolchain. The resulting static and shared libraries report:

```text
ELF64
Machine: Intel K1OM
SONAME: libffi.so.8
```

The public repository tracks only the patch, build recipe, and original smoke
source. It does not redistribute MPSS, the Intel sysroot, generated binaries,
or private rootfs contents.

## Backend Changes

The backend retains libffi's Unix64 ABI classification and replaces unsupported
XMM/SSE scalar moves with K1OM IMCI zmm broadcast and masked pack-store
instructions. K1OM return-dispatch slots are widened to fit those instruction
sequences.

The dynamic closure trampoline also removes the hardcoded CET `endbr64`
instruction. Knights Corner predates CET; four one-byte NOPs preserve the
trampoline's layout and RIP-relative offsets.

## Reproducible Build

Tracked inputs:

```text
ubuntu-port/k1om/patches/libffi-3.4.6-k1om.patch
tools/ubuntu-port/build-libffi-k1om.sh
tests/k1om/ffi-k1om-smoke.c
```

Verified private build:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/libffi-k1om-repro-20260729-185225
```

The CentOS MPSS host has Autoconf 2.69 while libffi 3.4.6 requires 2.71 to
regenerate `configure`. The verified run therefore used a clean source copy
with an already generated upstream configure artifact, restored the two
modified source files to their Ubuntu versions, and applied the tracked patch.

## Standalone Card Test

The freshly rebuilt acceptance binary passed on `mic0`:

```text
sum8=36
double=3.75
float=3.75
strlen=11
pair=20,10
closure=16
k1om_libffi_smoke_ok
```

This covers register and stack integer arguments, float/double arguments and
returns, pointers, a two-word aggregate, and the callback/closure direction.

## Python 3.12

CPython 3.12.13 was statically linked with the adapted libffi backend. Direct
on-card checks passed:

```text
python=3.12.13
getpid=<positive pid>
strlen=11
abs=42
ctypes_ordinary_calls=PASS
callback=42
ctypes_callback=PASS
```

The package smoke then made ctypes mandatory and recorded:

```text
ctypes_ptr=8
ctypes_strlen=3
ctypes_callback=42
```

The 36-package profile includes `libffi8-k1om`. A deterministic
`xpr-shell-compat` correction makes both `python3` and `python` select
Python 3.12.13. A final live check returned `ctypes_strlen=11`, callback result
`511`, and `python3_full_ctypes=PASS`.

## Meaning

`_ctypes` is no longer a Python completeness blocker for the bootstrap port.
The next distribution blockers are real Ubuntu dpkg/APT builds, a modern libc
strategy compatible with the kernel lane, and broader source-package rebuilds.
