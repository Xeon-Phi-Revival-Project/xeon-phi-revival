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
| Tested compatibility kernel | Solros `bda6ce066e514239c9b645fd1ed2a9ffe4f2db33`, source archive hash `0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59`, retained tested config `20f240d00b033c1a0e14ffc8d2023533552adc4040ac0deff3404c79f1f12479`, Linux `COPYING` | B | Bundle exact source/config/build metadata, then reproduce and compare the tested hash before publication |
| Five K1OM modules | `mpss-modules-3.4.10.tar.bz2` hash `0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54`; source RPM metadata says GPLv2; module entry sources declare `MODULE_LICENSE("GPL")` | D | Preserve complete source and inspect each contributing file's header/copyright before binary publication |
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

1. Can the retained Solros source/config/toolchain reproduce the tested
   `d529...` kernel, rather than only a related public-source build? The
   2026-08-10 test completed but produced `ba6c1a...`; `oldconfig` changed the
   retained configuration, so the historical generated/build environment still
   needs reconstruction.
2. Does the complete `mpss-modules-3.4.10` source archive contain clear,
   redistributable license/copyright notices for every source file linked into
   each of the five shipped modules, and can that complete corresponding source
   be bundled with the binary artifacts?
3. Has a qualified human completed the final artifact review after those
   mechanical questions are closed?

Until all three are answered, the permitted public release remains the existing
source/metadata/BYO-MPSS RC2. The local precompiled staging set is useful for
review and reproducibility work, but is not a downloadable release.
