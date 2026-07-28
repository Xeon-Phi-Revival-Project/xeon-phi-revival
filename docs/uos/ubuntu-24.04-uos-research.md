# Ubuntu 24.04 uOS Research Track

This track investigates whether a newer Ubuntu-inspired or Ubuntu-derived
userland can run on Intel Xeon Phi Knights Corner under the stock MPSS boot
model.

It does not start by replacing the card firmware, flashing the card, or claiming
that Ubuntu 24.04 can boot normally on K1OM. The first target is a reversible
userland experiment:

```text
stock MPSS kernel and host boot path
local-only K1OM root filesystem experiment
project-built K1OM binaries
Ubuntu-like filesystem layout where useful
```

## Current Level

Level 0 is complete enough to begin research:

- The Xeon Phi 5110P reaches `mic0: online` under MPSS 3.4.10.
- Public-safe stock uOS boot and ELF metadata are documented.
- Native K1OM assembly, C, file I/O, `libm`, pthread, and zmm-vector smoke
  tests have run on the card.
- The minimum dynamic runtime map is known for the passing smoke tests.

The next target is Level 1: prove that a tiny custom K1OM root filesystem can
run basic commands under the stock MPSS boot model, or document the exact
blocker.

## Definitions

Ubuntu-compatible:

- Use familiar Ubuntu filesystem conventions and package naming where practical.
- Do not require `apt` or Ubuntu archive metadata to work on the card.
- Use project-built K1OM binaries and local-only runtime files.
- This is the first realistic public milestone.

Ubuntu-derived:

- Rebuild selected Ubuntu 24.04 source packages for K1OM.
- Record source package versions, patches, configure flags, failures, and
  runtime results.
- Do not copy amd64 Ubuntu binaries into the K1OM root filesystem.
- This is the practical Python/rootfs target.

True Ubuntu port:

- Provide a coherent Ubuntu architecture port for a K1OM-like target, including
  archive metadata, package rebuilds, libc integration, and boot/userland
  policy.
- Treat this as a long-term feasibility question.

## Phase Plan

### Phase 0: Stock Baseline

Status: complete enough for Level 1 preparation.

Inputs:

- `docs/uos/stock-mpss-3.4.10-uos-inventory.md`
- `docs/uos/stock-uos-elf-inventory.md`
- `docs/uos/stock-uos-library-dependencies.md`
- `docs/toolchain/minimum-k1om-runtime.md`
- `artifacts/public/uos-elf-inventory.csv`
- `artifacts/public/uos-dependency-graph.json`

Output:

- Public metadata proving the stock uOS loader, core libraries, and executable
  format.

### Phase 1: Tiny Rootfs Requirements

Status: started.

Use the stock metadata to identify the smallest boot/userland set worth testing:

- `/sbin/init` or a replacement init
- `/bin/sh`
- `/bin/busybox` or project-built equivalents
- `/lib64/ld-linux-k1om.so.2`
- `libc.so.6`
- `libgcc_s.so.1`
- optional first extensions: `libpthread.so.0`, `libm.so.6`, `libdl.so.2`
- `/dev`, `/proc`, `/sys`, `/tmp`, `/run`, and basic `/etc` files
- a known-good K1OM smoke binary such as `hello-knc`

This phase should produce a local-only rootfs tree, a public-safe manifest, and
a boot attempt manifest. The rootfs tree itself must stay ignored unless every
file has been license-reviewed.

### Phase 2: Ubuntu-Compatible Layout

Status: blocked on Level 1.

Once a tiny rootfs boots or chroots cleanly, arrange project-built K1OM files
into an Ubuntu-like layout:

- `/usr/bin`, `/usr/lib64`, `/usr/share`
- `/etc/os-release` with a project identity, not an Ubuntu trademark claim
- package-style manifests under `var/lib/knc-uos-lab`

### Phase 3: Ubuntu 24.04 Source Rebuilds

Status: blocked on Phase 2.

Rebuild selected Ubuntu 24.04 source packages for K1OM, starting with small
libraries and utilities before Python:

- `zlib`
- `libffi`
- `openssl` or another TLS strategy
- `readline`
- `ncurses`
- `sqlite`
- CPython dependencies

Every rebuild must record provenance, source version, patch set, configure
flags, toolchain path, and runtime result.

### Phase 4: Python From Ubuntu-Derived Userland

Status: blocked on Phase 3.

The first Python target should be an era-compatible CPython that can run a small
script, import core modules, use file I/O, and report platform information from
inside the K1OM userland.

### Phase 5: True Ubuntu Port Feasibility

Status: blocked on lower levels.

Only investigate this after the custom rootfs and selected package rebuilds
produce useful evidence.

## Safety Boundary

- Do not flash the card.
- Do not replace the known-good stock boot path without a copy-based rollback
  plan.
- Do not commit Intel uOS files, extracted sysroots, firmware, MPSS packages, or
  copied Ubuntu binaries.
- Keep private rootfs experiments under ignored paths such as `uos-rootfs/`,
  `rootfs/`, `stock-uos/`, `sysroot/`, or `artifacts/private/`.
- Public commits may include scripts, manifests, hashes, file names, package
  recipes, and generated metadata.
