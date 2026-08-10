# KNC Module Source Audit

Date: 2026-08-01

## Required Runtime Modules

The live minimal project boot requires `ringbuffer.ko`, `dma_module.ko`,
`micscif.ko`, `mpssboot.ko`, and `intel_micveth.ko`, all with vermagic
`2.6.38.8+mpss3.4.10` and K1OM ELF architecture.

## Observed Lineage

The local modules are part of the installed MPSS card-side module tree. Their
metadata reports GPL licenses and the dependency graph documented in
`docs/uos/mpss-module-boundary.md`. A local GPLv2 MPSS 3.4.10 source RPM was
found with relevant sources and Kbuild files; see
`docs/kernel/source-package-provenance.md`. It remains unvalidated until built
against the exact KNC kernel source and compared with the working modules.

## Publication Decision

Do not distribute these module binaries in an XPR-OS archive. The project may
continue to use them as user-supplied local MPSS inputs for lab validation.
Source-built replacement modules require verified corresponding source and an
exactly matching project kernel build.

## Recovered 3.4.10 Source Composition

On 2026-08-09 the retained `mpss-modules-3.4.10.tar.bz2` source input was
re-extracted into a private audit directory. Its SHA-256 is:

```text
0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54
```

The source `Kbuild` files identify the input objects below. All listed module
entry sources declare `MODULE_LICENSE("GPL")`; this is source evidence, not a
final redistribution determination.

| Output | Kbuild source objects | GPL declaration observed in |
| --- | --- | --- |
| `dma_module.ko` | `mic_dma_lib.o`, `mic_dma_md.o`, `mic_sbox_md.o` | `dma/mic_dma_lib.c` |
| `ringbuffer.ko` | `micscif_rb.o` | `micscif/micscif_rb.c` |
| `micscif.ko` | `micscif_main.o`, `micscif_sysfs.o`, `micscif_smpt.o`, `micscif_intr.o`, `micscif_api.o`, `micscif_fd.o`, `micscif_nodeqp.o`, `micscif_va_node.o`, `micscif_va_gen.o`, `micscif_rma.o`, `micscif_rma_list.o`, `micscif_rma_dma.o`, `micscif_debug.o`, `micscif_ports.o`, `micscif_select.o`, `micscif_nm.o` | `micscif/micscif_main.c` |
| `mpssboot.ko` | `mpssboot.o` | `mpssboot/mpssboot.c` |
| `intel_micveth.ko` | `micveth.o`, `micveth_param.o`, `micveth_dma.o` | `vnet/micveth.c`, `vnet/micveth_dma.c` |

The matching candidate kernel source/build directory was no longer retained on
the host, so this source audit does not claim a fresh module binary rebuild.
The preserved candidate build log records the required precondition: recover
the exact candidate source archive and normalized config, then build these
objects against its `Module.symvers` before any public-image integration.
