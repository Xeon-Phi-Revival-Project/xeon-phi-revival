# XPR-OS 0.1.0-rc7 Integration Status

## Current Candidate

`XPR_OS_RC7_CANDIDATE=TECHNICALLY_PASS`

The exact unpublished Candidate E archive is:

- `xpr-os-0.1.0-rc7.tar.gz`
- SHA-256 `a4b313ad4b696ebdfe8a406da18288d1903933a6d3a12a1a41da1a69f218e0a4`

Its paired source archive SHA-256 is
`79bd109d097e105229266db7095f355fb17d431fe1f3310f8369621e475f61ad`.
Built-in source-policy, payload, SPDX 2.3, license, release-consistency, and
archive checks passed.

Release-facing sidecars are finalized as:

- SPDX: `xpr-os-0.1.0-rc7.spdx.json`, SHA-256
  `eb09d81c6ce10841724dd2a742832d551c30fca322fb1efbe57fd2434177cab8`
- notices/licenses: `xpr-os-0.1.0-rc7-notices.tar.gz`, SHA-256
  `5a76f612f09445d9af14a00dc5ee79f6ebe69a87350a07e0de49f139b2ebb924`
- publication checksums: `SHA256SUMS`, SHA-256
  `484dea684a1ad695f525dcf788520387b470f265649c84d8b0dfb9aa17171e7d`

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

Candidate E passed automatic xpr-init handoff, final XPR PID 1, micveth,
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
