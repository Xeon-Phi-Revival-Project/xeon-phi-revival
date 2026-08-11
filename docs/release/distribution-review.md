# Precompiled Distribution Review

Date: 2026-08-10  
Scope: XPR-OS `0.1.0-rc1` hardware-tested artifact set

This is an engineering provenance review, not legal advice. It records what is
known from retained build metadata, source-package metadata, source headers,
and license files. `hold-human-review` is deliberately not a publication
approval.

## Frozen Hardware Set

The exact artifacts from the three successful boots are recorded in
[`xpr-os-0.1.0-rc1-tested-artifacts.json`](../../manifests/release/xpr-os-0.1.0-rc1-tested-artifacts.json).
Do not substitute a later rebuild and describe it as hardware validated.

## Component Decisions

| Component | Evidence | Classification | Release action |
| --- | --- | --- | --- |
| XPR source, scripts, init, helpers | Tracked repository source under MIT | A | Publish source and notices |
| Tested compatibility kernel | Solros `bda6ce066e514239c9b645fd1ed2a9ffe4f2db33`, archive `0e8769...`, tested config `20f240...`, Linux GPLv2 `COPYING`, and deterministic wrapper now reproduce `d529...` byte-for-byte | B | Include complete kernel source, config, generated metadata inputs, wrapper, GPL text, and build information in the source bundle |
| Five K1OM modules | Hash-pinned `mpss-modules-3.4.10.tar.bz2` with GPLv2 `COPYING`; every Kbuild-selected implementation source has an Intel copyright/GPLv2 notice; per-module map is tracked | B | Bundle the complete source archive, capture clean-build header dependencies, and retain human review before binary publication |
| BusyBox 1.19.4 | Pinned upstream source/config/build recipe; source-built binary | B | Include source, config, GPL text, and notices in a future source bundle |
| eglibc runtime | Pinned Ubuntu source baseline and XPR overlay recipe | B | Include orig source, Debian delta, overlays, LGPL text/notices, and relinking material |
| libgcc runtime | Pinned GCC KNC source candidate and build recipe | B | Include exact source/prerequisites/patches and GCC Runtime Library Exception notice |
| Dropbear | Pinned Dropbear 2022.83 source/build recipe | B | Include upstream license and source record |
| Intel MPSS host software, firmware, SDK, stock uOS | Intel-controlled/local input boundary | C | Keep user-supplied and exclude from every public archive |

Classification A means the tracked source may be published. B means binary
redistribution has remaining mechanical source-bundle work. C is an intentional
external prerequisite. D means the project has not completed the source-file
and licensing review needed to make a binary distribution conclusion.

## Publication Decision

`CASE_B_HUMAN_REVIEW_REQUIRED`.

The hardware-tested kernel and modules must not be uploaded as a public binary
release yet. The precise remaining questions are:

1. Can the complete hash-pinned `mpss-modules-3.4.10` source archive, including
   the headers selected by a clean build, be assembled as the corresponding
   source bundle for the five modules? The Kbuild-selected implementation
   sources and GPLv2 evidence are mapped, but that delivery check remains.
2. Has a qualified human completed the final artifact review after those
   mechanical questions are closed?

Until all three are answered, the permitted public release remains the existing
source/metadata/BYO-MPSS RC2. The local precompiled staging set is useful for
review and reproducibility work, but is not a downloadable release.
