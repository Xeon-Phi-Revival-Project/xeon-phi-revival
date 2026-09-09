# XPR-OS 0.1.0-rc7 Publication Checklist

This is an owner-operated checklist. Completing it may authorize publication;
this document does not itself authorize or perform a tag, release, or upload.

Final candidate: G2, built from
`079521e895b82fb3ccec2fe0b29cfb3ea0e1bb1d`. The former Candidate F tag proposal
is superseded. The owner must select and explicitly authorize a tag target
containing the final G2 evidence; no tag is created by this checklist.

- [ ] Owner approves XPR-OS 0.1.0-rc7 publication.
- [x] Binary SHA-256 matches the hardware-validated candidate.
- [x] Corresponding-source SHA-256 matches the validated source archive.
- [x] SPDX 2.3 sidecar validation is confirmed.
- [x] Licenses and notices sidecar is present and validated.
- [x] The four-asset `SHA256SUMS` file verifies successfully.
- [x] Independent Candidate G2 staging produced byte-identical binary and source archives.
- [x] Strict publication-stage payload/SPDX audit passed with 771 files and 0 errors.
- [x] Candidate G2 contains archive-hash-bound `xpr-init` extraction and isolated persistent SSH identity.
- [x] The [hardware validation record](xpr-os-0.1.0-rc7-candidate-g-validation.md) is final.
- [x] The held standalone toolkit binary is excluded from RC7 assets.
- [ ] Owner reviews and approves the [release notes draft](xpr-os-0.1.0-rc7-release-notes.md).
- [ ] Owner selects and approves the final tag target.
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
