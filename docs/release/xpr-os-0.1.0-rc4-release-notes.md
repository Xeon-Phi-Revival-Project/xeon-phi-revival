# XPR-OS 0.1.0-rc4 Candidate

This is a private release-engineering candidate, not a published release.
It supersedes RC3 only for audit remediation and does not modify the frozen RC3
archives.

## RC4 changes

- The corresponding-source archive verifies the exact LF-byte hashes of the
  tested kernel and BusyBox configurations before and after staging.
- The kernel reproducer is self-contained: it extracts a supplied source archive
  into a controlled work root and does not require Git or historical `/root`
  build paths.
- SPDX generation uses valid SPDX 2.3 license expressions, extracted licensing
  information for Dropbear, and machine-validated download locations.
- The binary archive carries third-party license texts, a notices manifest, and
  a SHA-256 binding to its paired source archive.
- The generic public payload contains no `authorized_keys`. A separate
  `tools/provision-authorized-key.py` creates a deployment-specific payload from
  a supplied public key after strict key validation.

## Status

`AUTOMATED_CHECKS_PASS_HUMAN_LEGAL_REVIEW_PENDING`.

The frozen RC4 artifact set completed two independent byte-identical staging
builds and three rollback-protected hardware boots on the tested 5110P path.
Each boot reached the provisioned final root, project PID 1, micveth,
authenticated final-root Dropbear SSH, and the dynamic hello, pthread, and
`dlopen` probes. Each rollback restored stock MPSS, stock SSH, and the exact
stock configuration hash. See
[RC4 Validation](xpr-os-0.1.0-rc4-validation.md).

RC4 is still not a published release: qualified human legal review of the
frozen binary/source archives and module provenance bundle remains required.

## Host prerequisite

Users supply Intel MPSS 3.4.10 separately under its own terms. RC4 must not
contain MPSS host packages, stock card-side userspace, firmware, credentials,
or private keys.
