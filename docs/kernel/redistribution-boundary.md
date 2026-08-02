# Kernel And Module Redistribution Boundary

The requested prebuilt XPR-OS archive is blocked today.

It cannot include the current stock KNC kernel or the five locally extracted
MPSS module binaries because the project lacks verified corresponding source,
build configuration, patches, and a completed redistribution review. The
current verified release form remains source, metadata, and a bring-your-own
MPSS builder/boot procedure.

This is consistent with `docs/release/xpr-uos-0.1-license-review.md`, which
classifies MPSS boot files and module payloads as local-only until a separate
source and license release is prepared. No firmware, flash, persistent card
storage, stock kernel image, or module binary is committed by this decision.

The next acceptable input is a legally accessible MPSS 3.4.10 corresponding
source package containing the exact KNC kernel and module source lineage.
