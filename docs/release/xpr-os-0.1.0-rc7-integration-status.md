# XPR-OS 0.1.0-rc7 Integration Status

## Current Candidate

`XPR_OS_RC7_CANDIDATE=PASS`

The exact unpublished Candidate F archive is:

- `xpr-os-0.1.0-rc7.tar.gz`
- SHA-256 `f169ffea39b653ed583c8b84b1c9045393749586e9229acf9d7ab2538df49c86`

Its paired source archive SHA-256 is
`671b7230507d0efac76eafd351f24750af86866c26a9c33a24e807e2e6f3e3de`.
Built-in source-policy, payload, strict publication-stage provenance, SPDX 2.3,
license, release-consistency, and archive checks passed. Independent staging
produced byte-identical binary and source archives.

Release-facing sidecars are finalized as:

- SPDX: `xpr-os-0.1.0-rc7.spdx.json`, SHA-256
  `eb09d81c6ce10841724dd2a742832d551c30fca322fb1efbe57fd2434177cab8`
- notices/licenses: `xpr-os-0.1.0-rc7-notices.tar.gz`, SHA-256
  `d0fc20f19e6e476165eef600f689677962d6ddb84384aa56584655088efd6041`
- publication checksums: `SHA256SUMS`, SHA-256
  `bb44b2ef8379477b6f61442f8eedf80514ef86adfa20f1563236f375a8ded8b0`

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

Candidate F passed automatic xpr-init handoff, final XPR PID 1, micveth,
authenticated SSH, hello, pthread, `dlopen`, Python 3.12.13, the required core
Python/threading smoke, and host/card Python hash identity on the Intel Xeon
Phi 5110P. Recovery restored the exact stock configuration hash and stock SSH.

See [the validation record](xpr-os-0.1.0-rc7-validation.md) for exact hashes,
rejected-candidate boundaries, and command-level evidence.

## Publication Boundary

The candidate is not tagged or published. Its archive intentionally retains
pre-validation metadata because it was frozen before hardware testing; the
external validation record now binds the result to that exact immutable hash.

`RC7_PUBLICATION_PREP=PASS`

`RC7_PUBLICATION=AWAITING_OWNER_AUTHORIZATION`

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

The separately prepared standalone toolkit binary remains excluded while its
KNC binutils source-distribution review is held. That hold does not invalidate
the RC7 OS candidate.
