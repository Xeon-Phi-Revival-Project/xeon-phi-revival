# Documentation

The XPR documentation is organized around one rule: **current user guidance and
historical research should never look like the same thing**.

If you are trying to run XPR-OS, start with the short current path below. If you
are researching Knights Corner, K1OM, MPSS, uOS, or the history of the revival,
use the research indexes instead of treating old experiment notes as install
instructions.

## Run XPR-OS

For the hardware-validated Intel Xeon Phi 5110P + CentOS 7.4 + MPSS 3.4.10
configuration:

1. [Getting Started](getting-started/README.md) — the current beginner path.
2. [MPSS host setup](getting-started/mpss-setup.md) — establish a working stock baseline first.
3. [xpr-init host integration](getting-started/xpr-init-preview.md) — recommended install, automatic handoff, and recovery workflow.
4. [SSH access](getting-started/ssh-access.md) — keys, authentication, and the bootstrap/final-root transition.
5. [Verify XPR-OS](getting-started/verifying-xpr-os.md) — confirm that the final root is actually running.
6. [Rollback](getting-started/rollback.md) — return to the saved stock MPSS configuration.
7. [Troubleshooting](troubleshooting/README.md) — current user-facing failure paths.

The longer [manual installation procedure](getting-started/installation.md) is
kept for advanced troubleshooting and for understanding the underlying RC6 boot
path. It is not the preferred beginner workflow.

## Understand The Project

- [Concepts](concepts/README.md) — Knights Corner, K1OM, MPSS, boot flow, and terminology.
- [Architecture](architecture/README.md) — current XPR-OS architecture and observed ABI details.
- [Hardware](hardware/README.md) — tested hardware, lab evidence, and compatibility boundaries.
- [FAQ](faq.md) — practical project and beginner questions.
- [Glossary](glossary.md) — the single canonical terminology reference.
- [Project Status](status.md) — what is validated now, what is experimental, and what remains future work.

## Develop Or Extend XPR

- [Development index](development/README.md)
- [Build XPR-OS](release/build-xpr-os-rc-from-source.md)
- [Kernel and modules](kernel/README.md)
- [K1OM toolchain research](toolchain/README.md)
- [uOS and bootstrap research](uos/README.md)
- [Ubuntu/K1OM port research](ubuntu-port/README.md)
- [xpr-init future changes](development/xpr-init-future-changes.md) — backlog only; ideas here are not implemented until validated.
- [Source Index](source-index.md) — provenance and source mapping.
- [Reproducibility](development/release-reproducibility.md)

## Research And Historical Record

The repository intentionally preserves failed experiments, old plans, reverse
engineering notes, vendor-era observations, and superseded approaches because
they are useful evidence. They are indexed under [Research](research/README.md),
with dated project/planning checkpoints under [Historical Project Records](research/history/README.md).

Do **not** use a document merely because it contains a command. Check whether it
is in the current Getting Started path or is explicitly marked as research,
historical, experimental, or advanced.

## Evidence And Reproducibility

- [Manifests](../manifests/README.md) — experiment, hardware, and release evidence.
- [Artifacts](../artifacts/README.md) — generated inspection/audit outputs retained as evidence.
- [Release records](release/README.md) — RC validation and publication records.
- [Research index](research/README.md) — deep technical evidence and historical investigations.

## Maintainers

The deliberately small active-doc surface is checked with:

```bash
python3 tools/docs/validate-active-docs.py
```

When promoting an experimental result into current documentation, update the
status/validation evidence at the same time. When guidance becomes obsolete but
still has research value, move it into the historical/research structure rather
than silently deleting the record.
