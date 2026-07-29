# True Ubuntu K1OM Port Readiness

Public-safe checkpoint before beginning a true Ubuntu architecture port for
Intel Xeon Phi Knights Corner / K1OM.

## Current Readiness

Status: ready to start architecture-port design, not ready to claim a true
Ubuntu port.

The project now has enough verified ground to begin the real Ubuntu-port lane:

- K1OM toolchain installed and working on the MPSS host.
- Native K1OM binaries run on `mic0`.
- Ubuntu-source `zlib` and `ncurses` have been rebuilt/tested for K1OM.
- CPython 3.5.10 core userland runs on K1OM.
- A CPython 3.12.13 K1OM runtime now boots and runs on `mic0` as local
  `Architecture: k1om` packages with an expanded static module set and zlib.
- Project PID 1 handoff works.
- Project second-stage uOS profile works under stock MPSS init.
- A project-owned dpkg/APT shim pair runs on-card against the local K1OM
  archive, including update and reinstall smoke tests.
- A project-owned libc/runtime stack is split into standalone packages under
  `/opt/xeon-phi-revival/lib64`.
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

- Final architecture name decision, likely `k1om`.
- Debian/Ubuntu architecture tuple policy decision.
- `dpkg-architecture` metadata fragments.
- Minimal package archive layout.
- Reproducible bootstrap package set.
- Public-safe build manifests that do not redistribute Intel MPSS payloads.
- Clear split between Ubuntu-source outputs and bring-your-own-MPSS runtime
  material.
- Package tests for libc, zlib, ncurses, Python core, and basic shell tools.
- A project uOS profile package format that can install into the MicDir overlay
  or an equivalent generated rootfs without touching stock base images.

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
probe to packaged runtime profile; the next useful step is expanding missing
optional modules through real Ubuntu-source dependency ports.
