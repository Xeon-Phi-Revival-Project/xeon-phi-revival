# Development

This section is for work on XPR itself. If you only want to run XPR-OS, use
[Getting Started](../getting-started/README.md) instead.

## Current Engineering References

- [Build XPR-OS](../release/build-xpr-os-rc-from-source.md)
- [Architecture](../architecture/README.md)
- [Observed K1OM ELF ABI](../architecture/observed-k1om-elf-abi.md)
- [Kernel research and reconstruction](../kernel/README.md)
- [uOS/bootstrap research](../uos/README.md)
- [K1OM toolchain research](../toolchain/README.md)
- [Ubuntu/K1OM port research](../ubuntu-port/README.md)
- [Reproducibility](release-reproducibility.md)
- [Source Index](../source-index.md)

## xpr-init

The current host integration is documented for users in
[xpr-init Host Integration](../getting-started/xpr-init-preview.md).

Future ideas and validation tasks are intentionally kept out of the beginner
path in the [xpr-init Future Changes](xpr-init-future-changes.md) backlog. Items
in that document are **not implemented features** until code and appropriate
host/hardware validation say otherwise.

## Legacy And Experimental Development Paths

[From Card To Code](../getting-started-card-to-code.md) preserves the historical
MPSS/K1OM SDK development path and related experiments. Treat it as a development
and research reference, not as the recommended XPR-OS installation guide.

Deep experiments, failed approaches, and superseded plans belong under the
[Research index](../research/README.md), where they can remain useful without
being mistaken for current instructions.
