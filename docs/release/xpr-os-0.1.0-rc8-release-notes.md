# XPR-OS v0.1.0-rc8 Candidate

This is an unpublished release candidate for legacy Intel Xeon Phi Knights
Corner hardware. It is not a release announcement or publication approval.

## Candidate scope

- Reconstructs the public bootstrap and final-root containers from
  source-accounted inputs.
- Includes CPython 3.12.13 at `/usr/bin/python3.12`; `python3` and `python`
  resolve to that interpreter.
- Keeps the deployment-specific SSH key model and `xpr-init` recovery path.

The separately packaged XPR K1OM Toolkit remains excluded from this candidate
while its standalone distribution review is held for qualified human review.

## Publication boundary

Candidate hashes, source-delivery material, static audits, and any hardware
validation are recorded outside the immutable archive. Publication requires an
explicit owner decision after those records are complete.
