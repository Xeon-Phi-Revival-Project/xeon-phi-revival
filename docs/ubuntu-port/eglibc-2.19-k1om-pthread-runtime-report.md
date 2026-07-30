# Ubuntu-Source eglibc 2.19 K1OM pthread Runtime Report

Date: 2026-07-29

## Summary

The side-by-side Ubuntu-source eglibc 2.19 runtime probe now builds and runs on
the real Knights Corner uOS as K1OM ELF binaries.

This completes the immediate `libpthread` runtime boundary for the minimal
true-port lane:

- `ld-linux-k1om.so.2` is built as K1OM.
- `libc.so.6` is built as K1OM.
- `libpthread.so.0` is built as K1OM.
- `libm.so.6`, `libdl.so.2`, `librt.so.1`, and `libutil.so.1` are built as K1OM.
- A dynamically linked hello program ran on `mic0` and exited `0`.
- A dynamically linked pthread create/join smoke program ran on `mic0` and
  exited `0`.

The runtime was installed only under the project-owned side-by-side prefix:

```text
/opt/xeon-phi-revival/eglibc-2.19
```

The stock MPSS loader, stock uOS libraries, stock kernel, and firmware were not
replaced.

## Source Overlay

The working eglibc source overlay is tracked under:

```text
ubuntu-port/k1om/glibc/
```

The key K1OM-specific pieces are:

- `sysdeps/unix/sysv/linux/k1om/Makefile`: selects
  `ld-linux-k1om.so.2`.
- `sysdeps/unix/sysv/linux/k1om/dl-machine.h`: uses the x86-64 relocation
  implementation but makes the dynamic loader accept `EM_K1OM` / `181`.
- `nptl/sysdeps/unix/sysv/linux/k1om/elision-conf.h`: disables inherited
  x86 TSX lock-elision selection.
- `nptl/sysdeps/unix/sysv/linux/k1om/lowlevellock.h`: suppresses inherited
  x86 elision helper references and forces the plain futex wake path needed by
  pthread condition-variable code.

The `dl-machine.h` file is derived from LGPL glibc/eglibc source and keeps its
upstream license header. The repository MIT license applies to original project
files only.

## Build Result

Private build directory:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/ubuntu-eglibc-k1om-probe-20260729/build/eglibc-k1om-sysdeps-v21
```

Private staging directory:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/ubuntu-eglibc-k1om-probe-20260729/stage/eglibc-k1om-v21
```

Installed host-side prefix:

```text
/opt/xeon-phi-revival/eglibc-2.19
```

Verified runtime files:

```text
/opt/xeon-phi-revival/eglibc-2.19/lib/ld-linux-k1om.so.2
/opt/xeon-phi-revival/eglibc-2.19/lib/libc.so.6
/opt/xeon-phi-revival/eglibc-2.19/lib/libpthread.so.0
```

The loader reports:

```text
Machine: Intel K1OM
```

The smoke binaries request:

```text
/opt/xeon-phi-revival/eglibc-2.19/lib/ld-linux-k1om.so.2
```

## Live K1OM Validation

The first attempt to validate through nested SSH exposed a quoting issue: only
the first token was being sent to the card and later commands were accidentally
executing on the host. Validation was repeated with proper nested quoting before
recording the result.

Actual card identity:

```text
Linux unknownf48e38c1a578-mic0.home 2.6.38.8+mpss3.4.10 #1 SMP Thu Jan 12 16:38:30 EST 2017 k1om GNU/Linux
```

Smoke binaries:

```text
/tmp/xeon-phi-revival-eglibc-v21/eglibc-v21-hello:
  ELF 64-bit LSB executable, Intel Xeon Phi coprocessor (k1om), dynamically linked

/tmp/xeon-phi-revival-eglibc-v21/eglibc-v21-pthread:
  ELF 64-bit LSB executable, Intel Xeon Phi coprocessor (k1om), dynamically linked
```

Live output:

```text
eglibc-v21 hello pid=4901
HELLO_RC:0
eglibc-v21 pthread value=219 same=1
PTHREAD_RC:0
```

## MPSS Config Repair

During the ramfs refresh, `micctrl` refused to boot because
`/etc/mpss/mic0.conf` contained two stale metadata fields that this MPSS parser
reported as invalid:

```text
Family x100
MPSSVersion 3.x
```

A timestamped backup was created before changing the file:

```text
/etc/mpss/mic0.conf.bak-20260729-222845-before-remove-invalid-family-mpssversion
```

Only those invalid records and their comments were removed. After that,
`micctrl -b mic0` returned `mic0` to `online`.

## Current Boundary

This result is a major true-port milestone, but it is not yet a full Ubuntu
port. The libc/pthread stack is proven side-by-side and has now passed through
the reversible 36-package bootstrap gate. It has not replaced stock MPSS as a
permanent boot runtime, and the public repository still excludes private
runtime images and binaries with uncertain redistribution rights.

## Package Gate

The package builder was extended with an opt-in `--libc-root DIR` argument. With
`--libc-root /opt/xeon-phi-revival/eglibc-2.19`, the private package build
successfully produced the full 36-package bootstrap set and the determinism
check passed:

```text
status=passed
source_date_epoch=1704067200
package_count=36
checks=same_package_names,same_sha256
```

The generated `libc6-k1om` package contained `ld-2.19.so` and `libc-2.19.so`.
The generated `libpthread0-k1om` package contained `libpthread-2.19.so` and
`libpthread.so.0`.

A live MicDir boot gate was first attempted with those eglibc-backed packages.
It booted, exposed Ubuntu/K1OM identity, populated 36 dpkg status records, ran
APT metadata/update paths, and passed the basic OS/shell smoke. It did not pass
the full runtime/Python gate because the existing payload binaries were built
against the MPSS glibc ABI and expected symbol versions that the eglibc package
stack did not provide in the same way:

```text
symbol __libc_start_main, version GLIBC_2.14 not defined in file libc.so.6
libpthread.so.0: version `GLIBC_2.2.5' not found
libm.so.6: version `GLIBC_2.14' not found
```

Rollback restored the previous working project profile, which used the
MPSS-derived `libc-2.14.1.so` and `libpthread-2.14.1.so` package stack.

The payloads were then rebuilt/relinked against the eglibc loader/libc stack:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/payload-rootfs
/root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/python312-eglibc-root
/root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/libffi-eglibc-prefix/lib64
/root/xeon-phi-revival-local/ubuntu-port-runs/eglibc-payload-rebuild-20260730/runtime-root-stockpaths
```

The final live gate passed:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260730-050604

python3_default=3.12.13
python_default=3.12.13
python312_version_rc=0
python312_direct_rc=0
python312_rc=0
ctypes_ptr=8
ctypes_strlen=3
ctypes_callback=42
hello_loader_direct_rc=0
apt_update_rc=0
apt_install_rc=0
apt_runtime_install_rc=0
apt_python312_install_rc=0
hello_rc=0
python_rc=0
zlib_rc=0
ncurses_rc=0
libc_stack_rc=0
runtime_libs_rc=0
os_smoke_rc=0
PASS: bootstrap package set ran hello, python, and OS smoke then rolled back
```

Rollback verification returned stock SSH, confirmed the project profile and
stage2 log were absent, and reported `/proc/1/comm` as `init`. During rollback,
`micctrl --boot` printed `Boot failed - card state online`, but immediate
status and SSH checks showed `mic0` was online; this appears to be a benign
MPSS status message for this run.

Remaining cleanup for the Python 3.12 eglibc profile is packaging the optional
extension dependencies that were intentionally left outside this minimal gate:

```text
_bz2
_lzma
readline
_sqlite3
_curses
_ssl
_hashlib
```
