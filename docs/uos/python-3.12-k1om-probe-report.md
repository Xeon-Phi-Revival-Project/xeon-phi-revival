# CPython 3.12 K1OM Probe Report

Public-safe report for the first CPython 3.12 K1OM build probe.

## Status

Status: historical experimental package and ctypes smoke passed. It used a
private GCC 4.7-era build tree and is preserved as evidence, not as the current
RC7-ready build path. See [the source-built GCC 5.1.1 checkpoint]
(python-3.12-k1om-source-build-2026-08-14.md) for the current tracked lane.

The initial probe produced a dynamically linked `python` executable for
`Machine: Intel K1OM`. Follow-up work rebuilt that interpreter with a static
set of core extension modules, staged a trimmed Python 3.12 standard library in
a reversible MicDir overlay, booted `mic0`, ran Python 3.12.13 successfully on
the card, converted that runtime into K1OM `.deb` packages, tested them through
the local `binary-k1om` archive, and restored stock uOS afterward.

This is now a working packaged CPython 3.12 runtime profile for K1OM. It is not
yet an official Ubuntu Python package set, but the packaged smoke proves
compression, readline, sqlite, curses, OpenSSL, and real libffi-backed
`_ctypes` calls and callbacks on the card.

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

The follow-up runtime build statically enabled the useful no-external and
locally available modules that avoid the cross-build's bad dynamic extension
suffix:

```text
_asyncio
_contextvars
_csv
_lsprof
_opcode
_pickle
_queue
_random
_statistics
_zoneinfo
array
_bisect
_heapq
_json
_struct
math
cmath
_datetime
_decimal
binascii
pyexpat
_elementtree
_codecs_cn
_codecs_hk
_codecs_iso2022
_codecs_jp
_codecs_kr
_codecs_tw
_multibytecodec
unicodedata
fcntl
grp
mmap
_posixsubprocess
resource
select
_socket
termios
_multiprocessing
_md5
_sha1
_sha2
_sha3
_blake2
zlib
syslog
```

`zlib` was linked from the locally rebuilt Ubuntu 24.04 zlib source package.

## Early Live Test Result

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

## Expanded Live Test Result

The final expanded runtime test used:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/python312-static-expanded-sysconfig-overlay-20260729-031953
```

The overlay staged:

```text
/usr/bin/python3.12
/usr/bin/python3 -> python3.12
/opt/xeon-phi-revival/bin/python3.12
/opt/xeon-phi-revival/lib/python3.12
/opt/xeon-phi-revival/lib/python3.12/_sysconfigdata__linux_x86_64-linux-gnu.py
/opt/xeon-phi-revival/share/python312-smoke.py
```

The generated `_sysconfigdata` shim records K1OM-facing runtime values such as:

```text
SOABI=cpython-312-k1om-linux-gnu
EXT_SUFFIX=.cpython-312-k1om-linux-gnu.so
MULTIARCH=k1om-linux-gnu
TZPATH=/usr/share/zoneinfo:/usr/lib/zoneinfo:/usr/share/lib/zoneinfo:/etc/zoneinfo
```

Live `mic0` evidence:

```text
python312_expanded_sysconfig_ssh_ok
init
/usr/bin/python3.12
3.12.13 (main, Jul 29 2026, 03:15:12) [GCC 4.7.0 20110509 (experimental)]
pyver_rc=0
python312_expanded_sysconfig_smoke_ok
linux
k1om
knc-zlib
cpython-312-k1om-linux-gnu
pysmoke_rc=0
pyimports_rc=0
PASS python312 static expanded sysconfig overlay
```

The smoke imported and exercised:

```text
array
asyncio
binascii
contextvars
csv
datetime
decimal
hashlib
json
math
os
pathlib
pickle
queue
random
socket
statistics
struct
sys
sysconfig
threading
unicodedata
xml.etree.ElementTree
xml.parsers.expat
zlib
zoneinfo
```

Stock rollback was verified after the test:

```text
stock_ssh_ok
python312_absent
python312_bin_absent
python312_smoke_absent
init
```

## Packaged Runtime Result

The expanded runtime was then converted into four local K1OM packages:

```text
python3.12-minimal-k1om
python3.12-stdlib-k1om
python3.12-sysconfig-k1om
python3.12-smoke-k1om
```

The passing package-set run was:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525
```

Package hashes:

```text
python3.12-minimal-k1om b81642440a0527df52fa94bcae9141c1c05557112d21c3962284fb10c4b9be33
python3.12-stdlib-k1om 9849c3250f311bd66ac5f7033de88f5b875b1ec6c2ece0f0dc54725ae19b2569
python3.12-sysconfig-k1om e1d32c6d8c55f496f609b9356c293a1b6c34789a029eb52c920179760d43fe6a
python3.12-smoke-k1om 6f7dddf602875f03ed999a97b64fc2b2766c26e4390c4ac56fabe5700f2a4db1
```

The 35-package archive passed deterministic build, package audit, simulated
install, MicDir boot, direct `python3.12` invocation, second-stage packaged
smoke, `apt-get install --reinstall python3.12-smoke-k1om`, and stock rollback.

Live evidence:

```text
dpkg_status_present
35
/usr/bin/python3.12
python312_version_rc=0
python312_package_smoke_ok
bz2=bz-ok
lzma=lzma-ok
readline=True
sqlite3=42:3.45.1
curses=2.2
curses_panel=True
curses_cols=80
curses_lines=24/25
ssl=OpenSSL 3.0.13 30 Jan 2024
hashlib_openssl=2d711642
ctypes=skipped
python312_direct_rc=0
python312_rc=0
apt_python312_install_rc=0
```

Independent final stock verification after rollback:

```text
stock_ssh_ok
profile_absent
stage2_log_absent
python312_absent
dpkg_status_absent
init
```

## Dependency Progress

The latest private dependency build used public source metadata and official
source archives:

```text
bzip2 1.0.8-5.1build0.1 -> _bz2 package smoke passed
xz-utils 5.6.1+really5.4.5-1ubuntu0.3 -> _lzma package smoke passed
readline 8.2-4build1 -> readline package smoke passed
sqlite 3.45.1 -> sqlite3 package smoke passed
ncurses 6.4+20240113-1ubuntu2.1 -> curses and curses.panel package smoke passed
OpenSSL 3.0.13 -> _ssl and OpenSSL-backed _hashlib package smoke passed
ncurses-base-k1om terminfo -> curses.setupterm("linux") package smoke passed
```

SQLite note: the Ubuntu `sqlite3_3.45.1-1ubuntu2.7` source metadata and patches
were inspected, but generating the amalgamation from the Ubuntu source tree
needed missing host `tclsh`. The passing K1OM build used SQLite's official
upstream autoconf amalgamation for the same upstream 3.45.1 release and disabled
SQLite compiler intrinsics that lowered to unavailable K1OM atomics.

## Optional Module Gaps

OpenSSL 3.0.13 was built privately for K1OM with the host Perl `IPC::Cmd`
gap worked around by a minimal local build-time stub. The rollback-verified
package run `k1om-bootstrap-package-set-20260729-174525` proved
`ssl=OpenSSL 3.0.13 30 Jan 2024` and
`hashlib_openssl=2d711642` on `mic0`.

The earlier `_ctypes` shim result above is superseded. A real K1OM libffi
backend now replaces unsupported XMM/SSE moves with IMCI zmm operations and
removes the unsupported CET instruction from closure trampolines. Standalone
calls and closures pass, as do packaged Python `ctypes.CDLL` calls and
`CFUNCTYPE` callbacks. See
`docs/ubuntu-port/k1om-libffi-ctypes-report.md`.

K1OM ncurses headers and static libraries now work for static `_curses` and
`_curses_panel` imports. The build-system trap was `Modules/makesetup` treating
`-DHAVE_TERM_H=1` as a Makefile variable assignment; using `-DHAVE_TERM_H`
without `=1`, plus a private `ncurses.h` include shim to the K1OM `curses.h`,
produced a working package-smoked build. Adding `ncurses-base-k1om` with the
`linux` terminfo entry allowed `curses.setupterm(term="linux")`,
`curses.tigetnum("cols")`, and `curses.tigetnum("lines")` to pass in the
Python 3.12 package smoke.

## Meaning

The modern Python lane now has a package-built CPython 3.12 runtime on `mic0`
with compression, readline, sqlite, curses, OpenSSL/TLS, and complete
libffi-backed ctypes call/callback support. Both `python3` and `python` select
3.12.13 in the active profile. Remaining Python work is packaging polish,
dynamic-extension naming, tests, and broader module coverage rather than a
known core runtime blocker.
