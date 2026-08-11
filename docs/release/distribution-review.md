# Precompiled Distribution Review

Date: 2026-08-10  
Scope: XPR-OS `0.1.0-rc3` private review candidate

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
| Five K1OM modules | Hash-pinned source archive and GPLv2 `COPYING`; all 24 selected implementation files have GPLv2 evidence; clean dependency map and complete-source staging tool pass | B | Complete source is staged; retain final human review of the grant and exact archives |
| BusyBox 1.19.4 | Pinned upstream source/config/build recipe; source-built binary | B | Include source, config, GPL text, and notices in a future source bundle |
| eglibc runtime | Pinned Ubuntu source baseline and XPR overlay recipe | B | Include orig source, Debian delta, overlays, LGPL text/notices, and relinking material |
| libgcc runtime | Pinned GCC KNC source candidate and build recipe | B | Include exact source/prerequisites/patches and GCC Runtime Library Exception notice |
| Dropbear | Pinned Dropbear 2022.83 source/build recipe | B | Include upstream license and source record |
| Intel MPSS host software, firmware, SDK, stock uOS | Intel-controlled/local input boundary | C | Keep user-supplied and exclude from every public archive |

Classification A means the tracked source may be published. B means the
mechanical source bundle exists but binary redistribution still requires human
review. C is an intentional external prerequisite. D means source-file or
licensing evidence remains incomplete.

## Staged Review Artifacts

The source archive contains the pinned Linux, module, BusyBox, Dropbear,
eglibc, GCC, GMP, MPFR, and MPC archives plus the exact project tree. The
binary archive includes an SPDX 2.3 document covering seven packages and 24
release files. The final payload audit passed with 78 files and zero errors.
Exact post-build archive hashes belong in the external RC3 review report so the
source archive does not contain a recursive claim about its own hash.

## Publication Decision

`CASE_B_HUMAN_REVIEW_REQUIRED`.

The hardware-tested kernel and modules must not be uploaded as a public binary
release yet. The precise remaining questions are:

1. Has a qualified human confirmed that the archive-level GPLv2 `COPYING` and
   direct per-file GPLv2 grants support distribution of the five binaries with
   the mechanically complete staged corresponding source?
2. Has that reviewer inspected the final binary/source archives and notices?

Until both are answered, the permitted public release remains the existing
source/metadata/BYO-MPSS RC2. The local precompiled staging set is useful for
review and reproducibility work, but is not a downloadable release.
