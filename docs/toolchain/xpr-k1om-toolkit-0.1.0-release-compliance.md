# XPR K1OM Toolkit 0.1.0 Release Compliance Review

## Scope

This engineering review covers the immutable standalone-toolkit candidate
`xpr-k1om-toolkit-0.1.0-linux-x86_64.tar.xz`, SHA-256
`8227898056918423beab850b4daddd01423e88e75332698f636720d4b6fd6cc2`.
It is not legal advice or a publication authorization.

| Component | Version / identity | Source and license | Binary decision | Evidence |
| --- | --- | --- | --- | --- |
| XPR wrappers, validator, examples | toolkit 0.1.0 | tracked XPR source, MIT | PUBLISH | source archive `repository/` |
| GCC KNC | 5.1.1, `af7cc04cef723da3166f0d6f1539f02525fe5a93` | `gcc-5.1.1-knc-af7cc04.tar.gz`, SHA-256 `6538edbd3c309eb7c37bb215c40ef9822c7c015928ff354267eac2178cf5f1e3`, GPL-3.0-or-later | REBUILD_PROVEN | source archive and `build-k1om-gcc.sh` |
| KNC binutils | 2.22 + MPSS 3.8.6 changes | `binutils-2.22+mpss3.8.6.tar.bz2`, SHA-256 `0e498581badb505bd2639bc1f75debe9299212fb50e8eee5deb40631a78abd9c`, GPL-3.0-or-later | HOLD_HUMAN_REVIEW | public-source archive and `build-k1om-binutils.sh` |
| libgcc / libgcc_s | GCC 5.1.1 KNC build | GCC source, GPL-3.0-or-later WITH GCC-exception-3.1 | REBUILD_PROVEN | `build-k1om-libgcc.sh` |
| eglibc / CRT / headers | 2.19-0ubuntu6.15 | orig SHA-256 `e5d30be72b702dffae527779af1be755f0dfbf13c171998a04f7265cd4da131f`, Debian changes SHA-256 `2e0a1d4dfbc8bb666604d6804b9fbd9ce7a1f23b2a5bcb487f5a774d2c557e4c`, LGPL-2.1-or-later | REBUILD_PROVEN | `build-eglibc-k1om-runtime.sh` and overlay |
| GMP, MPFR, MPC | GCC build prerequisites | pinned source archives, LGPL-3.0-or-later | PUBLISH_SOURCE | source archive only |

## Engineering Results

- `MPSS_SDK_BINARY_PAYLOAD=0`: the candidate contains XPR-built host tools,
  sysroot files, scripts, and examples, not Intel MPSS SDK binaries.
- `MPSS_BUILD_INPUT=0`: the corresponding-source recipe rejects `/opt/mpss`
  and requires only the pinned source inputs plus ordinary host build tools.
- The candidate was validated on a Linux 6.12 x86-64 host without MPSS and the
  exact produced files executed on an Intel Xeon Phi 5110P under XPR-OS RC6.
  See [the validation record](standalone-toolkit-validation-2026-08-13.md).
- The source archive delivers exact source archives, patches/overlays, build
  scripts, license texts, and a deterministic package recipe.

## KNC Binutils Boundary

The KNC binutils source was recovered as source from the public MPSS 3.8.6
source distribution. Its `COPYING` is included and the toolkit contains no
MPSS SDK binary payload. Engineering evidence supports a source-accounted
rebuild; a qualified reviewer must decide whether any surrounding source-
distribution terms affect publication of rebuilt binaries.

## Clean Rebuild Result

The clean source-only reconstruction now passes. It builds GCC 5.1.1 KNC,
installs source-built eglibc bootstrap headers, stages the required
source-built GCC bootstrap archive/CRT objects, builds the full K1OM eglibc
runtime, then rebuilds `libgcc_s.so.1` against that runtime. No MPSS SDK or
`/opt/mpss` input was used.

The rebuilt loader, libc, pthread, libm, libdl, librt, and libutil all report
`Machine: Intel K1OM`. The rebuilt `libgcc_s.so.1` reports the expected SONAME
and `_Unwind_RaiseException`. The reconstructed toolkit compiled and validated
the `hello`, `pthread` (with `-pthread`), and `libc-smoke` examples; each has
the `/lib64/ld-linux-k1om.so.2` interpreter and passes the K1OM ELF validator.
The package-path scan passed with no `/opt/mpss` or `mpss-sdk` reference.

`XPR_STANDALONE_TOOLKIT=TECHNICALLY_PASS`. The immutable validated binary
candidate remains unchanged, but its publication is
`TOOLKIT_RELEASE_CANDIDATE=HOLD_HUMAN_REVIEW` pending the independent KNC
binutils source-distribution licensing interpretation described above.

## Final Release Sidecars

The immutable binary candidate remains
`xpr-k1om-toolkit-0.1.0-linux-x86_64-b.tar.xz`, SHA-256
`8227898056918423beab850b4daddd01423e88e75332698f636720d4b6fd6cc2`.
The final sidecars generated for that exact candidate are:

- `xpr-k1om-toolkit-0.1.0-sources.tar.xz`:
  `a2ec298e578652fff3118e29af203134c3e73a94da5202a07ff09760f799618a`
- `xpr-k1om-toolkit-0.1.0.spdx.json`:
  `a741b0e002fcf94101d085d41b7608fae954966d1a5f8efef5ebbbc235de48a4`
  (`SPDX_2_3_VALIDATION=PASS`)
- `xpr-k1om-toolkit-0.1.0-notices.tar.xz`:
  `4bbe8ce48a24c59834cbe47c14c67d3051c57709820956913dc346d1c171599f`

`SHA256SUMS` records all release-facing files. The final source archive
contains byte-identical copies of the active standalone-toolkit, EGLIBC
bootstrap-header, and K1OM GCC build scripts. This confirms the delivered
recipe matches the clean source-only reconstruction; full archive
byte-reproducibility has not been asserted.
