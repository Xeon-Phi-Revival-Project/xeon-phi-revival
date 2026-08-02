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
