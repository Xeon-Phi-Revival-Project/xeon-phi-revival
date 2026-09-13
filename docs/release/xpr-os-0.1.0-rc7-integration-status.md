# XPR-OS 0.1.0-rc7 Integration Status

## Current Candidate

`XPR_OS_RC7_CANDIDATE=TECHNICALLY_PASS`

The exact unpublished Candidate G2 archive is:

- `xpr-os-0.1.0-rc7.tar.gz`
- SHA-256 `6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c`

Its paired source archive SHA-256 is
`9d1261fd42f87697ee84b3cff749487c92bf11eb9eba952fcf6ead3be6df4c4a`.
Built-in source-policy, payload, strict publication-stage provenance, SPDX 2.3,
license, release-consistency, and archive checks passed. Independent staging
produced byte-identical binary and source archives.

Release-facing sidecars are finalized as:

- SPDX: `xpr-os-0.1.0-rc7.spdx.json`, SHA-256
  `7bd7586fc4064ea01df4e55d85738eba8c3d7d2ff96cbca7f42d7362c49b0e07`
- notices/licenses: `xpr-os-0.1.0-rc7-notices.tar.gz`, SHA-256
  `186c883301997b483ca26921b600f3fc6d1c2e2ed6af221d1c0d00fd77789a0d`
- publication checksums: `SHA256SUMS`, SHA-256
  `8247c9f44f0042778f5d60db942afbf0726d6765df292e87f00cefcc84ef312e`

## Integrated Runtime

The public-clean root is assembled only from current source-built BusyBox,
Dropbear, eglibc, libgcc, tracked XPR helpers, and the exact validated CPython
3.12.13 core package. It contains:

- `/usr/bin/python3.12`
- `/usr/bin/python3` -> `python3.12`
- `/usr/bin/python` -> `python3.12`
- `/usr/lib/python3.12`

No historical `/opt` Python layout, Python 3.5 payload, MPSS SDK binary,
archived root, private CPIO, private key, or universal authorization key is an
input or payload member.

`PUBLIC_ROOT_INPUTS=PASS`

`PUBLIC_ROOT_BUILD=PASS`

`RC7_CONTAMINATION_AUDIT=PASS`

## Live Result

Candidate G2 passed automatic xpr-init handoff, final XPR PID 1, micveth,
authenticated SSH, hello, pthread, `dlopen`, Python 3.12.13, the required core
Python/threading smoke, and host/card Python hash identity on the Intel Xeon
Phi 5110P. Recovery restored the exact stock configuration hash and stock SSH.

See [the validation record](xpr-os-0.1.0-rc7-candidate-g-validation.md) for exact hashes,
rejected-candidate boundaries, and command-level evidence.

## Publication Boundary

At the pre-publication checkpoint, the archive intentionally retains
pre-validation metadata because it was frozen before hardware testing; the
external validation record now binds the result to that exact immutable hash.

`RC7_PUBLICATION_PREP=PASS`

`RC7_PUBLICATION=AUTHORIZED_AFTER_FINAL_CHECKS`

The owner's publication task authorizes the final documentation commit as the
tag target after checks pass. The GitHub release records the publication result;
the artifact build revision remains `079521e` regardless of later documentation.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

The separately prepared standalone toolkit binary remains excluded while its
KNC binutils source-distribution review is held. That hold does not invalidate
the RC7 OS candidate.
