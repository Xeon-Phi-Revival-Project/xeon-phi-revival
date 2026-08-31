# XPR-OS 0.1.0-rc7 Publication Checklist

This is an owner-operated checklist. Completing it may authorize publication;
this document does not itself authorize or perform a tag, release, or upload.

Proposed `v0.1.0-rc7` tag target:
`4987a9b4a51e2151090925448a0e4b54c98c0d30` (`Finalize RC7 publication metadata`).
That commit contains the finalized validation record, release notes, manifest,
artifact inventory, and checksum reference. This later operational checklist
does not change the proposed release contents.

- [ ] Owner approves XPR-OS 0.1.0-rc7 publication.
- [x] Binary SHA-256 matches the hardware-validated candidate.
- [x] Corresponding-source SHA-256 matches the validated source archive.
- [x] SPDX 2.3 sidecar validation is confirmed.
- [x] Licenses and notices sidecar is present and validated.
- [x] The four-asset `SHA256SUMS` file verifies successfully.
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
```

Current boundary:

```text
XPR_OS_RC7_CANDIDATE=TECHNICALLY_PASS
RC7_PUBLICATION_PREP=PASS
RC7_PUBLICATION=AWAITING_OWNER_AUTHORIZATION
TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW
```
