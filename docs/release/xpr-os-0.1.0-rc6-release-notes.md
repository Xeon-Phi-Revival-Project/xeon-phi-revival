# XPR-OS 0.1.0-rc6 Candidate

This is an unpublished package-cleanup release candidate. It is not a GitHub
release, tag, or owner publication decision.

RC6 preserves the byte-identical RC5 runtime artifact set: the compatibility
kernel, five K1OM modules, project Base CPIO, nested bootstrap root, and final
root payload. Its changes close the RC5 audit's documentation/package issues:
current release metadata is RC6-consistent, and the public source archive
excludes machine-specific historical reports with developer-local paths.

The generic payload remains key-free. A user supplies one structurally
validated RSA public key only when creating local deployment copies of the
Base CPIO and final payload. No password, private key, or fixed public key is
included in the candidate archive.

The runtime already passed three rollback-protected 5110P boots as RC5. RC6
requires a targeted archive audit before an owner publication decision.
