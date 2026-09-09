# RC7 Candidate G Validation Checkpoint

Candidate G is unpublished and not yet hardware-validated. Its source revision
is `d67ae6f4e3f2519ea8809b03dda0781091fd9ffd`. Candidate F remains historical
evidence; its runtime containers were preserved byte-for-byte in G.

## Frozen Staging Results

| Artifact | Size (bytes) | SHA-256 |
| --- | ---: | --- |
| `xpr-os-0.1.0-rc7.tar.gz` | 20901936 | `9293c0cb689c0262a50a8c0a14c9ee8a57b1f09b8554e38177860780c4938b4d` |
| `xpr-os-0.1.0-rc7-sources.tar.gz` | 383324223 | `3e05ed2ff3920106606fd158b86c51ba295dac9130330ce95d6b4dfea0871dea` |

Two independent staging runs produced identical binary and source archives.
Both passed the precompiled release verifier. Publication-stage root audit:
771 files, zero errors. Embedded SPDX 2.3 validates with nine packages and
63 files, including explicit mappings for the host installer, SSH helper, and
deployment provisioner. All 17 audited card ELF files are K1OM.

Actual private-key payloads, universal authorization keys, Python 3.5 payload,
MPSS SDK binary payload, and standalone toolkit binary payload: zero.
The helper's OpenSSH private-key header parser literal is not key material.
Generic archives contain no generated SSH state.

## SSH Implementation And Host Tests

- `ssh xpr-mic0` selects the invoking user's actual client identity and separate
  `~/.ssh/xpr_os_known_hosts` with strict host-key checking.
- A private per-device ECDSA P-256 server identity is generated on the host and
  provisioned only into private bootstrap/final-root deployment images.
- Client private keys never enter the card image. Server identity and alias
  survive recovery for subsequent installations.
- CentOS 7 Bash/Python 2.7 install/recover fixtures pass: fresh RSA generation,
  identity reuse, idempotence, original user-config preservation, stock trust
  preservation, archive-hash binding, and cross-user reinstall rejection.
- An isolated non-root account test confirms invoking-user ownership and mode
  0600 for SSH configuration. Deployment host-key conversion and actual CPIO
  insertion passed on CentOS without altering the running deployment.
- Python 3 host tests pass all 14 public-key cases and the new CPIO host-key
  permission/non-directory rejection cases.

Lead and Luna reviewed the narrow SSH design. The proposed `Host *` precedence
regression was disproved with `ssh -G` and retracted. A retained limitation is
that a failed installation can leave bounded, reusable XPR alias/trust/key
state; these files are not a multi-file transaction. Stock trust remains
untouched, strict checking remains enabled, and installation errors are not
reported as success. Failure-injection coverage for those writes is pending.

## Hardware Preflight Blocker

Candidate F was recovered with the existing installer. Recovery reported PASS;
stock mic0 is online using the stock MPSS kernel. The restored configuration
SHA-256 is exactly:

`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`

Before G installation, normal `ssh mic0` failed with a host-key mismatch.
The unchanged root known-hosts file hashes to
`ca34f3ea8a34ec96d7fb1c6cdced25978d3a9aa8442f9541c82995c06d46f4b7`.
Its old ECDSA fingerprint is
`SHA256:wwisJpcUT+sNblRcJuRb+b/QRVB2ITQih+pbi7TAQ5Y`.
The stock card presents
`SHA256:jDlU/aLcUHPsKrWg5tYRdWWVLAeeVeeDZ+Z7ZqXvrq8`, matching the
stock public key in the trusted host's MPSS MicDir.

This is a pre-existing stock trust mismatch, not a Candidate G regression.
No trust record has been replaced. Owner permission was requested for a bounded
backup/repair of only the stale stock entries before continuing hardware tests.
Candidate G installation, alias login, reboot/reuse, reinstall, final runtime
regression, and final G recovery have NOT RUN.

## Status

`RC7_CANDIDATE_G=STAGED_HARDWARE_PENDING`

`RC7_PUBLICATION_PREP=BLOCKED_STOCK_SSH_PREFLIGHT`

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

No RC7 tag, public release, or asset upload was created. Do not publish on the
basis of staging results alone.
