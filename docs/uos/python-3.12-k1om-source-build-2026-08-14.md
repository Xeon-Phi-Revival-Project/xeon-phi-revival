# CPython 3.12.13 K1OM Source-Build Checkpoint

## Scope

This is the current source-accounted core CPython lane for a future XPR-OS
RC7. It does not modify the frozen RC6 runtime or claim an RC7 integration.

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
source-built CPython core execution path; future RC7 packaging must install
the staged tree directly rather than relying on an unavailable `tar` command.

## RC7-Oriented Core Package

The clean rebuild under the canonical public source root `/usr/src` produced a
K1OM interpreter with SHA-256
`d4347f6c6cfa7bb1cfae513f664b66f41c94864ddd53542fb7f51571fcd0ba0a`.
`tools/python/package-python312-k1om-core.sh` strips only debug metadata from
the package copy, excludes the non-runtime CPython `test` and `idlelib` trees,
and writes sorted xz archives suitable for an RC7 integration candidate:

- `xpr-python-3.12.13-k1om-core.tar.xz`
  SHA-256 `3e1d202a75046063713389098f7125f824ad71f73fe3c6b22fab678f9080146d`
- `xpr-python-3.12.13-k1om-core-sources.tar.xz`
  SHA-256 `ac7c449c2d67e426de9d03c5cb13f9c3dd58c4c5e650805338198aec15d86c53`

The package validator confirms `Machine: Intel K1OM`,
`PYTHON312_MPSS_BINARY_PAYLOAD=0`, and `PYTHON35_PAYLOAD=0`. The source bundle
contains the official CPython archive, the tracked K1OM patch, build/package
helpers, a source manifest, and the PSF license.

The exact package was prepared for a repeat hardware smoke, but that one
bounded boot did not expose the final root after the automatic handoff despite
the host service reporting success. The card was immediately recovered to the
exact stock baseline. This does not invalidate the prior staged-core 5110P
execution evidence, but the final RC7 integration should rerun the exact
package smoke before release freeze.

## Recovery

`xpr-init --recover` passed. The stock `mic0.conf` SHA-256 was restored to
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`, and
stock `mic0` SSH returned `k1om` with `systemd` as PID 1.

## Status

`PYTHON312_CORE_SOURCE_BUILD=PASS`

`PYTHON312_5110P_CORE_EXECUTION=PASS`

`PYTHON312_CORE_PACKAGE=PASS`

`PYTHON312_CORE_SOURCE_ACCOUNTING=PASS`

`XPR_PYTHON312=CORE_RC7_READY_WITH_PACKAGE_SMOKE_PENDING`
