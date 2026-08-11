# XPR-OS 0.1.0-rc5 Candidate

This is an unpublished release-engineering candidate. It is not a GitHub
release, tag, or owner publication decision.

RC5 replaces the RC4 release-construction paths with source-accounted bootstrap
and final-root builders, strict deployment SSH public-key validation, generated
artifact metadata, and release-level SPDX container coverage.

The RC5-generated Base CPIO and final-root payload passed three identical
rollback-protected deployments on the tested Xeon Phi 5110P path. This remains
an unpublished release candidate pending the independent RC5 audit and owner
publication decision.

The generic payload is key-free. A user supplies one validated RSA public key
only when making local deployment Base CPIO and final-payload artifacts; no
password, private key, or fixed public key is included in the candidate archive.
