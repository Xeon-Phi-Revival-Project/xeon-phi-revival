# CPython 3.12 K1OM Probe Report

Public-safe report for the first CPython 3.12 K1OM build probe.

## Status

Status: partial.

The probe produced a dynamically linked `python` executable for `Machine:
Intel K1OM`, but the staged MicDir boot tests did not produce a working on-card
Python 3.12 userland. Treat this as source-compatibility progress, not as a
completed Python 3.12 port.

## Source

The probe used the official Python 3.12.13 source release:

```text
Python-3.12.13.tar.xz
release date: 2026-03-03
sha256: c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684
```

Public source references:

- https://www.python.org/downloads/release/python-31213/
- https://www.python.org/ftp/python/3.12.13/

No Python source archive or generated binary is committed.

## Private Work Directory

```text
/root/xeon-phi-revival-local/ubuntu2404-level3/cpython-3.12.13-probe-20260729-001250
```

## Build Findings

The host build Python succeeded:

```text
Python 3.12.13
```

The K1OM cross configure initially failed on IPv6/getaddrinfo detection. The
configure step passed after adding:

```text
--disable-ipv6
```

The K1OM GCC frontend rejected CPython 3.12's default C mode:

```text
k1om-mpss-linux-gcc: error: unrecognized command line option '-std=c11'
```

The compiler accepted `-std=gnu1x`, so the private generated Makefile was
patched for the probe.

The build then exposed old-compiler C11 compatibility gaps:

```text
static_assert -> _Static_assert
_Alignof -> __alignof__
```

The next architecture-specific blocker was CPython's x86 atomic fallback,
which emitted `mfence`. The K1OM assembler rejected that instruction:

```text
Error: `mfence' is not supported on `k1om'
```

A tiny compiler probe showed `__sync_synchronize()` compiles for K1OM and emits
a supported locked operation. The private build tree patched
`_Py_atomic_thread_fence()` to call `__sync_synchronize()` instead of inline
`mfence`.

## Build Result

After those private probe patches:

```text
python: ELF 64-bit LSB executable, version 1 (SYSV), dynamically linked
Machine: Intel K1OM
```

## Live Test Result

Two reversible MicDir staging attempts were made:

1. Full Python executable plus `Lib` standard-library tree.
2. Smaller binary-only version check.

Both attempts were rolled back. The full-tree path did not return a useful
Python 3.12 SSH result before timeout. The smaller binary-only path left
`mic0` in `ready` during the staged boot attempt. Stock MPSS/uOS was restored
afterward.

Final stock verification after cleanup:

```text
stock_ssh_ok
python312_bin_absent
python312_opt_absent
dpkg_status_absent
init
```

## Meaning

The modern Python lane now has a concrete compiler/source patch list and an
`EM_K1OM` executable. The next step is not more blind boot attempts; it is a
smaller reproducible Python 3.12 packaging harness that separates:

- interpreter binary startup;
- minimum `PYTHONHOME`/encoding files;
- dynamic extension loading;
- packaged libc/library path;
- MicDir image size and boot timing;
- rollback verification.

Until that harness passes, CPython 3.5 remains the working on-card Python
baseline and CPython 3.12 remains a build probe.
