# CPython 3.12 K1OM Probe Report

Public-safe report for the first CPython 3.12 K1OM build probe.

## Status

Status: expanded runtime smoke passed.

The initial probe produced a dynamically linked `python` executable for
`Machine: Intel K1OM`. Follow-up work rebuilt that interpreter with a static
set of core extension modules, staged a trimmed Python 3.12 standard library in
a reversible MicDir overlay, booted `mic0`, ran Python 3.12.13 successfully on
the card, and restored stock uOS afterward.

This is now a working CPython 3.12 runtime profile for K1OM. It is not yet a
complete Ubuntu Python package set because optional modules such as `_ssl`,
readline, sqlite, `_ctypes`, bz2, and lzma still need their development headers
and libraries ported or supplied.

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

## Optional Module Gaps

The local trusted roots currently lack the development headers needed for these
standard optional modules:

```text
_ssl / _hashlib through OpenSSL headers
readline
sqlite3
_ctypes through a completed K1OM libffi build
bz2
lzma
```

K1OM ncurses headers and static libraries exist, but a static `_curses` attempt
generated a malformed CPython Makefile through `Modules/makesetup`; that needs
a separate build-system fix before it should be retried.

## Meaning

The modern Python lane now has a rollback-verified CPython 3.12 runtime on
`mic0`. The next step is to turn the private overlay recipe into project
package recipes:

- `python3.12-minimal-k1om`
- `python3.12-stdlib-k1om`
- `python3.12-sysconfig-k1om`
- `python3.12-smoke-k1om`

After packaging, the remaining work is normal Python-port expansion: OpenSSL,
sqlite, readline, ctypes/libffi, compression modules, and eventually a cleaner
K1OM SOABI/dynamic-extension story.
