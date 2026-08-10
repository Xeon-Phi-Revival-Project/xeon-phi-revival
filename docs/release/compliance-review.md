# XPR-OS Release Compliance Review

Date: 2026-08-10

This is an engineering compliance assessment, not legal advice. It separates
the published source/BYO-MPSS release from a future prebuilt binary image.

## Current Public Release

`v0.1.0-rc1` contains tracked source, documentation, scripts, and metadata. It
does not contain MPSS packages, firmware, kernel images, modules, rootfs images,
`.deb` packages, SDK/sysroot files, or other private K1OM binaries.

The audit found one source-release defect: six tracked eglibc overlay files are
LGPL-2.1-or-later, but RC1 did not include the LGPL text. Main now includes the
license text and explicit SPDX markers. The corrected source archive is
published as RC2; the existing RC1 archive and hash were not silently replaced.

Canonical's policy also makes the `Ubuntu` trademark inappropriate in the
product title of an unapproved modified distribution. Generated identity now
uses `PRETTY_NAME="Xeon Phi Revival K1OM uOS"`. Documentation may factually say
that individual components are rebuilt from Ubuntu source packages, while
stating that XPR-OS is independent and unendorsed.

## Component Decisions

| Component | License or boundary | Binary decision | Required evidence or action |
| --- | --- | --- | --- |
| Original XPR source, scripts, tests, docs | MIT | `PUBLISH` | Include `LICENSE` and project notice |
| K1OM eglibc overlay source | LGPL-2.1-or-later | `PUBLISH_SOURCE` | Include LGPL text, copyright notices, modifications, and exact source baseline |
| Compatibility kernel | Linux GPL-2.0-only; candidate provenance remains incomplete | `HOLD` | Establish authoritative source provenance; publish exact corresponding source, config, patches, and build scripts beside the binary |
| Five card-side modules | Observed MPSS source/RPM fields are GPLv2 | `HOLD` | Verify each file header and source grant; publish the exact source and build scripts corresponding to the modules |
| Intel MPSS host software, firmware, stock uOS/kernel, SDK/sysroot | Mixed, including Intel MPSS EULA | `USER_SUPPLIED` | Never include; validate local user inputs by version/hash |
| BusyBox | GPL-2.0-only | `REBUILD_PROVEN` | BusyBox 1.19.4 rebuild matches the private payload byte-for-byte; publish only with its source bundle, config, GPL text, notices, and human review |
| eglibc runtime | LGPL-2.1-or-later plus file-specific notices | `REBUILD` | Publish exact source, overlays, config, build scripts, license notices, and relinking-compatible dynamic libraries |
| Dropbear | Permissive MIT/BSD-style collection | `REBUILD_PROVEN` | Dropbear 2022.83 source and current binary hash are pinned; retain the upstream multi-component `LICENSE`, build evidence, and human review gate |
| libgcc_s | GPLv3 with GCC Runtime Library Exception expected | `HOLD` | Identify exact GCC source/version and verify the shipped file carries the exception; avoid copying an unidentified SDK binary |
| CPython 3.12.13 | PSF-2.0 and incorporated licenses | `REBUILD` | Pin official source hash/SBOM; include complete Python license stack, patches, and build recipe |
| CPython 3.5 payload | Unneeded legacy input with uncertain lineage | `REMOVE` | Exclude from the public binary profile and package dependencies |
| libffi | Permissive MIT-style | `REBUILD` | Pin source version/hash and include its license and K1OM patches |
| zlib | zlib license | `REBUILD` | Pin source version/hash; retain notice and mark modifications |
| ncurses/libtinfo | MIT-style ncurses license | `REBUILD` | Pin source version/hash and preserve notices |
| GNU Readline | GPL-3.0-or-later for current relevant releases | `EXCLUDE_OPTIONAL` | Exclude unless needed; if included, publish exact corresponding source and GPL materials |
| OpenSSL 1.0.x | Dual OpenSSL/SSLeay license; obsolete | `EXCLUDE_OPTIONAL` | Exclude from first binary image; if retained, pin source and include both notices; do not present it as supported TLS |
| dpkg 1.22.6ubuntu6.6 | Package-specific GPL and permissive files | `REBUILD` | Preserve the source package `debian/copyright`, exact source archive, patches, and build scripts |
| APT 1.0.1ubuntu2.24 | Package-specific GPL and permissive files | `REBUILD` | Preserve exact source package copyright data, source archive, patches, and build scripts |
| Ubuntu package names/metadata | Component licenses plus Canonical trademark policy | `FACTUAL_REFERENCE` | Use package provenance factually; do not title or brand XPR-OS as Ubuntu |

`PUBLISH` does not mean warranty or endorsement. `REBUILD` means the current
binary is not publishable until its exact source lineage and compliance bundle
exist. `HOLD` means even the source provenance needs resolution.

## Copyleft Delivery Rules

- GPL object code must be accompanied by the complete corresponding source or a
  compliant source offer. The practical project rule is to publish exact source
  beside every binary, including patches, configuration, and build/install
  scripts.
- LGPL runtime libraries require the applicable license and corresponding
  modified library source. XPR-OS should keep them dynamically linked and ship
  enough material for recipients to replace/relink the library.
- A link to an unrelated upstream repository is not sufficient when it cannot
  reproduce the distributed binary.
- Source bundles must preserve upstream copyright and modification notices.

## Required Binary-Release Bundle

A prebuilt RC cannot be published until it contains or links beside it:

1. an SPDX SBOM listing every file and package;
2. per-component source name, version, URL, SHA-256, license expression, and
   build recipe;
3. exact corresponding-source archives for all GPL/LGPL binaries;
4. all license and third-party notice texts;
5. kernel/module config, patches, and build scripts;
6. a proof that no Intel/MPSS/SDK payload is present;
7. reproducible binary hashes from two clean builds;
8. a successful hardware smoke and rollback run of the exact publishable image;
9. human legal review of the final artifact.

## Authoritative References

- [GNU GPL 2.0](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
- [GNU LGPL 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html)
- [Linux kernel licensing rules](https://www.kernel.org/doc/html/next/process/license-rules.html)
- [BusyBox license](https://busybox.net/license.html)
- [GCC Runtime Library Exception 3.1](https://www.gnu.org/licenses/gcc-exception-3.1.html)
- [Python 3.12 license](https://docs.python.org/3.12/license.html)
- [OpenSSL release licenses](https://openssl-library.org/source/license/index.html)
- [zlib license](https://www.zlib.net/zlib_license.html)
- [Canonical intellectual-property policy](https://ubuntu.com/legal/intellectual-property-policy)
- [Ubuntu Noble dpkg source package](https://packages.ubuntu.com/source/noble/amd64/dpkg)

## Current Verdict

- Corrected source/BYO-MPSS prerelease RC2: `PASS` and published.
- Existing RC1 source archive: `SUPERSEDED_FOR_LICENSE_TEXT`.
- Current private prebuilt image: `TECHNICALLY_VALIDATED_DO_NOT_PUBLISH`.
- The source-accounted clean stack passed three identical hardware boots with
  final PID 1, SSH, native hello/pthread/dlopen, and stock rollback. This does
  not clear binary redistribution; the kernel and module corresponding-source
  blockers below still apply.
- The August private-payload audit has 2,916 files and 2,448 fail-closed
  findings. Its public-clean profile excludes Python 3.5, Readline, and
  OpenSSL 1.0.x. BusyBox is now technically reproducible byte-for-byte.
- Highest-value binary-release action: build a clean profile without excluded
  legacy payloads, then pin/rebuild the kernel, modules, eglibc, libgcc, and
  remaining userland before any hardware validation of a publishable image.

See [Prebuilt Image Provenance Status](prebuilt-image-provenance.md) and the
machine-readable `prebuilt-clean-profile.json` / `prebuilt-source-ledger.json`.
