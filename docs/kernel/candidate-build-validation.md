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
