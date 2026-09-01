# XPR-OS 0.1.0-rc7 Publication Checklist

This is an owner-operated checklist. Completing it may authorize publication;
this document does not itself authorize or perform a tag, release, or upload.

Proposed `v0.1.0-rc7` tag target:
`e7341413d102718ecccb51f3744f80a1dbdc55af` (`Align RC7 owner authorization boundary`).
That commit and its parents contain the finalized Candidate F validation
record, release notes, manifest, artifact inventory, publication decisions,
checksum reference, and normalized hardware transcript. This later operational
checklist does not change the proposed release contents.

- [ ] Owner approves XPR-OS 0.1.0-rc7 publication.
- [x] Binary SHA-256 matches the hardware-validated candidate.
- [x] Corresponding-source SHA-256 matches the validated source archive.
- [x] SPDX 2.3 sidecar validation is confirmed.
- [x] Licenses and notices sidecar is present and validated.
- [x] The four-asset `SHA256SUMS` file verifies successfully.
- [x] Independent Candidate F staging produced byte-identical binary and source archives.
- [x] Strict publication-stage payload/SPDX audit passed with 771 files and 0 errors.
- [x] Candidate F contains archive-hash-bound `xpr-init` extraction behavior.
- [x] The [hardware validation record](xpr-os-0.1.0-rc7-validation.md) is final.
- [x] The held standalone toolkit binary is excluded from RC7 assets.
- [ ] Owner reviews and approves the [release notes draft](xpr-os-0.1.0-rc7-release-notes.md).
- [x] Proposed tag target commit is recorded and verified above.
- [ ] GitHub release is explicitly marked as a prerelease.

Final non-destructive audit:

```text
BINARY_HASH_MATCH=PASS
SOURCE_HASH_MATCH=PASS
SPDX_VALIDATION=PASS
NOTICES_PRESENT=PASS
SHA256SUMS=PASS
VALIDATION_RECORD=PASS
TOOLKIT_BINARY_EXCLUDED=PASS
PUBLICATION_STAGE_AUDIT=PASS
RC7_BUILD_AB=PASS
XPR_INIT_HASH_BOUND_CACHE=PASS
```

Current boundary:

```text
XPR_OS_RC7_CANDIDATE=TECHNICALLY_PASS
RC7_PUBLICATION_PREP=PASS
RC7_PUBLICATION=AWAITING_OWNER_AUTHORIZATION
TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW
```
