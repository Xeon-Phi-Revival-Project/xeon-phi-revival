# XPR-OS 0.1.0-rc5 Candidate

This is an unpublished release-engineering candidate. It is not a GitHub
release, tag, or owner publication decision.

RC5 replaces the RC4 release-construction paths with source-accounted bootstrap
and final-root builders, strict deployment SSH public-key validation, generated
artifact metadata, and release-level SPDX container coverage.

Hardware validation is pending for the RC5-generated Base CPIO and final-root
payload. Do not describe this candidate as hardware validated until the bounded
RC5 deployment and rollback evidence has been recorded against its exact hashes.

The generic payload is key-free. A user supplies one validated RSA public key
only when making a local deployment payload; no password or private key is
included in the candidate archive.
