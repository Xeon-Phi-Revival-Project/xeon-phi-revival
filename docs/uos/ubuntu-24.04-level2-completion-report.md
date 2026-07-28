# Ubuntu 24.04 uOS Level 2 Completion Report

Public-safe package rebuild report. Downloaded source archives, build trees,
compiled objects, binaries, and raw logs remain local-only.

## Result

Level 2 is complete enough to open Level 3.

The project now has multiple Ubuntu 24.04 Noble source-package rebuild attempts
against the K1OM MPSS 3.4.10 SDK:

- `zlib`: passed build and runtime smoke
- `ncurses`: passed build and simple runtime smoke
- `sqlite3`: source verified and patched, blocked by missing host `tclsh`
- `libffi`: source verified and patched, blocked by host Autoconf being older
  than the package requires

This satisfies the Level 2 research goal narrowly: selected Ubuntu 24.04 source
packages can be cross-built for K1OM and run on the card. It does not mean the
Ubuntu package archive can be rebuilt wholesale.

## Passing Package Proofs

### zlib

- Source package: `zlib`
- Ubuntu suite: Noble / Ubuntu 24.04 LTS
- Version: `1:1.3.dfsg-3.1ubuntu2`
- Runtime result: `zlib version=1.3 result=knc zlib smoke`
- Status: passed

### ncurses

- Source package: `ncurses`
- Ubuntu suite: Noble / Ubuntu 24.04 LTS
- Version: `6.4+20240113-1ubuntu2.1`
- Runtime result: `ncurses version=ncurses 6.4.20240113`
- Status: passed for simple library API

The first `setupterm("xterm")` runtime attempt segfaulted. A narrower
`curses_version()` test passed. Treat terminfo setup as a separate runtime issue
before claiming full curses behavior.

Downloaded files and SHA256 values:

| File | SHA256 |
| --- | --- |
| `ncurses_6.4+20240113-1ubuntu2.1.dsc` | `87d71c553da108e83c4985e0bca8b944db2dd7931105e511a61e77faf1b415b7` |
| `ncurses_6.4+20240113.orig.tar.gz` | `37a12a0f8ae2605012c9a164dd286b0cfa02b51b5055836d09eb3d597fc351b1` |
| `ncurses_6.4+20240113.orig.tar.gz.asc` | `b70cfa4f155f61dfa7c085ad1e3f90c73132ad198764d7793a44cd7fdca51f1b` |
| `ncurses_6.4+20240113-1ubuntu2.1.debian.tar.xz` | `5d86811c8c9c3fab79c9d644a00ee31b4113b969d32b0bb05b5d3e7c2bcea9ac` |

## Blocked Package Attempts

### sqlite3

- Source package: `sqlite3`
- Ubuntu suite: Noble / Ubuntu 24.04 LTS
- Version: `3.45.1-1ubuntu2.7`
- Source verification: passed
- Debian patch application: passed
- Blocker: the source-package build needs `tclsh` to generate SQLite build
  artifacts; the current CentOS MPSS host does not provide it.

Downloaded files and SHA256 values:

| File | SHA256 |
| --- | --- |
| `sqlite3_3.45.1-1ubuntu2.7.dsc` | `2e6909bc4316d52ad471704a246f67c46bd50b4edc8956fa75b5cc0e057819de` |
| `sqlite3_3.45.1.orig.tar.xz` | `e32e817f7b4166a301f60b14a711871bfab7d35c1d7e29b585dfc479ae150aa4` |
| `sqlite3_3.45.1.orig-www.tar.xz` | `79b60798195a024d447e661e5bbc1eb40af50387ebf840e6f581190cc02064b6` |
| `sqlite3_3.45.1-1ubuntu2.7.debian.tar.xz` | `65e98fe518e9b1b89e90f8028d09d64c3786664b3dcc878a393ab82f7a770108` |

### libffi

- Source package: `libffi`
- Ubuntu suite: Noble / Ubuntu 24.04 LTS
- Version: `3.4.6-1build1`
- Source verification: passed
- Debian patch application: passed
- Blocker: `autoreconf` fails because the package requires Autoconf 2.71 or
  newer; the current CentOS MPSS host has an older Autoconf.

Downloaded files and SHA256 values:

| File | SHA256 |
| --- | --- |
| `libffi_3.4.6-1build1.dsc` | `a7a2c320c04149192a6dd78df8be28b2b27fd38e48d76f2ee6ba0c19ae0758f6` |
| `libffi_3.4.6.orig.tar.gz` | `9ac790464c1eb2f5ab5809e978a1683e9393131aede72d1b0a0703771d3c6cda` |
| `libffi_3.4.6-1build1.debian.tar.xz` | `9d8712818b833baf002a2413552194b8770800cb20b802ba1d3714156eba14fe` |

## Level 3 Gate

Level 3 is open because:

- K1OM source-package rebuilds are no longer theoretical.
- At least two selected Ubuntu 24.04 packages built far enough to run K1OM
  smoke binaries on `mic0`.
- Remaining blockers are specific host-tool or runtime-integration issues, not
  a general proof that Ubuntu-source rebuilds are impossible.
