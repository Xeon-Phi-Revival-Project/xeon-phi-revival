# XPR-OS 0.1.0-rc7 Integration Status

## CPython layout reconciliation

`tools/release/build-public-clean-root.py` now consumes the validated CPython
3.12.13 core package layout directly:

- `/usr/bin/python3.12`
- `/usr/bin/python3` -> `python3.12`
- `/usr/bin/python` -> `python3.12`
- `/usr/lib/python3.12`

The historical `/opt/xeon-phi-revival/lib/python3.12` integration path is not
used by the public-clean root builder.  The release ledger maps this component
to the pinned CPython source, tracked build/package scripts, and the
corresponding-source component archive.

## Candidate status

`XPR_OS_RC7_CANDIDATE=REBUILDING_DYNAMIC_DROPBEAR`

The public-root reconstruction is complete. Fresh source builds supplied
eglibc, libgcc, BusyBox, Dropbear, and the XPR helper binaries; the bootstrap
and final payload were generated without an archived root or private CPIO
input. The corrected compiler wrapper passed the tracked K1OM init/fini probe.

`PUBLIC_ROOT_INPUTS=PASS`

`PUBLIC_ROOT_BUILD=PASS`

The exact candidate and paired source archive were built twice from commit
`1a2518afae704f9c352912cd99e8f4fca2b63ddb`. Both pairs are byte-identical.
Built-in source-policy, payload, SPDX 2.3, license, release-consistency, and
archive verification gates passed. The standalone toolkit binary remains
excluded.

After a cold chassis restart restored the 5110P, candidate A installed and
booted its kernel but failed automatic handoff at bootstrap RSA authentication.
The deployed nested bootstrap archive contained the selected public key with
the correct bytes and modes. Static Dropbear's build log reported glibc account
lookup warnings, and the server rejected the valid provisioned key.

The tracked Dropbear builder now accepts the standard XPR sysroot layout for a
dynamic build. Source-built dynamic Dropbear hash
`a9085bcd3fd3d22deb9c38cdf4c5ce23d9ddf7e4ce0729f367665e5e15068391`
uses the bundled `/lib64` eglibc/libgcc runtime. Replacement bootstrap and
public-root containers have been built; a new candidate and complete live
cycle are required. Candidate A was recovered to the exact stock configuration
and stock SSH.

See [the candidate validation record](xpr-os-0.1.0-rc7-validation.md) for exact
artifact hashes and the resume boundary.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

The standalone toolkit binary remains excluded from a public RC7 artifact
while its separate KNC binutils source-distribution review is held.
