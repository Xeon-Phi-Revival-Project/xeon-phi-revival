# Candidate Module Build

The externally supplied `mpss-modules-3.4.10.tar.bz2` source archive
(`0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54`)
built unpatched against the public K1OM 3.5.1 candidate with:

```sh
make -C KERNEL_SOURCE O=KERNEL_BUILD M=MODULE_SOURCE \
  ARCH=k1om CROSS_COMPILE=k1om-mpss-linux- MIC_CARD_ARCH=k1om modules
```

The package Kbuild produced all card modules; this track evaluates only the
required `dma_module`, `ringbuffer`, `micscif`, `mpssboot`, and
`intel_micveth` objects. All five are ELF64 little-endian `Intel K1OM`.
No patches, installation, module load, or card operation occurred.

Use [build-candidate-mpss-modules.sh](../../tools/kernel/build-candidate-mpss-modules.sh)
with separately obtained source and kernel-build paths. Generated objects stay
outside the repository.
