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
the host when this audit began. The preserved candidate build log identified
the necessary next action: recover the candidate source archive and a
configuration, then build these objects against its `Module.symvers` before any
public-image integration.

## 2026-08-09 Public-Source Module Build

That precondition has now been met for the recovered public Solros source and
its public `config/config-phi-kernel` reconstruction. The five required modules
built successfully as K1OM against the clean build's `Module.symvers`; all
report `2.6.38.8+mpss3.5.1 SMP mod_unload` and GPL metadata.

| Module | SHA-256 |
| --- | --- |
| `dma_module.ko` | `af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a` |
| `ringbuffer.ko` | `e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068` |
| `micscif.ko` | `0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2` |
| `mpssboot.ko` | `a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894` |
| `intel_micveth.ko` | `0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60` |

No module or kernel from this clean reconstruction has been loaded or booted.
The next technical gate is a clean runtime, then a bounded alternate-config
hardware test with the rebuilt kernel and modules.
