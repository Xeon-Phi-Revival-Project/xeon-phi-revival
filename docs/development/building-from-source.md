# Building XPR-OS From Source

The paired RC6 source archive contains pinned upstream inputs, project scripts,
configs, and source maps. It is the starting point for reproducibility work;
the public binary archive alone is not a compiler SDK.

Use [Build XPR-OS RC From Source](../release/build-xpr-os-rc-from-source.md)
for the current detailed process. The build has separate kernel, module,
BusyBox, eglibc, libgcc, bootstrap, final-root, and packaging stages. Keep all
locally obtained MPSS/toolchain material outside the repository and pass it as
explicit input.

The current project claim is reproducible construction from declared inputs,
not universal byte-identical reproduction on arbitrary host versions.

