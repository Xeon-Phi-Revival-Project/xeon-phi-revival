# XPR uOS 0.1 Release License Review

> [!IMPORTANT]
> This July private-image review is retained for history. The authoritative
> current assessment is [XPR-OS Release Compliance Review](compliance-review.md),
> which also covers the compatibility kernel, rebuilt modules, Dropbear,
> corrected LGPL source packaging, and Canonical trademark boundary.

This is an engineering release review, not legal advice. It records what was
observed in the current lab build and gives conservative publication options
for the first Xeon Phi Revival uOS release candidate.

## Reviewed State

- Repository: `Xeon-Phi-Revival-Project/xeon-phi-revival`
- Current private RC build:
  `/root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125`
- Verified live baseline documented by:
  `docs/ubuntu-port/xpr-uos-0.1-rc-live-report.md`
- Host MPSS version: 3.4.10
- Card target: Intel Xeon Phi 5110P / Knights Corner / K1OM

The current RC rootfs is useful for lab validation, but it is still a private
payload until every copied binary has a recorded source and redistribution
decision.

## Local MPSS Findings

Installed MPSS-related RPM license fields observed on the CentOS MPSS host:

| Package | License Field |
| --- | --- |
| `glibc2.12pkg-libmicmgmt0-3.4.10-1.glibc2.12.x86_64` | `LGPLv2.1` |
| `glibc2.12pkg-mpss-flash-3.4.10-1.glibc2.12.x86_64` | `Intel-MPSS-License` |
| `glibc2.12pkg-mpss-rasmm-kernel-3.4.10-1.glibc2.12.x86_64` | `Intel-MPSS-License` |
| `mpss-boot-files-3.4.10-1.glibc2.12.x86_64` | `GPLv2` |
| `mpss-core-3.4.10-1.glibc2.12.x86_64` | `MIT` |
| `mpss-daemon-3.4.10-1.glibc2.12.x86_64` | `GPLv2 LGPLv2.1` |
| `mpss-micmgmt-3.4.10-1.glibc2.12.x86_64` | `LGPLv2.1` |
| `mpss-modules-3.10.0-693.el7.x86_64-3.4.10-1.x86_64` | `GPLv2` |
| `mpss-myo-3.4.10-1.glibc2.12.x86_64` | `LGPLv2.1` |
| `mpss-sdk-k1om-3.4.10-1.x86_64` | `various` |
| `microcode_ctl-2.1-22.el7.x86_64` | `GPLv2+ and Redistributable, no modification permitted` |

The local MPSS archive also contains
`mpss-license-3.4.10-1.glibc2.12.x86_64.rpm`. It was not installed, but it was
inspected without installing it.

| Field | Value |
| --- | --- |
| Name | `mpss-license` |
| Version | `3.4.10-1.glibc2.12` |
| License | `Intel-MPSS-License` |
| Vendor / packager | Intel Corporation |
| Build host | `sid-bld24.pdx.intel.com` |
| Build date | 2017-01-12 |
| Signature | DSA/SHA1, key ID `94619b594a86c38d`, local key unavailable (`NOKEY`) |
| Extracted file | `/usr/share/doc/mpss-3.4.10/license.txt` |
| Extracted license SHA-256 | `622b8be9dd2c1add746d1f8ddc0f9a0b1c8cd818906fc6f398511f6eb2fea0e0` |

The MPSS license text is titled for internal use and object-code distribution.
It includes restrictions and an Intel EULA attachment. Until a human legal
review says otherwise, this project should not redistribute Intel MPSS RPMs,
firmware, stock uOS images, stock kernels, SDK sysroots, Intel compiler
packages, or copied Intel runtime payloads.

## Current RC Payload Classes

The current private RC contains a mix of:

- original project shell scripts, manifests, package metadata, and smoke tests;
- project-built K1OM binaries;
- Ubuntu/GNU/upstream-source-derived binaries;
- copied or lineage-uncertain K1OM runtime files from local MPSS/uOS/sysroot
  inputs;
- generated `.deb`, package archive, and rootfs payloads.

The generated rootfs is about 127 MB in the current lab build. The manifest
marks package archives and private payload tarballs as `review-required`.

Important binaries observed in the rootfs include BusyBox, CPython 3.12,
legacy CPython 3.5, the project-built eglibc runtime, libgcc, libffi, zlib,
ncurses/libtinfo, Readline, and OpenSSL 1.0.x libraries. For release purposes,
source provenance matters more than whether the binary works. A working K1OM
ELF is not automatically redistributable.

## Component Release Matrix

| Component | Observed / Likely License | Current Release Decision | Required Before Binary Publication |
| --- | --- | --- | --- |
| Project docs and scripts | MIT | Redistributable now | Keep copyright/license notices |
| Project package shims and smoke tests | MIT | Redistributable now if source is included | Keep generated packages traceable to repo source |
| MPSS RPMs, firmware, stock uOS, stock kernel, Intel compiler installers | Mixed, includes `Intel-MPSS-License` | Bring-your-own only | Do not publish from this repo |
| MPSS SDK K1OM sysroot files | `various`, distributed inside Intel SDK package | Bring-your-own only for now | Replace with rebuilt open-source equivalents or require local SDK input |
| MPSS boot files and host modules | GPLv2 fields observed | Do not bundle in uOS release | Link/source references only unless a separate GPL source release is prepared |
| `microcode_ctl` / firmware-like payloads | GPLv2+ and redistributable/no modification field observed | Do not bundle | Users obtain through host distro/vendor channels |
| eglibc/glibc runtime | LGPL-family | Potentially redistributable if built from source and compliance material is shipped | Provide exact source, patches, notices, and LGPL compliance material |
| BusyBox | GPLv2 | Do not publish current copied binary | Rebuild from source and provide corresponding source, or keep BYO/local-only |
| CPython 3.12 | Python Software Foundation License v2 plus incorporated licenses | Potentially redistributable | Include Python license stack and source/provenance manifest |
| CPython 3.5 compatibility payload | Python license, but current binary lineage is not needed | Remove from public RC | Drop unless rebuilt from source and required |
| libffi | MIT-style permissive license | Potentially redistributable | Include license and exact source provenance |
| zlib | zlib license | Potentially redistributable | Rebuild or prove source provenance for the shipped K1OM binary |
| ncurses / libtinfo | permissive ncurses license | Potentially redistributable | Rebuild or prove source provenance and include notices |
| GNU Readline | GPLv3 according to upstream Readline page | Optional; avoid for first binary RC if not needed | If shipped, satisfy GPL source/license obligations |
| OpenSSL 1.0.x | OpenSSL/SSLeay license for pre-3.0 releases | Optional; avoid for first binary RC if not needed | Rebuild from source and review notices/compatibility before shipping |
| libgcc_s | GCC runtime library with runtime exception when from GCC sources | Provenance review required | Rebuild or trace exact source and exception notices |
| Ubuntu-derived source package patches | Upstream package-specific licenses | Source references and patches may be redistributable with notices | Preserve upstream copyright files and source package references |

## Publication Options

### Option A: Source, Metadata, and Reproducibility Release

This is safe to do first. Publish repository source, documentation, public
manifests, package names, hashes, file inventories, build scripts, BYO-MPSS
instructions, and sanitized smoke-test evidence. Do not publish rootfs tarballs,
`.deb` packages containing copied or uncertain binaries, MPSS RPMs, extracted
sysroots, stock uOS files, Intel firmware, kernels, or compiler installers.

### Option B: BYO-MPSS Builder Release

This is the recommended first usable release. Publish a release archive
containing only public project code, manifests, and scripts. The user supplies
MPSS/SDK locally, and the build flow creates a private rootfs on their machine.

This can include a one-command build wrapper, source download/build recipes for
open-source components, checksum validation of local Intel inputs, local-only
rootfs generation, and a reversible MicDir install/boot script.

### Option C: Public Prebuilt Binary Rootfs

This should wait. A downloadable rootfs is realistic, but the current RC should
not be published as a binary image.

The binary release gate is:

1. remove `python3.5` compatibility payloads unless rebuilt and required;
2. rebuild BusyBox from source or replace it with another compliant shell/core
   command provider;
3. rebuild zlib, ncurses/libtinfo, libffi, OpenSSL if included, and other
   userland libraries from recorded public sources;
4. rebuild or fully trace `libgcc_s.so.1`;
5. include license texts and source/provenance records for every shipped binary;
6. include LGPL/GPL compliance material for eglibc, BusyBox, Readline if used,
   and any other copyleft component;
7. prove the image contains no MPSS SDK/sysroot/uOS/firmware/kernel payloads;
8. regenerate an SPDX-style SBOM and artifact manifest;
9. run the live release smoke test and rollback test on `mic0`;
10. get a human legal review before attaching the rootfs to a public release.

## Recommendation

Release `xpr-uos-0.1-rc1` as a source/metadata/BYO-MPSS builder release, not as
a prebuilt rootfs.

The release can truthfully claim:

> Minimal Ubuntu-derived K1OM uOS release-candidate build and boot procedure,
> verified on Xeon Phi 5110P with locally supplied MPSS 3.4.10 inputs.

It should not claim official Ubuntu status, Intel or Canonical endorsement,
redistribution rights for MPSS, or that the current private rootfs is
public-safe.

## Highest-Value Cleanup Before Any Binary Artifact

The fastest path toward a binary rootfs is to create a `public-binary-clean`
profile that intentionally excludes difficult or uncertain payloads:

- remove Python 3.5;
- exclude OpenSSL and Readline unless needed;
- rebuild BusyBox, zlib, ncurses/libtinfo, libffi, CPython 3.12, and eglibc
  from recorded public sources;
- require local MPSS only for host boot support and the K1OM compiler/sysroot
  build input, not as copied release payload.

That leaves a smaller rootfs, but it is much closer to something we can
responsibly attach to a GitHub release.

## External License References

- Python license: <https://docs.python.org/3/license.html>
- GNU C Library project and license links: <https://www.gnu.org/software/libc/>
- BusyBox license: <https://busybox.net/license.html>
- zlib license: <https://www.zlib.net/zlib_license.html>
- ncurses licensing FAQ: <https://invisible-island.net/ncurses/ncurses.faq.html#licensing>
- libffi project/license information: <https://sourceware.org/libffi/>
- GNU Readline project/license information: <https://tiswww.case.edu/php/chet/readline/rltop.html>
- OpenSSL release license overview: <https://openssl-library.org/source/license/index.html>
- GCC Runtime Library Exception: <https://www.gnu.org/licenses/gcc-exception.html>
