# XPR-OS 0.1.0 RC1 Plan

> [!IMPORTANT]
> RC1 is superseded by the source-compliance-corrected
> [RC2](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc2).
> This file remains the historical RC1 architecture record.

## Decision

Status: `SOURCE_BYO_MPSS_RC_PUBLISHED`

The first public prerelease is a source, metadata, and bring-your-own-MPSS
builder release. The bootable private image passed the hardware gates, but its
kernel, modules, package repository, bootstrap, and rootfs remain unpublished
until every binary has a completed provenance and redistribution decision.

This is an experimental Ubuntu-derived K1OM environment. It is not an official
Ubuntu, Canonical, or Intel release.

Published prerelease:
<https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc1>

## Proven Architecture

```text
MPSS host + local inputs
  -> project compatibility kernel and five rebuilt modules
  -> small project bootstrap/Base CPIO
  -> micveth + bootstrap SSH
  -> checksummed final-root payload transfer
  -> project static switch helper
  -> project final-init trampoline
  -> final project root and PID 1
  -> final-root networking, SSH, packages, and Python
```

The accepted private artifact set is:

| Artifact | Bytes | SHA-256 |
| --- | ---: | --- |
| Candidate kernel | private | `0450c4370fb9c023c5229274d9a7a5cc02b8a37838c3220a0c714fc602cb2505` |
| Bootstrap root | 6,071,745 | `46fde82d0f5a0afe91719d1266c6e1151ec2b945fb78f96a3af669b1d38ff4f3` |
| Base CPIO | 29,578,142 | `42b7560f8dcc277f1d976e40db57668caedb749125e66171281ea8ba755e3bef` |
| Final-root payload | 77,582,489 | `8a410d8577971068888f46cee66b7b6020f675144f9d0cafc6a79efce53b7520` |

Two clean builds reproduced all three generated image hashes exactly.

## Passed Gates

- Project final root is active.
- Final project init runs as PID 1.
- `/proc`, `/sys`, `/dev`, `/run`, and `/tmp` are usable.
- `uname -m` reports `k1om` and `/etc/os-release` reports `xpr-uos`.
- micveth works at `172.31.1.1`.
- Project Dropbear accepts SSH in the final root.
- Native K1OM hello and pthread tests pass.
- Python 3.12.13 and `ctypes` call/callback tests pass.
- `dpkg`, `dpkg-query`, `dpkg-deb`, `apt-get`, and `apt-cache` work.
- The embedded local repository supports `apt-get update` and a clean
  reinstall of `xpr-pci-tools`.
- Automatic rollback restores stock MPSS, stock SSH, stock PID 1, and the exact
  baseline configuration hash.
- The same architecture completed three consecutive earlier boots; the exact
  final package-complete payload has one clean full-suite hardware pass.

## Public RC Contents

The public `v0.1.0-rc1` archive may contain:

- tracked project source, scripts, tests, documentation, and manifests;
- sanitized hashes and hardware evidence;
- local-input validation and reproducible build recipes;
- the repository `LICENSE` and `NOTICE.md`.

It must not contain:

- Intel MPSS packages, firmware, stock uOS, stock kernel, or SDK/sysroot files;
- private K1OM binaries, modules, Base CPIOs, rootfs payloads, or package files;
- host keys, credentials, private logs, or generated local configuration.

## Remaining Binary-Release Work

1. Classify every file in the private payload by source, license, build recipe,
   and redistribution status.
2. Rebuild or remove copied and lineage-uncertain components, including the
   current BusyBox and `libgcc_s` inputs.
3. Supply corresponding source, patches, notices, and license texts for GPL,
   LGPL, Python, zlib, ncurses, and other shipped components.
4. Prove the binary image contains no Intel/MPSS userspace or SDK payload.
5. Generate and review an SPDX-style SBOM.
6. Obtain human legal review before publishing prebuilt binaries.

Optional Python modules such as `bz2`, `lzma`, `readline`, `sqlite3`, and
`curses` do not block this source/BYO-MPSS prerelease.

## Release Rule

Tag and publish this milestone only as a prerelease. Do not label it stable and
do not attach the private boot images. A future binary RC requires the
redistribution gates above plus another clean hardware smoke and rollback run
of the exact publishable artifact.
