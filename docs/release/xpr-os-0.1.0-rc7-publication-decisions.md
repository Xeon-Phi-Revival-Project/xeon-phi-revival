# XPR-OS 0.1.0-rc7 Publication Decisions

This is an engineering provenance and distribution review for the exact RC7
artifact set. It is not legal advice and does not authorize publication.

## Reproduced Candidate E Gate

The strict publication audit was reproduced against Candidate E SHA-256
`a4b313ad4b696ebdfe8a406da18288d1903933a6d3a12a1a41da1a69f218e0a4` and
its embedded `manifests/prebuilt-clean-profile.json`. The audit examined 771
payload entries and failed with 45 errors.

| Exact file/path | Component | Previous status | Requested status | Evidence | Decision |
| --- | --- | --- | --- | --- | --- |
| `/bin/busybox` (1 error) | BusyBox 1.19.4 | `candidate` | `publish` | Exact upstream archive SHA-256 `9b853406da61ffb59eb488495fe99cbb7fb3dd29a31307fcfa9cf070543710ee`, tracked config/patch/build recipe, GPL-2.0-only text, source bundle and SPDX mapping | `publish` |
| `/usr/bin/python3.12` and 32 executable standard-library scripts under `/usr/lib/python3.12/` (33 errors) | CPython 3.12.13 | `candidate` | `publish` | Official source SHA-256 `c08bc65a81971c1dd5783182826503369466c7e67374d1646519adf05207b684`, tracked K1OM patch/build/package recipe, PSF and incorporated notices, separate corresponding-source bundle and SPDX mapping | `publish` |
| `/usr/sbin/dropbear` (1 error) | Dropbear 2022.83 | `candidate` | `publish` | Exact upstream archive SHA-256 `bc5a121ffbc94b5171ad5ebe01be42746d50aa797c9549a4639894a16749443b`, tracked build recipe, complete upstream multi-license text, source bundle and SPDX mapping | `publish` |
| `/lib64/ld-linux-k1om.so.2`, `libc.so.6`, `libcrypt.so.1`, `libdl.so.2`, `libm.so.6`, `libnss_files.so.2`, `libpthread.so.0`, `librt.so.1`, and `libutil.so.1` (9 errors) | eglibc 2.19-0ubuntu6.15 | `candidate` | `publish` | Exact orig and Debian source hashes, tracked XPR overlay/build recipe, LGPL-2.1-or-later text, complete source delivery and SPDX mapping | `publish` |
| `/lib64/libgcc_s.so.1` (1 error) | GCC runtime 5.1.1 KNC | `candidate` | `publish` | Exact GCC source SHA-256 `6538edbd3c309eb7c37bb215c40ef9822c7c015928ff354267eac2178cf5f1e3`, tracked source-only build recipe, GPL-3.0-only and GCC Runtime Library Exception 3.1, source bundle and SPDX mapping | `publish` |

`PUBLICATION_GATE_REPRODUCED=PASS`

## Candidate F Closure

Candidate F was assembled from commit
`90291d67eb856385c90ac575afb2c9b0e6149804`. Its exact binary SHA-256 is
`f169ffea39b653ed583c8b84b1c9045393749586e9229acf9d7ab2538df49c86`.
The corrected embedded profile records every reviewed component decision above.
The strict publication audit against the exact embedded payload, profile, and
SPDX examined 771 entries and returned zero errors. A second independent
staging produced byte-identical binary and source archives.

The same immutable Candidate F archive passed automatic handoff, final PID 1,
micveth, authenticated SSH, native hello/pthread/`dlopen`, CPython 3.12.13 core,
and exact stock recovery on the Intel Xeon Phi 5110P. The hardware transcript
is linked from the release index.

`PUBLICATION_STAGE_AUDIT=PASS`

`RC7_REPRODUCIBILITY=PASS`

## Required Top-Level Components

The payload audit does not inspect the separately shipped kernel and modules,
so they were reviewed independently rather than treated as implicitly clear.

| Component | Exact binary identity | Exact source and build evidence | License/notice evidence | Decision |
| --- | --- | --- | --- | --- |
| XPR K1OM kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` | Solros commit `bda6ce066e514239c9b645fd1ed2a9ffe4f2db33`, source archive SHA-256 `0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59`, exact config, compile metadata and `reproduce-tested-k1om-kernel.sh` | Linux GPL-2.0-only `COPYING`, source archive, notices and SPDX package | `publish` |
| Five MIC modules | `af0a88a14bcd815bea07739b88a54d453eb68b7e5c1acc81de0fc8aac70af32a`, `e7339e86b9a00c047acc982e7f8a734f963b5ec945991f3cbd62bca1a6eba068`, `0c5476258e5a4f200a1c38c1f434ae3ffccd29ec6f098b165d028c27655f64e2`, `a5cc794ed1a6874a23830b39fc617fcea61f1de6a952b37029a099eb148d6894`, `0e8f2baee0551707ca05ac85d19855b24e346742f8ff08b91ba2e294252bea60` | Complete `mpss-modules-3.4.10.tar.bz2` SHA-256 `0bfbb007aaba7f041b51229c28f11a793ba1adc76f08afd8e83b3a0488936f54`, per-file dependency map, kernel inputs and tracked build recipe | Archive GPLv2 `COPYING`; every one of the 24 implementation files has an Intel copyright notice and direct GPL version 2 grant; source archive, notices and SPDX package | `publish` |

These kernel and module binaries are byte-identical to the binaries in the
published RC6 prerelease. RC6 manifest `publication.allowed: true`, tag
`v0.1.0-rc6`, and the owner publication decision are additional project-level
evidence that the exact binary/source pairing crossed the publication boundary.
No Intel MPSS package, stock uOS, firmware, SDK binary or stock kernel is used.

## Other Shipped Material

Project-owned init, helper, configuration, smoke-test and host integration files
remain `publish` under the repository MIT license and are included in the source
archive. Their release commit is substituted into SPDX/source metadata during
staging. No separate opaque binary input is involved.

The standalone XPR K1OM Toolkit is not part of RC7. Its separate KNC-binutils
source-distribution interpretation remains:

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

## Engineering Conclusion

For these exact RC7 components, tracked evidence identifies every shipped
binary, exact source, build recipe, corresponding source, license expression,
license text/notices and SPDX relationship. No required XPR-OS component has an
unresolved engineering publication hold. Final publication remains an explicit
owner action.

`PUBLICATION_PROFILE_CONSISTENCY=PASS`
