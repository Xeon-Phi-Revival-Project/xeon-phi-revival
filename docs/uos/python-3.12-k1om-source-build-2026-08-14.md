# CPython 3.12.13 K1OM Source-Build Checkpoint

## Scope

This document is a historical pre-RC7 source-build checkpoint. At the time it
was recorded, it did not modify the frozen RC6 runtime or claim RC7 integration;
later RC7 records supersede that packaging status without changing this build
evidence.

## Inputs

- CPython `Python-3.12.13.tar.xz`, SHA-256
  `c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684`
- Source-built XPR GCC 5.1.1 KNC, KNC binutils, libgcc, EGLIBC, CRT, and Linux
  UAPI headers from the standalone toolkit reconstruction.
- No MPSS SDK compiler, CRT, sysroot, or binary input was used.

## Tracked K1OM Changes

`patches/python-3.12-k1om/0001-k1om-atomic-fence.patch` contains only:

- a K1OM sequential-fence implementation using `__sync_synchronize()` in
  place of unavailable `mfence`;
- a K1OM-only `PY_SSIZE_T_MAX` fallback for the EGLIBC header profile where
  `SSIZE_MAX` is not exported under CPython's C11 feature configuration.

The builder also gives cross-configure the explicit fact that K1OM EGLIBC has
no BSD `chflags(2)`, avoiding a false-positive compile failure.

## Core Build Result

`tools/python/build-python312-k1om.sh` built a host bootstrap Python 3.12.13,
then built the target core with `xpr-gcc`. The resulting target executable:

- SHA-256: `3112f3c1d0026fd8f9a4755010696f1e15b9a1ace1034c7d8d167dd8cf9d79c3`
- ELF machine: `Intel K1OM`
- interpreter: `/lib64/ld-linux-k1om.so.2`
- dependencies: `libpthread.so.0`, `libgcc_s.so.1`, and `libc.so.6`
- source-only package stage: 77 MiB, with no `/opt/mpss`, `mpss-sdk`, or
  private-workspace path found.

The initial core profile installs source `.py` files and deliberately omits
third-party extension-module lanes. Historical zlib, SQLite, OpenSSL, curses,
readline, and libffi/ctypes results remain experimental evidence, not part of
this new release-quality build.

## 5110P Core Validation

The initial failed attempt was a staging-command error, not a loader/runtime
defect: the minimal RC6 root provides the `tar` BusyBox applet but deliberately
does not install a `/bin/tar` link. The initial `tar -xzf` command therefore
never extracted the staged Python tree.

The bounded follow-up used the same final RC6 root without any runtime overlay:

- a fresh `examples/k1om/loader-probe.c` built by the current source-built
  toolkit executed and printed `XPR fresh loader probe PASS`;
- the exact Python executable transferred with matching SHA-256
  `3112f3c1d0026fd8f9a4755010696f1e15b9a1ace1034c7d8d167dd8cf9d79c3` and
  ran `--version` as `Python 3.12.13`;
- `busybox tar -xzf` extracted the complete source-built stage, after which
  `PYTHONHOME=/tmp/xpr-python312/usr` ran the core smoke and printed
  `Hello from Python on Xeon Phi`, Python `3.12.13`, and `k1om`.

The final RC6 loader, libc, and libgcc_s were recorded in the running root and
no historical/private runtime component was substituted. This validates the
source-built CPython core execution path. The later RC7 packaging work installs
the staged tree directly rather than relying on an unavailable `tar` command.

## RC7-Oriented Core Package

The clean rebuild under the canonical public source root `/usr/src` produced a
K1OM interpreter with SHA-256
`0c15380e4e00c0aeb3beddf48db5a16d2378014745aa352f8a90c2ab3049b0d3`.
The tracked build profile statically links CPython's essential `math` module;
the target build's `Modules/config.c` records `PyInit_math`.
`tools/python/package-python312-k1om-core.sh` strips only debug metadata from
the package copy, excludes the non-runtime CPython `test` and `idlelib` trees,
and writes sorted xz archives suitable for an RC7 integration candidate:

- `xpr-python-3.12.13-k1om-core.tar.gz`
  SHA-256 `7cfe57598fecf9263af84f5409a4c9f3f3e688b13d6ae784eaae79aba4e49d4a`
- `xpr-python-3.12.13-k1om-core-sources.tar.xz`
  SHA-256 `f35bdbb603651cf00da87283a2b2740e06d3a801b94330539939b3311f93ff1d`

The runtime archive deliberately uses deterministic gzip: RC6 BusyBox cannot
extract `.tar.xz`, but does support `busybox tar -xzf`. The package validator confirms `Machine: Intel K1OM`,
`PYTHON312_MPSS_BINARY_PAYLOAD=0`, and `PYTHON35_PAYLOAD=0`. The source bundle
contains the official CPython archive, the tracked K1OM patch, build/package
helpers, a source manifest, and the PSF license.

The exact gzip package was transferred to the final RC6 root with matching
host/card SHA-256 and extracted successfully using `busybox tar -xzf`.
`python3.12 --version` passed. The exact package smoke imported `sys`, `os`,
`pathlib`, `json`, `math`, `threading`, and `platform`, asserted
`platform.machine() == "k1om"`, and printed
`XPR Python core smoke PASS 3.12.13 k1om`. The card was immediately recovered
to the exact stock baseline.

## Recovery

`xpr-init --recover` passed. The stock `mic0.conf` SHA-256 was restored to
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.
That checkpoint recorded `k1om` over stock SSH; the current RC7 recovery
evidence records `/sbin/init.sysvinit` as stock PID 1.

## Status

`PYTHON312_CORE_SOURCE_BUILD=PASS`

`PYTHON312_5110P_CORE_EXECUTION=PASS`

`PYTHON312_CORE_PACKAGE=PASS`

`PYTHON312_CORE_SOURCE_ACCOUNTING=PASS`

`PYTHON312_CORE_PACKAGE_5110P=PASS`

`XPR_PYTHON312=RC7_READY`
