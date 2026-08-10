# Kernel And Module Redistribution Boundary

The requested prebuilt XPR-OS archive is blocked today.

It cannot include the stock KNC kernel or locally extracted MPSS module
binaries. The accepted private RC instead uses an independently reconstructed
compatibility kernel and five rebuilt modules, but their exact source
provenance, corresponding-source bundle, configuration, and redistribution
review are still incomplete. The current verified public release form remains
source, metadata, and a bring-your-own-MPSS builder/boot procedure.

This is consistent with `docs/release/xpr-uos-0.1-license-review.md`, which
classifies MPSS boot files and module payloads as local-only until a separate
source and license release is prepared. No firmware, flash, persistent card
storage, stock kernel image, or module binary is committed by this decision.

The next acceptable inputs are either a legally accessible MPSS 3.4.10
corresponding-source package or a fully reviewed compatibility-source bundle
containing the exact source, configuration, patches, build metadata, and
licenses for the published binaries.
