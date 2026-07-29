# Xeon Phi Revival

Practical preservation and software bring-up for Intel Xeon Phi Knights Corner
coprocessors. The current lab target is a working 5110P that can boot MPSS,
accept SSH, compile native K1OM programs, and run an experimental
Ubuntu-shaped package/profile layer.

The Xeon Phi Revival Project is a community preservation and engineering effort
focused on restoring usable software-development support for Intel Xeon Phi
Knights Corner coprocessors. The project has successfully compiled and executed
native K1OM assembly, C, pthread, math, file-I/O, and 512-bit vector test
programs on an Intel Xeon Phi 5110P running MPSS 3.4.10.

This project is AI-assisted and Codex-driven: planning, documentation,
experiments, scripts, and repository maintenance are being developed in
collaboration with OpenAI Codex/ChatGPT, with hardware results validated on the
actual Xeon Phi system before being treated as project facts.

## Start Here

- New to the hardware: [From Card To Code](docs/getting-started-card-to-code.md)
- Current verified status: [Project Status](docs/status.md)
- Public-safe source/reference list: [Source Index](docs/source-index.md)
- Ubuntu/K1OM package lane:
  [K1OM Ubuntu Port Lab](ubuntu-port/k1om/README.md)
- Latest package-set report:
  [K1OM Bootstrap Package Set](docs/ubuntu-port/k1om-bootstrap-package-set-report.md)
- K1OM libffi/Python ctypes result:
  [K1OM libffi and CPython ctypes](docs/ubuntu-port/k1om-libffi-ctypes-report.md)
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

The project has moved beyond initial native execution into reversible uOS and
Ubuntu-style package experiments:

- Project PID 1 handoff through MPSS MicDir was proven and rolled back.
- A second-stage project service can run after stock init without replacing the
  stock uOS.
- A deterministic local `Architecture: k1om` package set now builds into a
  Noble-style `binary-k1om` archive with `Packages`, `Packages.gz`, and
  `Release` checksum metadata.
- Host-side APT can parse the local archive when forced to
  `APT::Architecture=k1om`.
- The current thirty-six-package bootstrap set boots on `mic0`, runs
  `hello-knc`, CPython core, zlib smoke, ncurses smoke through a separately
  packaged `libtinfo5-k1om` runtime, basic filesystem/OS smoke, exposes
  dpkg-style package status, provides project `dpkg`/`apt-get`/`apt-cache`
  commands backed by the local K1OM archive, provides `python3`/`python`
  command wrappers, exposes common BusyBox-backed command entrypoints, includes
  a small `pcietool` sysfs helper, packages a project-owned libc runtime stack
  and split zlib/ncurses/readline/OpenSSL-1.0 runtime libraries under
  `/opt/xeon-phi-revival/lib64`, includes packaged CPython 3.12.13 and
  `libffi8-k1om`, includes OpenSSL-backed `_ssl`/`_hashlib`, and provides
  working Python `_ctypes` calls and callbacks.
- CPython 3.12.13 now runs on `mic0` as local `Architecture: k1om` packages:
  `python3.12-minimal-k1om`, `python3.12-stdlib-k1om`,
  `python3.12-sysconfig-k1om`, and `python3.12-smoke-k1om`. The packaged
  smoke covers zlib, hashes, XML, pickle, CSV, asyncio import, sysconfig,
  threading, decimal, socket, `bz2`, `lzma`, `readline`, `sqlite3`, `curses`,
  `curses.panel`, `_ctypes` foreign calls, `_ctypes` callbacks, and more.

See `docs/status.md` and `docs/ubuntu-port/` for the latest public-safe
reports.

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

- `docs/`: public-safe architecture, uOS, hardware, and toolchain notes.
- `tests/`: original K1OM smoke-test source code.
- `tools/`: original helper scripts for metadata collection and validation.
- `toolchains/`: notes and scripts for Intel MIC and open-toolchain lanes.
- `uos/`: scripts and notes for inventorying locally supplied uOS contents.
- `experiments/`: native run harnesses.
- `manifests/`: hardware and experiment manifests.
- `artifacts/public/`: public-safe generated metadata only.

## Current Experimental Profile

The latest local profile is a thirty-six-package `Architecture: k1om` set. It is
not a full Ubuntu port yet, but it behaves more like a small Linux userland:

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
libutil1-k1om
libtinfo5-k1om
ncurses-base-k1om
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

Verified command conveniences inside the profile:

```bash
ls
cat
grep
sed
awk
find
python3
python
pcietool
dpkg
dpkg-query
dpkg-deb
apt-get
apt-cache
cat /var/lib/dpkg/status
```

## Bring Your Own MPSS

This repository does not redistribute Intel MPSS packages, Intel compiler
installers, firmware, extracted sysroots, stock uOS images, Intel headers, Intel
libraries, or copied Intel documentation.

Users must obtain any required Intel software under its applicable terms. The
project documentation may refer to package names, versions, hashes, paths, and
ELF metadata, but those references are not redistributions of the underlying
software.

For public links and source notes, see [Source Index](docs/source-index.md).

## Status

Phase 1 is complete: a real Xeon Phi 5110P moved from PCIe enumeration and MPSS
bring-up to repeatable native K1OM program execution.

The active milestone is the true Ubuntu architecture-port lane: keep expanding
the deterministic `k1om` package set and rootfs layout while preserving APT
parser checks, package audits, simulated installs, live MicDir boot smoke tests,
and verified rollback to stock uOS. OpenSSL-backed `_ssl`/`_hashlib`, sqlite3,
curses, curses.panel, terminfo-backed terminal setup, and full libffi-backed
Python `_ctypes` calls and callbacks now pass inside packaged Python 3.12.
The next major distribution boundary is replacing the bootstrap dpkg/APT
compatibility tools and MPSS-era libc with genuine Ubuntu ports.

## Independence

This is experimental preservation work. Intel, Xeon, and Xeon Phi are trademarks
of Intel Corporation. This project is unaffiliated with Intel and is not
sponsored, endorsed, or supported by Intel.

## License

Original project work is licensed under the MIT License. See `LICENSE`.

The MIT License applies only to original project work in this repository. It
does not grant rights to Intel software, firmware, documentation, extracted
sysroots, or third-party components.
