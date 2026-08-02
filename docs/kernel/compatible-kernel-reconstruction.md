# Experimental Compatible KNC Kernel Reconstruction

This is an independent compatibility reconstruction track. It is not an
MPSS 3.4.10 source reproduction and must not be described as one.

The objective is a source-available K1OM kernel that `micctrl` can boot with
the project Base CPIO, rootfs, five required modules, readiness path, and
virtual networking. The exact-source recovery track remains open.

## Candidate Inventory

The local MPSS 3.8.6 archive was inspected read-only:

```text
archive SHA-256: fce922dd0fc62e0a7f3afb431f870d71679e76d82f2db867cb03c45584f548f3
```

It contains binary `mpss-boot-files` and host-module RPMs, not a KNC kernel
source tree, config, or K1OM patch series. It is rejected as a build baseline.

The local GPLv2 MPSS 3.4.10 module source remains a module candidate only.

The first complete source-available candidate was found in the public
[`cosmoss-jigu/solros`](https://github.com/cosmoss-jigu/solros) repository:

```text
repository revision: bda6ce066e514239c9b645fd1ed2a9ffe4f2db33
archive SHA-256:     0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59
tree:                phi-kernel
candidate label:     linux-2.6.38+mpss3.5.1
```

It is a complete Linux tree with `arch/x86` K1OM support, K1OM ELF selection,
and the historical `k1om.uconfig`, `mic-min.uconfig`, and `mic-mpss.uconfig`
fragments. It is the current independent compatibility-build baseline. The
candidate was built successfully with the local MPSS 3.4.10 cross compiler;
see [candidate-build-validation.md](candidate-build-validation.md).

The repository has no declared top-level license. `phi-kernel/COPYING` is the
Linux GPLv2 text, but the public GitHub copy is not evidence of Intel's
corresponding-source offer or its exact provenance. Treat it as a research
reference and build input obtained separately, not as code to import or
redistribute from this project.

The five required MPSS 3.4.10 module sources now build unpatched against the
candidate and have complete static symbol closure. The current decision remains
`INSUFFICIENT_EVIDENCE`, because host MPSS 3.4.10 to candidate-kernel 3.5.1
boot-protocol compatibility has not been established. No candidate boot was run.
