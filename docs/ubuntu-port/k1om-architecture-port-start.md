# K1OM Ubuntu Architecture Port Start

This document starts the true Ubuntu architecture-port lane for Intel Xeon Phi
Knights Corner / K1OM.

It does not claim that Ubuntu has been ported yet. It defines the first public
metadata, naming, and bootstrap boundaries needed to turn the working K1OM
userland experiments into a distro-port effort.

## Current Port Status

Status: started, not complete.

Evidence available before this lane started:

- stock MPSS K1OM uOS inventory
- K1OM GCC/binutils from MPSS SDK
- tiny rootfs chroot demo
- Ubuntu 24.04-source `zlib` rebuilt and run
- Ubuntu 24.04-source `ncurses` rebuilt and run for a simple API smoke
- CPython 3.5.10 K1OM interpreter running inside the demo rootfs
- CPython `math` and `zlib` imports working inside the demo rootfs

## Proposed Architecture Identity

Initial experimental values:

| Field | Proposed value | Notes |
| --- | --- | --- |
| Ubuntu/Debian architecture name | `k1om` | short port architecture name |
| GNU CPU | `k1om` | matches the observed target CPU family |
| GNU system | `linux-gnu` | userland is Linux/glibc |
| MPSS toolchain tuple | `k1om-mpss-linux-gnu` | observed MPSS SDK compiler identity |
| dynamic loader | `/lib64/ld-linux-k1om.so.2` | observed stock uOS loader |
| ELF machine | `181` / `EM_K1OM` | required binary identity |
| ABI | LP64 | observed `sizeof(void*)=8`, `sizeof(long)=8` |

Open question: whether a long-term Ubuntu port should use
`k1om-linux-gnu` as the distro tuple while mapping to the MPSS compiler tuple
internally, or expose `k1om-mpss-linux-gnu` directly. The practical bootstrap
will use the MPSS tuple until an independent toolchain exists.

## Porting Rules

- Do not use amd64 Ubuntu binaries in the target rootfs.
- Rebuild source packages for K1OM.
- Keep package provenance, patches, configure flags, and runtime outcomes.
- Keep Intel MPSS runtime files user-supplied and local-only.
- Treat glibc 2.14 and the stock MPSS kernel as hard compatibility constraints
  until proven otherwise.
- Keep the stock MPSS boot path reversible.

## Bootstrap Stages

Stage A: architecture metadata

- define architecture name
- define GNU tuple mapping
- define dpkg metadata overlay proposal
- define apt repository layout
- create package status matrix

Stage B: seed packages

- `zlib`
- `ncurses`
- CPython 3.5.10 bootstrap interpreter
- minimal rootfs package manifest

Stage C: blocked Python dependencies

- `sqlite3` after host `tclsh` issue is solved
- `libffi` after Autoconf 2.71+ issue is solved
- `_ctypes`, `_sqlite3`, `_curses` extension modules

Stage D: archive mechanics

- generate `Packages` metadata for locally built K1OM packages
- generate `Sources` metadata for source provenance
- generate unsigned local `Release` metadata
- document how a user supplies MPSS runtime payloads locally

Stage E: true port decision

The true port becomes credible only after dpkg/apt tooling can reason about
`k1om` packages and rebuild recipes are repeatable. Until then this is an
Ubuntu-derived K1OM userland, not a full Ubuntu port.
