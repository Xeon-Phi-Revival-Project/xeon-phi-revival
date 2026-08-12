# Release Reproducibility

RC6 was packaged twice with byte-identical binary and source archives. The
published release includes hashes, SPDX, notices, corresponding-source material,
and artifact manifests. See the [RC6 targeted audit](../release/xpr-os-0.1.0-rc6-targeted-audit.md)
and [release provenance](../release/prebuilt-image-provenance.md).

The release toolchain fails closed on missing or mismatched declared inputs.
It does not package Intel MPSS binaries, firmware, or developer-local CPIO
inputs.

