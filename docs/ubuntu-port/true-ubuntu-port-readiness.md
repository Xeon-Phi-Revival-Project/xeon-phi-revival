# True Ubuntu K1OM Port Readiness

Public-safe checkpoint before beginning a true Ubuntu architecture port for
Intel Xeon Phi Knights Corner / K1OM.

## Current Readiness

Status: ready to start architecture-port design, not ready to claim a true
Ubuntu port.

Latest package-manager checkpoint:

- Ubuntu Noble dpkg `1.22.6ubuntu6.6` runs natively on K1OM and completed a
  full 36-package isolated transaction.
- A native Ubuntu APT `1.0.1ubuntu2.24` compatibility bridge updated from the
  local archive and drove the same full transaction through real dpkg.
- Noble APT `2.8.3` requires C++17; MPSS K1OM GCC 4.7 only accepts
  `gnu++0x`.
- The active minimal package gate can now run against the Ubuntu-source eglibc
  2.19 loader/libc/pthread runtime after rebuilding the core payloads against
  that ABI.

The project now has enough verified ground to begin the real Ubuntu-port lane:

- K1OM toolchain installed and working on the MPSS host.
- Native K1OM binaries run on `mic0`.
- Ubuntu-source `zlib` and `ncurses` have been rebuilt/tested for K1OM.
- CPython 3.5.10 core userland runs on K1OM.
- A CPython 3.12.13 K1OM runtime now boots and runs on `mic0` as local
  `Architecture: k1om` packages with compression, sqlite, curses, OpenSSL,
  and complete libffi-backed `_ctypes` call/callback support.
- Project PID 1 handoff works.
- Project second-stage uOS profile works under stock MPSS init.
- Both the project dpkg/APT shim pair and side-by-side real Ubuntu dpkg/APT
  builds run on-card against the local K1OM archive.
- A project-owned MPSS-derived libc/runtime stack is split into standalone
  packages under `/opt/xeon-phi-revival/lib64`.
- Ubuntu-source eglibc 2.19 now builds side-by-side K1OM `ld.so`, `libc`,
  `libpthread`, `libm`, `libdl`, `librt`, and `libutil`; dynamic hello and
  pthread smoke binaries ran on real `k1om` uOS with exit code `0`.
- The eglibc stack is packaged deterministically through the local bootstrap
  builder, and the 36-package live gate now passes with eglibc-linked
  `hello-knc`, Python 3.12, zlib/ncurses smokes, `_ctypes`, package-manager
  checks, OS/filesystem checks, and verified stock rollback.
- Rollback to stock uOS is repeatable.

## Port Boundary

The next target should be called an Ubuntu K1OM architecture port only when it
has Ubuntu package metadata and reproducible package builds for a declared
architecture name.

The current working uOS profile is:

```text
stock MPSS uOS + project PID 1 preflight + stock init + second-stage project services
```

It is Ubuntu-compatible research infrastructure, not Ubuntu itself.

## Required Before Claiming True Ubuntu

Minimum claim line:

- Final architecture name decision, likely `k1om`.
- Debian/Ubuntu architecture tuple policy decision and working
  `dpkg-architecture` metadata fragments.
- Minimal Ubuntu-style archive layout with `dists/.../binary-k1om/Packages`,
  `Packages.gz`, and checksum metadata.
- Ubuntu-source base runtime packages for the core dynamic runtime:
  `libc6`, loader, `libgcc1`, `libm6`, `libpthread0`, `libdl2`, `librt1`,
  and `libutil1`.
- Real native K1OM `dpkg` installing the essential package set into a clean
  root or isolated target directory.
- Native K1OM APT updating from the local project archive and installing K1OM
  packages through real dpkg.
- Usable minimal command surface: `sh`, `ls`, `cat`, `python3`, `dpkg`,
  `dpkg-query`, `dpkg-deb`, `apt-get`, and `apt-cache`.
- Coherent root/profile identity with `/etc/os-release`, `/dev`, `/proc`,
  `/sys`, `/tmp`, package status metadata, and a repeatable stock MPSS rollback.
- Package tests for libc, zlib, ncurses, Python core, package-manager
  transactions, and basic shell tools.
- Public-safe build manifests that do not redistribute Intel MPSS payloads,
  extracted sysroots, firmware, private rootfs images, or binaries with unclear
  redistribution rights.
- Clear split between Ubuntu-source outputs and bring-your-own-MPSS material.

The project already satisfies much of the package-manager and userland surface.
The previous immediate runtime boundary, `libpthread`, now passes in the
side-by-side eglibc 2.19 probe and in the reversible package gate. The smallest
remaining technical gap before a minimal true-port claim is packaging the
remaining Python 3.12 optional extension dependencies and broadening the rootfs
service/filesystem surface without relying on stock MPSS runtime paths.

## Bare-Minimum Smoke Test

The first true-port candidate should pass this exact style of on-card smoke
before being described as a minimal Ubuntu K1OM port:

```bash
uname -a
cat /etc/os-release
dpkg --print-architecture
dpkg-query -W
apt-get update
apt-get install hello-knc-smoke
hello-knc
python3 -c "import ctypes, sqlite3, zlib; print('ubuntu-k1om-ok')"
```

Expected result:

```text
dpkg --print-architecture => k1om
hello-knc exits 0
python3 smoke exits 0
rollback to stock MPSS succeeds afterward
```

## Completed Bootstrap Archive Step

A first reproducible local package set now exists and has passed on `mic0`:

```text
apt-k1om
base-files-k1om
dpkg-k1om
hello-knc-smoke
libc6-k1om
libc-stack-smoke-k1om
libdl2-k1om
libffi8-k1om
libgcc1-k1om
libm6-k1om
libcrypto1.0.0-k1om
libncurses5-k1om
libpthread0-k1om
libreadline6-k1om
librt1-k1om
libssl1.0.0-k1om
libtinfo5-k1om
libutil1-k1om
ncurses-smoke-k1om
python3.5-minimal-k1om
python3.5-stdlib-k1om
python3.5-lib-dynload-k1om
python3.5-smoke-k1om
python3.12-minimal-k1om
python3.12-stdlib-k1om
python3.12-sysconfig-k1om
python3.12-smoke-k1om
xpr-shell-compat
xpr-busybox-compat
xpr-runtime-libs-smoke
zlib1g-k1om
zlib-smoke-k1om
xpr-pci-tools
xpr-os-smoke
xeon-phi-revival-stage2
```

The package set proves deterministic K1OM package construction, the local
`binary-k1om` archive path with `Packages` and `Packages.gz`, archive/package
audit path, simulated dpkg-style install/rootfs path with package `md5sums` and
`conffiles`, host-side APT parser path, MicDir install path, stock-init
second-stage service path, K1OM hello payload, CPython core payload, zlib smoke,
separate libtinfo runtime, split zlib/ncurses/readline/OpenSSL-1.0 runtime
packages, runtime-library presence smoke, ncurses smoke, basic filesystem smoke, on-card
dpkg-style package status metadata, `python3`/`python` shell entrypoints,
BusyBox-backed command entrypoints, a small `pcietool` sysfs helper,
bootstrap-compatible `dpkg`/`apt-get`/`apt-cache` commands, a separately
packaged libc stack, and stock rollback path.

## Immediate Next Track

Continue the `k1om` bootstrap repository:

```text
ubuntu-port/
  arch/
  bootstrap/
  packages/
  profiles/
  manifests/
```

Minimum first package targets:

```text
base-files-k1om
xeon-phi-revival-profile
dpkg-k1om
apt-k1om
libc6-k1om
libgcc1-k1om
libm6-k1om
libpthread0-k1om
libdl2-k1om
librt1-k1om
libutil1-k1om
zlib
ncurses
python3.5-minimal-k1om
python3.5-stdlib-k1om
python3.5-lib-dynload-k1om
python3.5-smoke-k1om
xpr-shell-compat
xpr-busybox-compat
xpr-pci-tools
xpr-os-smoke
xeon-phi-revival-stage2
```

The host-side APT parser test has passed for the bootstrap archive, and Python
has been split into more Ubuntu-like interpreter, standard-library,
dynamic-extension, and smoke-script packages under the same reversible gates.
The profile now also exposes basic command entrypoints through
`xpr-shell-compat` and `xpr-busybox-compat`, plus a first project-owned utility
package through `xpr-pci-tools`. The latest milestone expanded smoke payload
dependencies into standalone runtime/library packages and tightened
package-manager compatibility. The Python 3.12 lane has crossed from build
probe to packaged runtime profile, and now proves `bz2`, `lzma`, `readline`,
`sqlite3`, `curses`, and `curses.panel` inside the packaged smoke on `mic0`.
The Python dependency lane is now complete enough for the bootstrap target:
OpenSSL-backed `_ssl`/`_hashlib`, sqlite3, curses, terminfo, and libffi-backed
`_ctypes` calls/callbacks pass on-card in the MPSS-runtime package profile.
Real Ubuntu dpkg and a local-file APT bridge now pass too. The Ubuntu-source
eglibc 2.19 loader/libc/pthread runtime now passes direct on-card smokes,
deterministic package construction, and the 36-package live gate after the core
payloads were rebuilt against it. The next useful step is packaging the
remaining Python 3.12 optional extension dependencies for the eglibc profile
and modernizing the K1OM C++ toolchain enough to build Noble APT.
