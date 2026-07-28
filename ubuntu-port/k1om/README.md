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

The first multi-package bootstrap archive also passed. It contains:

- `base-files-k1om`
- `hello-knc-smoke`
- `python3.5-core-k1om`
- `zlib-smoke-k1om`
- `libtinfo5-k1om`
- `ncurses-smoke-k1om`
- `xpr-os-smoke`
- `xeon-phi-revival-stage2`

That package set now builds deterministically, is indexed into a local unsigned
Noble `binary-k1om` archive with `Packages`, `Packages.gz`, and `Release`
checksums, audited, simulated into a dpkg-style staged rootfs, installed into
MPSS MicDir staging, booted on `mic0`, runs `hello-knc`, runs CPython core,
is parsed by host-side APT as `Architecture: k1om`, runs zlib and ncurses
smoke payloads, uses a separately packaged `libtinfo5-k1om` runtime, verifies
basic filesystem and OS behavior, and rolls back to the stock uOS.

The passing run is documented in:

```text
docs/ubuntu-port/k1om-bootstrap-package-set-report.md
manifests/experiments/k1om-bootstrap-package-set.yml
docs/ubuntu-port/k1om-apt-sandbox-report.md
manifests/experiments/k1om-apt-sandbox.yml
```
