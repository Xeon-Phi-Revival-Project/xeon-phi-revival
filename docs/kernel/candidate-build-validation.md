# First Buildable K1OM Kernel Candidate

## Scope

This is a host-only source build. It did not run `micctrl`, alter an MPSS
configuration, reset `mic0`, boot a kernel, or touch firmware or persistent
card storage.

## Candidate

| Field | Value |
| --- | --- |
| Public repository | `https://github.com/cosmoss-jigu/solros` |
| Revision | `bda6ce066e514239c9b645fd1ed2a9ffe4f2db33` |
| Candidate subtree | `phi-kernel` |
| Candidate label | `linux-2.6.38+mpss3.5.1` |
| Downloaded source archive SHA-256 | `0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59` |
| Cross compiler | local MPSS 3.4.10 `k1om-mpss-linux-gcc` (GCC 4.7.0) |

The tree contains a Linux `COPYING` file and real K1OM build support:
`ARCH=k1om` selects `elf64-k1om`, uses the `x86_64-k1om` tool architecture,
and enables K1OM defaults in `arch/x86/Kconfig`. It includes the historical
`k1om.uconfig`, `mic-min.uconfig`, and `mic-mpss.uconfig` fragments.

The committed tree does not contain the `k1om_defconfig` referred to by its
Kconfig. For this validation only, an externally supplied private copy of the
installed MPSS 3.4.10 K1OM config was normalized with `oldconfig`. No config,
source archive, or build artifact is committed here.

## Build Evidence

The out-of-tree build used the source tree with:

```sh
yes "" | make ARCH=k1om CROSS_COMPILE=k1om-mpss-linux- O=BUILD oldconfig
make -j2 ARCH=k1om CROSS_COMPILE=k1om-mpss-linux- O=BUILD bzImage
```

The `bzImage` build completed in 263 seconds. The build output reported:

```text
Kernel: arch/x86/boot/bzImage is ready (#1)
2.6.38.8+mpss3.5.1
```

| Artifact | SHA-256 |
| --- | --- |
| `bzImage` | `0450c4370fb9c023c5229274d9a7a5cc02b8a37838c3220a0c714fc602cb2505` |
| `vmlinux` | `3460c0b44e2136e572312d588da8fbcb9e3382a546be1857a340dc22f0ee0e27` |
| `System.map` | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` |
| normalized private config | `28b8f22589f5a79a703772bd4fdba401c9c562048277371bde0c77ab92bd3246` |

`readelf -h vmlinux` reported:

```text
Class: ELF64
Data:  2's complement, little endian
Machine: Intel K1OM
Entry point address: 0x1000000
```

The normalized configuration contained:

```text
CONFIG_MK1OM=y
CONFIG_X86_MICPCI=y
CONFIG_BLK_DEV_INITRD=y
CONFIG_MODULES=y
CONFIG_NET=y
CONFIG_HVC_MIC=y
```

## Boundary and Next Check

This is an independent MPSS 3.5.1 compatibility reconstruction, not an exact
MPSS 3.4.10 rebuild. Its `2.6.38.8+mpss3.5.1` release does not match the
installed `2.6.38.8+mpss3.4.10` kernel. The current five external module
objects must therefore not be loaded with this image.

The next narrowly scoped technical check is to build the five already-audited
module sources against this candidate and inspect their K1OM ELF metadata,
vermagic, dependency graph, and unresolved symbols. Only after that check can
an alternate-config, RAM-only `micctrl` boot experiment be considered.

## License and Provenance

The public repository does not declare a top-level license. Although the
candidate tree contains Linux GPLv2 text, this project does not redistribute
the source tree, generated image, or any external MPSS module. Users must
obtain all such inputs independently until a source-provenance and
redistribution review is complete.

## 2026-08-09 Clean Source Reconstruction

The same Solros revision was re-downloaded from the public repository and its
archive hash matched the recorded value exactly:

```text
0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59
```

Unlike the earlier validation, this reconstruction used the public tree's
`config/config-phi-kernel` (`fc406d6d95527a8b01f36c1acd861f28ce552be88df7324eabd60542525d78c7`),
then `oldconfig` produced
`2f6cee5cf43d6bf68649de1b05f1c784918b4eb5b874afa2c8850809b8cb267e`.
The deterministic build script completed and emitted K1OM artifacts:

| Artifact | SHA-256 |
| --- | --- |
| `bzImage` | `f59b6237fa204b62acd5e6930b4bc57bd7936a91be2d0c3fb126cc2508629583` |
| `vmlinux` | `d25ed300e0bde27a3a09cde07dea5096ea4edee31c597978db257fdfc03a04c8` |
| `System.map` | `2a2dabf5305f43b95fa40abe18e7ebdc801a48c5bf21ff05d927fe7b0f5b5673` |

These hashes differ from the retained private hardware-validation reference.
That difference is expected until the exact normalized historic configuration
and reproducibility controls are reconciled. This public-source rebuild has
not been booted and must not replace the known-good kernel.

## Retained Tested Configuration

The host still retains the exact `.config` used to produce the hardware-tested
kernel `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8`.
It is now tracked as
[`configs/kernel/k1om-solros-tested.config`](../../configs/kernel/k1om-solros-tested.config)
with SHA-256
`20f240d00b033c1a0e14ffc8d2023533552adc4040ac0deff3404c79f1f12479`.

The configuration enables `CONFIG_MK1OM`, `CONFIG_X86_MICPCI`, initramfs,
modules, networking, and `CONFIG_HVC_MIC`. This closes the missing-config
record but does not by itself prove a clean rebuild reproduces `d529...`.
That comparison and a complete source bundle remain required before binary
publication.

## 2026-08-10 Tested-Config Rebuild

An isolated build used the retained Solros tree, the retained tested `.config`,
the local MPSS 3.4.10 K1OM GCC 4.7.0 prefix, and `KBUILD_BUILD_VERSION=1`.
It completed as a K1OM kernel but did **not** reproduce the hardware-tested
image:

| Artifact | Tested SHA-256 | Clean rebuild SHA-256 |
| --- | --- | --- |
| `bzImage` | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` | `ba6c1a99c88f52264f785ac03ddfa0fae075b4041bbd07be3da047518854f654` |
| `vmlinux` | `b96b976f2eac4da888edef36fea8234efc97b00160a72da595d5ed048021991e` | `3da0839fd64c0137175aa38ab6c9ac760a7a8c466d3f68a8317016b2fcd392b3` |
| `System.map` | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` | `a3e1e68f78d697593edd96ad2abca0b3ba8b7f4970236f37be4f9aa1631739d7` |

`oldconfig` normalized the retained input from `20f240...` to
`57bbada012a7320e655550fe3b93c238ddf9a6f97d35d3b8338f6227e14ac893`.
The exact historical build environment or pre-`oldconfig` generated state is
therefore still missing. This confirms the binary release hold: do not publish
`d529...` as corresponding to the current reproducible source recipe.

## Binary Differential Result

The retained and normalized `.config` files differ only in the generated
timestamp comment. The kernel difference is consequently not explained by that
timestamp or by `bzImage` compression metadata. A section-level comparison of
the two `vmlinux` files found different executable and semantic-data sections:

| Section | Tested | Clean rebuild | Result |
| --- | --- | --- | --- |
| `.text` | 3,526,555 bytes | 3,526,555 bytes | same size, different SHA-256 |
| `.rodata` | 1,183,906 bytes | 1,215,154 bytes | size and content differ |
| `__modver` | 2,736 bytes | 4,256 bytes | size and content differ |
| `.init.text`, `.init.data`, `.data` | same sizes | same sizes | different SHA-256 values |

The clean build did use the same K1OM GCC major version, but these differences
show that an unrecorded source-tree, generated-header, or build-environment
input affected code generation or linked content. The exact `d529...` kernel
is therefore not yet reproducibly attributable to the current source recipe.

## Historical-Tree Forensics

The retained historical source path was then rebuilt out of tree. A targeted
comparison found no content difference in compilable source, header, Kbuild,
or Kconfig files against the archived Solros tree. Its source-root path is
nevertheless build-relevant because old kernel code embeds `__FILE__` strings
and their linked addresses.

That historical-path rebuild produced the exact tested hashes for the semantic
sections and link map:

| Item | Tested | Historical-tree rebuild |
| --- | --- | --- |
| `.text` SHA-256 | `d3fcfb984c7fa466a48ecc1f3d30c9fd8dec97de606e727f3d7e1850e7f39104` | identical |
| `__modver` SHA-256 | `d583ce16fb8fe716f022d2fb503cca88e944114f5375ac289dd12d7da61a51d8` | identical |
| `System.map` SHA-256 | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` | identical |

`Module.symvers` was also byte-identical between the retained and clean
builds, so module-version generation is not the unresolved input. The first
clean-tree divergence is `linux_banner` in `.rodata`; its build timestamp
shifts linked data and relocation immediates in `ident_complete`.

The remaining whole-image blocker is historical Kbuild metadata. The retained
artifact records a build-start banner timestamp and a later generated
`compile.h` time. Rebuilding regenerates `compile.h` and increments the build
version; copying the retained header before relinking is overwritten by Kbuild.
The next exact action is to pin the historical source-root path and control or
patch the old `mkcompile_h`/build-version generation so both fields are
recreated without regeneration. No source-code or module-CRC delta remains.

## 2026-08-10 Metadata Preservation Check

The retained historical output directory has since regenerated
`include/generated/compile.h` to `UTS_VERSION "#2 SMP Mon Aug 10 17:57:13
EDT 2026"`; it is not the original generated header. The expected validated
`bzImage` was also no longer present at the previously recorded private
reference path, so a controlled `mkcompile_h` relink was not started. The
temporary source-script backup trap restored the source tree unchanged.

The next reproduction attempt must first preserve or recover the actual
hardware-tested `bzImage`, original `compile.h`, and `.version` state, then
override old Kbuild metadata generation before a minimal relink. Without those
inputs, byte-for-byte reproduction cannot be claimed.

## 2026-08-10 Controlled Metadata Relink

The validated artifacts were subsequently recovered at
`/root/xpr-kernel-candidate-solros-build-validated`: `bzImage` is exactly
`d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8`,
`vmlinux` is `b96b976f2eac4da888edef36fea8234efc97b00160a72da595d5ed048021991e`,
and its generated header records build `#1`, `Sat Aug 1 22:34:49 EDT 2026`.

One controlled relink used the retained historical source-root path, restored
`.version` to `1`, and supplied that exact header through a temporary source
tree `scripts/mkcompile_h` override. It produced `vmlinux`
`694a0f6f19e94ddb34be8d81143d7aa59513fdf08cc6d3258a8d26fed40405fb` and
`bzImage` `4a97ac90a87a7da207a7ebec2422645f44499483ee22697c4e104390e17646c1`:
neither matched. The output header remained build `#2` with the Aug 10 time.
The source script restoration hash matched its pre-test hash.

The out-of-tree build has no separate `O=scripts/mkcompile_h`: it invokes the
source-tree helper with the output header path as its first argument. The first
override was ignored because the existing output header was up to date. A
forced regeneration then proved the helper was invoked, but the temporary
replacement wrote the recovered header to standard output rather than its
required `$1` target; `init/version.o` correctly failed because the target
header was absent. The pre-test output header and source helper were restored.

The next smallest experiment is now exact: preserve `.version=1`, remove the
output header, and stage a temporary source-tree helper that writes the
recovered validated header to `"$1"`. It must preserve the validated source-root
path and compiler path. No further broad kernel rebuild is justified.
