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
- Project PID 1 handoff works.
- Project second-stage uOS profile works under stock MPSS init.
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
base-files-k1om
hello-knc-smoke
python3.5-core-k1om
zlib-smoke-k1om
libtinfo5-k1om
ncurses-smoke-k1om
xpr-os-smoke
xeon-phi-revival-stage2
```

The package set proves deterministic K1OM package construction, the local
`binary-k1om` archive path with `Packages` and `Packages.gz`, archive/package
audit path, simulated dpkg-style install/rootfs path with package `md5sums` and
`conffiles`, host-side APT parser path, MicDir install path, stock-init
second-stage service path, K1OM hello payload, CPython core payload, zlib smoke,
separate libtinfo runtime, ncurses smoke, basic filesystem smoke, and stock
rollback path.

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
zlib
ncurses
python3.5-core-k1om
xpr-os-smoke
xeon-phi-revival-stage2
```

The host-side APT parser test has passed for the bootstrap archive. The next
milestone is splitting the Python standard-library/package layout into more
Ubuntu-like packages under the same reversible gates.
