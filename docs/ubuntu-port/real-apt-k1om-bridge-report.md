# Real APT K1OM Compatibility Bridge

Status: full local-archive transaction passed on the Intel Xeon Phi 5110P.

Date: 2026-07-29

## Result

Ubuntu APT `1.0.1ubuntu2.24` was cross-built for K1OM with the MPSS 3.4.10
GCC 4.7 toolchain. Ubuntu Noble zlib `1.3.dfsg-3.1ubuntu2.1` was built as a
position-independent static library for the APT shared libraries.

The staged runtime contains native K1OM builds of:

- `apt`
- `apt-get`
- `apt-cache`
- `apt-config`
- `apt-mark`
- `libapt-pkg.so.4.12`
- `libapt-inst.so.1.5`
- `libapt-private.so.0.0`
- the `file`, `copy`, `gzip`, `gpgv`, and `rred` methods
- the internal dependency solver

Fourteen staged ELF files were audited as ELF64 Intel K1OM, machine 181.
The build is installed side-by-side at
`/opt/xeon-phi-revival/apt-real`; the bootstrap `/usr/bin/apt-get` was not
replaced.

## On-Card Acceptance

The native binary reports:

```text
apt 1.0.1ubuntu2.24 for k1om
APT::Architecture "k1om";
```

`apt-get update` read the existing trusted local repository at
`file:/opt/xeon-phi-revival/repo`. `apt-cache policy` selected the expected
`Architecture: k1om` candidates from `noble/main`.

Real APT then drove real Ubuntu Noble dpkg through two isolated transactions:

1. A three-package dependency install selected, unpacked, and configured
   `base-files-k1om`, `xpr-busybox-compat`, and `xpr-pci-tools`.
2. A fresh full-archive transaction selected, unpacked, and configured all 36
   project packages.

The full transaction ended with 36 `install ok installed` records and a clean
`dpkg --audit`. CPython 3.12.13 executed from the APT-created root and passed
imports and calls through `ctypes`, SQLite 3.45.1, and zlib 1.3.

## Scope

This is a compatibility bridge, not Noble APT and not an upstream Ubuntu
architecture port. It is useful because it replaces the project APT resolver
shim with real Ubuntu APT code for the local, trusted, file-based archive.

HTTPS is intentionally disabled in this build. The source required libcurl
for its HTTPS method, while the current bootstrap only needs the local `file:`
transport. Network repositories and signature policy remain future work.

## Noble APT Blocker

Ubuntu Noble APT `2.8.3` was also probed from official source. It requires
CMake 3.13 and C++17. The host CMake can be upgraded independently, but the
MPSS K1OM compiler accepts `-std=gnu++0x` and rejects `-std=gnu++11`,
`-std=gnu++14`, and `-std=gnu++17`.

The narrowest dependency for a true Noble APT build is therefore a modern
K1OM C++ compiler and compatible `libstdc++`, or a substantial reviewed
backport of APT 2.8 to the older language level.

## Verified Inputs

APT source:

```text
apt_1.0.1ubuntu2.24.dsc
SHA-256: 3e2e99fc464b10660035c92e3791fd303d1b23c1abbfc4c590db7e7b62b3fdc7

apt_1.0.1ubuntu2.24.tar.xz
SHA-256: 6241527ac778b1e9008a21e0e8de57dc48798f078d95ae59fc6e347559abb5d7
```

The APT tar hash matched the checksum in the `.dsc`. Both Noble zlib source
files matched their `.dsc` checksums.

Public build inputs:

```text
tools/ubuntu-port/build-apt-k1om-bridge.sh
ubuntu-port/k1om/patches/apt-1.0.1ubuntu2.24-k1om-bridge.patch
```

Private run:

```text
/root/xeon-phi-revival-local/ubuntu-port-runs/apt-legacy-k1om-20260729-194129
/root/xeon-phi-revival-local/ubuntu-port-runs/apt-bridge-repro-20260729
/root/xeon-phi-revival-local/ubuntu-port-runs/apt-real-k1om-probe-20260729-194032
```

No Ubuntu source archives, Intel toolchains, generated target binaries,
package archives, or private logs are committed.
