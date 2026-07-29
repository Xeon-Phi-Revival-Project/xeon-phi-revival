# K1OM Ubuntu Port Lab

This directory contains public-safe metadata and tooling for an experimental
Ubuntu architecture port targeting Intel Xeon Phi Knights Corner / K1OM.

This is not a finished Ubuntu port. It is the bootstrap lane for turning the
working K1OM userland experiments into reproducible package and archive
metadata.

## Architecture Sketch

- Architecture name: `k1om`
- Practical compiler tuple: `k1om-mpss-linux-gnu`
- Loader: `/lib64/ld-linux-k1om.so.2`
- ELF machine: `EM_K1OM` / `181`
- ABI: LP64

## Contents

- `dpkg/`: proposed dpkg architecture metadata overlays.
- `packages/`: public-safe source/control metadata for bootstrap packages.
- `repo-skeleton/`: local archive layout skeleton.
- `package-status.tsv`: source package status matrix.

No binary packages, MPSS files, sysroots, firmware, or uOS payloads belong here.

## First Working Bootstrap Package

The first working package-built profile is `xeon-phi-revival-profile`.

It is built locally from user-supplied K1OM payloads into a `.deb`-structured
archive with:

- `debian-binary`
- `control.tar.gz`
- `data.tar.gz`

The private build is indexed into a local unsigned Noble `binary-k1om` archive
and installed into MPSS MicDir staging for testing. The generated `.deb` is not
committed because it contains local K1OM binaries and Python payloads.

The passing run is documented in:

```text
docs/ubuntu-port/k1om-bootstrap-package-report.md
manifests/experiments/k1om-profile-package-bootstrap.yml
```

## First Working Package Set

The current multi-package bootstrap archive also passed. It contains:

- `base-files-k1om`
- `dpkg-k1om`
- `apt-k1om`
- `hello-knc-smoke`
- `libc6-k1om`
- `libgcc1-k1om`
- `libm6-k1om`
- `libpthread0-k1om`
- `libdl2-k1om`
- `librt1-k1om`
- `libutil1-k1om`
- `libc-stack-smoke-k1om`
- `zlib1g-k1om`
- `libncurses5-k1om`
- `libreadline6-k1om`
- `libcrypto1.0.0-k1om`
- `libffi8-k1om`
- `libssl1.0.0-k1om`
- `xpr-runtime-libs-smoke`
- `ncurses-base-k1om`
- `python3.12-minimal-k1om`
- `python3.12-stdlib-k1om`
- `python3.12-sysconfig-k1om`
- `python3.12-smoke-k1om`
- `libtinfo5-k1om`
- `ncurses-smoke-k1om`
- `python3.5-minimal-k1om`
- `python3.5-stdlib-k1om`
- `python3.5-lib-dynload-k1om`
- `python3.5-smoke-k1om`
- `xpr-shell-compat`
- `xpr-busybox-compat`
- `zlib-smoke-k1om`
- `xpr-pci-tools`
- `xpr-os-smoke`
- `xeon-phi-revival-stage2`

That package set now builds deterministically, is indexed into a local unsigned
Noble `binary-k1om` archive with `Packages`, `Packages.gz`, and `Release`
checksums, audited, simulated into a dpkg-style staged rootfs, installed into
MPSS MicDir staging, booted on `mic0`, runs `hello-knc`, runs CPython core,
is parsed by host-side APT as `Architecture: k1om`, runs zlib and ncurses
smoke payloads, uses a separately packaged `libtinfo5-k1om` runtime, verifies
basic filesystem and OS behavior, exposes dpkg-style package status metadata
on-card, provides bootstrap-compatible `dpkg`/`apt-get`/`apt-cache` commands,
adds `dpkg-query` and `dpkg-deb` entrypoints for local package inspection,
provides `python3`/`python` command wrappers, exposes common BusyBox-backed
command entrypoints, includes a small `pcietool` sysfs helper, packages a
project-owned libc stack and split zlib/ncurses/readline/OpenSSL-1.0 runtime
library packages under `/opt/xeon-phi-revival/lib64`, verifies runtime-library
presence through `xpr-runtime-libs-smoke`, packages and runs CPython 3.12.13
through `/usr/bin/python3.12`, verifies the packaged Python 3.12 smoke through
the second-stage service and `apt-get install --reinstall`, exercises `bz2`,
`lzma`, `readline`, `sqlite3`, `curses`, `curses.panel`, `_ssl`, and
OpenSSL-backed `_hashlib`, full libffi-backed `_ctypes` calls and callbacks,
and rolls back to the stock uOS.

This is still a bootstrap archive, not a complete Ubuntu archive port. Python
3.12 now has a working K1OM libffi backend: `ctypes.CDLL(...)`, integer,
pointer, float/double, aggregate, and closure/callback paths pass on `mic0`.
The remaining architecture-port work is real Ubuntu dpkg/APT/libc integration,
broader package rebuilds, and eventually reducing dependence on stock MPSS
userspace and init.

## Minimal Ubuntu-Shaped Rootfs

The package-set simulation can now be turned into a private minimal rootfs with
Ubuntu identity files and a root-level filesystem layout:

```text
tools/ubuntu-port/build-k1om-minimal-ubuntu-rootfs.sh
tools/ubuntu-port/validate-k1om-minimal-ubuntu-rootfs.sh
```

The generated rootfs is intentionally private because it can contain locally
supplied MPSS runtime files and K1OM binaries. The public repo tracks only the
recipe, validation checks, and public-safe reports.

The passing run is documented in:

```text
docs/ubuntu-port/k1om-bootstrap-package-set-report.md
manifests/experiments/k1om-bootstrap-package-set.yml
docs/ubuntu-port/k1om-apt-sandbox-report.md
manifests/experiments/k1om-apt-sandbox.yml
```
