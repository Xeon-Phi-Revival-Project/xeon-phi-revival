# Xeon Phi Revival

Practical preservation and software bring-up for Intel Xeon Phi Knights Corner
coprocessors. The current lab target is a working 5110P that can boot MPSS,
compile native K1OM programs, and boot the experimental Ubuntu-derived XPR-OS
split-root environment with project PID 1, networking, SSH, packages, and
Python 3.12.

The Xeon Phi Revival Project is a community preservation and engineering effort
focused on restoring usable software-development support for Intel Xeon Phi
Knights Corner coprocessors. The project now boots a project-controlled
split-root XPR-OS environment with PID 1, networking, SSH, native package
management, and Python 3.12 on an Intel Xeon Phi 5110P running MPSS 3.4.10.

This project is AI-assisted and Codex-driven: planning, documentation,
experiments, scripts, and repository maintenance are being developed in
collaboration with OpenAI Codex/ChatGPT, with hardware results validated on the
actual Xeon Phi system before being treated as project facts.

> [!NOTE]
> **XPR-OS 0.1.0-rc1 hardware gates passed - August 10, 2026**
>
> The project-controlled split-root path now reaches the final root with project
> PID 1, micveth, Dropbear SSH, native package management, Python 3.12, and the
> full release smoke suite. Reproducible private builds and stock rollback also
> passed. Public distribution is currently limited to source, metadata, and a
> bring-your-own-MPSS builder while binary redistribution review continues.

## Start Here

- Latest source/BYO-MPSS prerelease:
  [XPR-OS 0.1.0-rc2](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc2)
- New to the hardware: [From Card To Code](docs/getting-started-card-to-code.md)
- Documentation map: [Documentation](docs/README.md)
- Current verified status: [Project Status](docs/status.md)
- Build the RC from public source and local inputs:
  [Build XPR-OS RC From Source](docs/release/build-xpr-os-rc-from-source.md)
- Hardware evidence: [XPR-OS 0.1 RC Live Report](docs/ubuntu-port/xpr-uos-0.1-rc-live-report.md)
- Release boundary: [Compliance Review](docs/release/compliance-review.md)
- Public-safe source/reference list: [Source Index](docs/source-index.md)
- Ubuntu/K1OM package lane:
  [K1OM Ubuntu Port Lab](ubuntu-port/k1om/README.md)
- Latest package-set report:
  [K1OM Bootstrap Package Set](docs/ubuntu-port/k1om-bootstrap-package-set-report.md)
- K1OM libffi/Python ctypes result:
  [K1OM libffi and CPython ctypes](docs/ubuntu-port/k1om-libffi-ctypes-report.md)
- Native package-manager results:
  [real dpkg](docs/ubuntu-port/real-dpkg-k1om-report.md) and
  [real APT bridge](docs/ubuntu-port/real-apt-k1om-bridge-report.md)
- Toolchain package notes:
  [MPSS SDK K1OM preinstall report](docs/toolchain/mpss-sdk-k1om-3.4.10-preinstall-report.md)

## What This Is

Intel Xeon Phi Knights Corner cards are PCIe coprocessors, not ordinary host
CPUs. They run a small Linux-based uOS on K1OM cores and are managed by Intel
MPSS from an x86-64 host.

K1OM is the Knights Corner native ISA/ABI target. It is not normal x86-64, even
though many tools display ELF64 containers. Native card binaries must report
`Machine: Intel K1OM` and ELF machine value `181`.

## Proven Baseline

Current verified hardware and software baseline:

- Card: Intel Xeon Phi 5110P / 5100 series
- Host: Dell PowerEdge R730
- Host OS: CentOS 7.4.1708
- MPSS: 3.4.10
- Toolchain package: `mpss-sdk-k1om-3.4.10-1.x86_64`
- Tool prefix: `k1om-mpss-linux-*`
- Card state: `mic0` online with SSH working

Verified native runs:

- Freestanding `_start` K1OM ELF returned exit code `42`.
- Dynamically linked K1OM libc hello-world printed `hello from k1om libc`.
- Native C smoke test reported `machine=k1om`, 64-bit pointers, and 64-bit
  longs.
- File I/O, `libm`, pthread creation/join, normal return codes, and zmm vector
  instructions were tested on the card.
- Disassembly of the vector smoke test confirmed `vbroadcastsd`, `vaddpd`, and
  `vmovapd`.

## Current Port Progress

The project has moved beyond native-program probes into a hardware-verified,
reversible XPR-OS release-candidate path:

- A project-built compatibility kernel boots a small bootstrap and a
  checksummed final-root payload.
- The project switch helper reaches the final project root and runs the
  BusyBox-based project init as PID 1.
- The final root provides micveth, Dropbear SSH, an XPR-OS boot/login banner,
  interactive PTYs, native hello and pthread tests, and Python 3.12.13.
- Native K1OM dpkg and an APT compatibility bridge operate against an embedded
  local `Architecture: k1om` repository; package reinstallation passed on the
  card.
- Python `_ctypes` calls and callbacks and zlib passed in the accepted eglibc
  profile. Optional modules are reported separately instead of being treated
  as core RC failures.
- Two clean private builds reproduced the bootstrap, Base CPIO, and payload
  hashes. Bounded hardware runs restored stock MPSS, stock SSH, and the exact
  configuration hash.
- Post-gate usability checks proved an interactive SSH shell, the XPR-OS
  banner, and normal Python `exit()`/`quit()` helpers. Their source fixes must
  be included in the next clean image and full smoke run before a new binary
  artifact is called hardware-accepted.

See `docs/status.md` and `docs/ubuntu-port/` for the latest public-safe
reports.

## Ubuntu-Derived Claim Boundary

The current RC satisfies most of the functional minimums below, but it is not
an official Ubuntu architecture port and is not produced by Ubuntu's archive
infrastructure. The accurate current description is an experimental,
Ubuntu-derived K1OM XPR-OS environment. A stronger Ubuntu-port claim requires
all of these pieces to be publicly reproducible and tested:

- Ubuntu package metadata recognizes a real `k1om` architecture, including
  `dpkg-architecture` fragments and a `binary-k1om` archive path.
- Ubuntu-source base runtime packages provide the loader and core libraries:
  `libc6`, `libgcc1`, `libm6`, `libpthread0`, `libdl2`, `librt1`, and
  `libutil1`.
- Real K1OM `dpkg` can install the essential package set into a clean root.
- Native K1OM APT can update from the local project archive and install K1OM
  packages through real dpkg.
- The resulting root/profile exposes normal system commands such as `sh`,
  `ls`, `cat`, `python3`, `dpkg`, `dpkg-query`, `dpkg-deb`, `apt-get`, and
  `apt-cache`.
- A boot or controlled stock-init handoff presents a coherent Ubuntu-shaped
  root with `/etc/os-release`, `/dev`, `/proc`, `/sys`, `/tmp`, package status,
  and rollback to stock MPSS.
- Public scripts and manifests can rebuild the package set without committing
  Intel MPSS payloads, extracted sysroots, firmware, private rootfs images, or
  uncertain-redistribution binaries.

The previous narrow blocker, `libpthread`, passed in the side-by-side
Ubuntu-source eglibc 2.19 probe: K1OM `ld-linux-k1om.so.2`, `libc.so.6`, and
`libpthread.so.0` ran a dynamic hello and pthread smoke on real uOS. The package
builder can also produce deterministic eglibc-backed libc packages, and the
36-package live gate now passes after rebuilding the core payloads against that
runtime. The final gate verified Ubuntu/K1OM identity, APT/dpkg paths,
`python3`/`python` as Python 3.12.13, `_ctypes`, zlib/ncurses/runtime-library
smokes, filesystem/OS smokes, and stock rollback. The current release boundary
is legal and provenance review for a downloadable binary image; optional Python
extensions remain documented non-blockers for the source/BYO-MPSS RC.

## What You Can Do Today

With a compatible host, MPSS install, and locally supplied K1OM SDK, the project
can guide you through:

1. Detecting a Knights Corner card.
2. Bringing `mic0` online with MPSS.
3. SSHing into the card.
4. Building and validating a native K1OM ELF.
5. Running progressively larger native smoke tests.
6. Building a local `k1om` package archive.
7. Booting the reversible project profile and returning to stock.

The repo intentionally keeps that path check-heavy. If a step fails, the next
move should be collecting evidence, not guessing with firmware.

## Current Goals

- Preserve public-safe knowledge about Knights Corner, K1OM, MPSS, and the uOS
  runtime.
- Build small, repeatable native test programs that prove specific runtime and
  ABI behavior.
- Map the minimum runtime and sysroot pieces needed for ports.
- Explore practical ports such as Python and Doom after the C/runtime baseline
  is well understood.
- Keep proprietary Intel payloads, firmware, extracted sysroots, and unclear
  third-party materials out of the repository.

## Repository Structure

- `src/`: project-owned init, switch, banner, and native helper source.
- `docs/`: public-safe architecture, uOS, hardware, and toolchain notes.
- `tests/`: original K1OM smoke-test source code.
- `tools/`: original helper scripts for metadata collection and validation.
- `toolchains/`: notes and scripts for Intel MIC and open-toolchain lanes.
- `uos/`: scripts and notes for inventorying locally supplied uOS contents.
- `experiments/`: native run harnesses.
- `manifests/`: hardware and experiment manifests.
- `artifacts/public/`: public-safe generated metadata only.
- `tools/release/`: deterministic source packaging and split-root assembly.

## Private Experimental Profile

The accepted private profile contains 36 local `Architecture: k1om` packages,
including the project eglibc runtime, BusyBox command layer, native dpkg, the
APT compatibility bridge, CPython 3.12, libffi, zlib, ncurses, package smokes,
and project services. The package archive and binaries are not public release
artifacts while provenance and redistribution review remains incomplete.

Verified commands include:

```bash
ls
cat
grep
sed
awk
find
python3
python
busybox --list
pcietool
dpkg
dpkg-query
dpkg-deb
apt-get
apt-cache
cat /var/lib/dpkg/status
```

The shell is BusyBox `ash`, not Bash. Bash-only builtins such as `help` are not
present; use `busybox --list` and `busybox COMMAND --help` to discover applets.

## Bring Your Own MPSS

This repository does not redistribute Intel MPSS packages, Intel compiler
installers, firmware, extracted sysroots, stock uOS images, Intel headers, Intel
libraries, or copied Intel documentation.

Users must obtain any required Intel software under its applicable terms. The
project documentation may refer to package names, versions, hashes, paths, and
ELF metadata, but those references are not redistributions of the underlying
software.

For public links and source notes, see [Source Index](docs/source-index.md).

Release packaging is currently conservative by design. The first practical
public release should be a source/metadata/BYO-MPSS builder release, not a
prebuilt rootfs image, until every K1OM binary payload has a recorded source,
license, and redistribution decision. See the
[XPR uOS 0.1 license review](docs/release/xpr-uos-0.1-license-review.md) and
[license matrix](manifests/release/xpr-uos-0.1-license-matrix.yml).

## Status

Phase 1 is complete: a real Xeon Phi 5110P moved from PCIe enumeration and MPSS
bring-up to repeatable native K1OM program execution.

The private package/runtime profile passed its documented Python, libc,
networking, SSH, package-manager, and rollback tests. The split-root transition
and final project PID 1 are proven. The current public-release boundary is
redistribution: source, metadata, and BYO-MPSS tooling are published as RC2,
but the private kernel, modules, bootstrap, package repository, and rootfs are
not public artifacts. See the [current status](docs/status.md),
[source-build guide](docs/release/build-xpr-os-rc-from-source.md), and
[compliance review](docs/release/compliance-review.md). The evolving binary
evidence is tracked separately in the [prebuilt-image provenance record](docs/release/prebuilt-image-provenance.md);
it is not a publication approval.

The earlier non-eglibc package set demonstrated OpenSSL-backed Python modules,
SQLite, curses, terminfo, libffi, and `_ctypes`; the later eglibc-backed RC gate
should be treated as the authoritative current boundary and reports optional
module gaps separately. The project has crossed the native dpkg boundary and
has a local-file APT path, but this is not yet a standalone or official Ubuntu
port.

## Independence

This is experimental preservation work. Intel, Xeon, and Xeon Phi are trademarks
of Intel Corporation. This project is unaffiliated with Intel and is not
sponsored, endorsed, or supported by Intel.

## License

Original project work is licensed under the MIT License. See `LICENSE`.

The MIT License applies only to original project work in this repository. It
does not grant rights to Intel software, firmware, documentation, extracted
sysroots, or third-party components.

The repository is mixed-license: K1OM eglibc overlay files under
`ubuntu-port/k1om/glibc/` are marked `LGPL-2.1-or-later`. See `NOTICE.md`,
`LICENSES/`, and the [release compliance review](docs/release/compliance-review.md).
