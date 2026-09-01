# XPR-OS 0.1.0-rc7 Candidate Validation

This record covers the unpublished RC7 Candidate F assembled from commit
`90291d67eb856385c90ac575afb2c9b0e6149804`. It is the exact archive used for
the successful Intel Xeon Phi 5110P validation. It is not publication approval.

## Exact Candidate

| Artifact | Size | SHA-256 |
| --- | ---: | --- |
| `xpr-os-0.1.0-rc7.tar.gz` | 20,897,319 bytes | `f169ffea39b653ed583c8b84b1c9045393749586e9229acf9d7ab2538df49c86` |
| `xpr-os-0.1.0-rc7-sources.tar.gz` | 383,316,819 bytes | `671b7230507d0efac76eafd351f24750af86866c26a9c33a24e807e2e6f3e3de` |
| `xpr-os-0.1.0-rc7.spdx.json` | 44,159 bytes | `eb09d81c6ce10841724dd2a742832d551c30fca322fb1efbe57fd2434177cab8` |
| `xpr-os-0.1.0-rc7-notices.tar.gz` | 42,195 bytes | `d0fc20f19e6e476165eef600f689677962d6ddb84384aa56584655088efd6041` |
| `SHA256SUMS` | 379 bytes | `bb44b2ef8379477b6f61442f8eedf80514ef86adfa20f1563236f375a8ded8b0` |

Container hashes:

- inner bootstrap: `dc206d23dcd26a44b17e78103fe4bc1e1d30077af20fbc12af8cbfffc6ae032d`
- outer Base CPIO: `72f40d37a8090caacbdf45fe39d55b9a9e6b635db6bdff984b9a9eefe5f67c71`
- final payload: `ed236ef40639d0e279977519bcab43f1baca297fbbf7b008adcd7e61ad825951`

The candidate remains frozen with `hardware-validation-pending` in its embedded
pre-validation metadata. This external record ties the completed validation to
the exact immutable archive rather than modifying it after the hardware run.
The release-facing SPDX file is an exact copy of the validated SPDX document
embedded in that archive. The notices sidecar deterministically packages the
embedded `LICENSE`, `NOTICE.md`, and `LICENSES/` files. The external
`SHA256SUMS` verifies all four intended publication assets.

## Source-Built Root Inputs

| Input | SHA-256 |
| --- | --- |
| BusyBox | `f639cc8fa89b987e2392e484a4643fcabd80beefc76041b3fda55885831a277c` |
| Dropbear | `a9085bcd3fd3d22deb9c38cdf4c5ce23d9ddf7e4ce0729f367665e5e15068391` |
| `ld-linux-k1om.so.2` | `812e9f9a347e4effa1f20688d7383e82220365abf91945fac53b344ac7d14f10` |
| `libc.so.6` | `1c680801e39082a1d504fe3a517836ecabee6e0059983bdd41a0b35b8b4c84aa` |
| `libpthread.so.0` | `4a7dbd34d9bac478f808c81491d8cb4f79449d7e50fc3dcb7e4f19bd50372424` |
| `libm.so.6` | `ad35aa054edc8978a8a62051b499236a4aa7c61df0dbf126e8eb763c9d79eb7d` |
| `libdl.so.2` | `2e6f7952b06417029cc9bb5ec11fc20a7b4e8c98e8bbf988c0271006ea1df98c` |
| `librt.so.1` | `bc05e371a69abcbf226a904cc83d08d4d5786d51d59370972576331399d49737` |
| `libutil.so.1` | `78a9e9e2aea84c3e768bb7eb6a2be6daaaa35ff3db0abbb5aa30608a6b81edb0` |
| `libgcc_s.so.1` | `f149daa610c673cb700ceba72f5e2d0057f14061772a047b117c526bd17a9500` |
| CPython 3.12.13 executable | `259b2a33523ab8581cb70648c88f3a0b1be8f285eb2b21c42a60addf27c2a211` |

The fresh loader has no `RPATH` or `RUNPATH`. All target ELFs report
`Machine: Intel K1OM`. No MPSS SDK binary, archived root, or private CPIO was
used as a public-root construction input.

`PUBLIC_ROOT_INPUTS=PASS`

`PUBLIC_ROOT_BUILD=PASS`

## Static Gates

- source release compliance: PASS
- public source policy: PASS
- private build path leaks: 0
- payload audit: PASS, 771 files
- fixed `authorized_keys`: 0
- private keys: 0
- universal administrator keys: 0
- Python 3.5 payload: 0
- MPSS SDK binary payload: 0
- standalone toolkit binary: 0
- SPDX 2.3 validation: PASS, 9 packages and 60 files
- license bundle validation: PASS
- release-version consistency: PASS
- archive checksum verification: PASS
- paired source archive verification: PASS
- precompiled release verification: PASS
- strict publication-stage payload/SPDX audit: PASS, 771 files and 0 errors
- embedded publication profile matches corresponding source: PASS
- embedded `xpr-init` matches corresponding source and binds its extraction
  cache to the full release-archive SHA-256: PASS
- release-facing SPDX sidecar validation: PASS
- release-facing notices bundle validation: PASS
- release-facing four-asset `SHA256SUMS`: PASS

`RC7_CONTAMINATION_AUDIT=PASS`

## Reproducibility

A second clean staging pass from the same explicit inputs and repository
snapshot produced byte-identical binary and source archives.

`RC7_REPRODUCIBILITY=PASS`

## Rejected Candidates And Fixes

Candidate A used static Dropbear and failed bootstrap RSA account lookup.
Candidates B and C used dynamic Dropbear but never opened bootstrap SSH. A
direct card-side loader test located the second failure: the source-built
loader contained an injected `/lib64` RPATH and aborted during its own
bootstrap with the eglibc `DT_RPATH` assertion.

The `xpr-gcc` wrapper now suppresses all automatic runtime linker flags for
`-nostdlib`, `-nodefaultlibs`, and `-static`. The toolkit packager also now
keeps the correct `mkheaders` output rather than duplicating GCC's limits-header
guards. Fresh eglibc and libgcc builds then completed, and the exact fresh
loader ran the source-built Dropbear binary on the card.

Candidate D booted successfully but contained a stale pre-validation Python
package selected from the build host. Candidate E first used the authoritative
hardware-validated package SHA-256
`7cfe57598fecf9263af84f5409a4c9f3f3e688b13d6ae784eaae79aba4e49d4a`.
During repeated same-version testing, xpr-init initially reused Candidate D's
cached extraction. The stale cache was preserved as evidence, Candidate E was
freshly extracted, and its generic payload hash was verified as
`ed236ef40639d0e279977519bcab43f1baca297fbbf7b008adcd7e61ad825951`
before the successful boot.

Candidate F retains those exact runtime bytes and closes the release-stage
gaps: publication provenance decisions are explicit, the strict publication
audit passes, and `xpr-init` keys same-version extraction caches by the full
archive SHA-256. Candidate F was independently staged twice before its own
hardware cycle.

## 5110P Validation

Environment: CentOS 7.4, Intel MPSS 3.4.10, Intel Xeon Phi 5110P, `mic0`.

The sanitized command-level output is preserved in the
[Candidate F hardware transcript](xpr-os-0.1.0-rc7-candidate-f-hardware-transcript.txt).

- candidate archive verification and xpr-init installation: PASS
- deployment-specific RSA public-key provisioning: PASS
- reset/wait/boot lifecycle: PASS
- automatic bootstrap-to-final-root handoff: PASS
- final XPR `/sbin/init` as PID 1: PASS
- micveth and `/sys/class/net/mic0`: PASS
- authenticated Dropbear SSH: PASS
- `xpr-hello`: PASS (`XPR_HELLO_OK`)
- pthread smoke: PASS (`XPR_PTHREAD_OK`)
- `dlopen` smoke: PASS (`xpr-dlopen-smoke: ok`)
- `python`, `python3`, and `python3.12` paths: PASS
- Python version: PASS (`Python 3.12.13`)
- Python imports `sys`, `os`, `pathlib`, `json`, `math`, `threading`, and
  `platform`: PASS
- threaded `math.sqrt(144)` result: PASS
- `platform.machine()`: PASS (`k1om`)
- Python host/card SHA-256 identity: PASS

Python output included:

```text
Hello from Python on Xeon Phi
3.12.13 (main, Aug 15 2026, 01:06:32) [GCC 5.1.1]
k1om
RC7 Python core smoke PASS
```

`RC7_5110P_BOOT=PASS`

`RC7_PYTHON312=PASS`

`RC7_PYTHON_CORE_SMOKE=PASS`

## Recovery

`xpr-init --recover` restored and booted the stock MPSS image. The active
`mic0.conf` SHA-256 returned exactly to
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.
Stock SSH and `k1om` userspace passed. The observed stock image uses PID 1
`/sbin/init.sysvinit`; it does not provide `systemctl`.

The raw transcript first records a recovery `FAIL` from a harness assertion
that expected `/proc/1/cmdline` to contain an absolute init path. Stock reports
`init [5]` there. The immediate direct check resolved `/proc/1/exe` to
`/sbin/init.sysvinit` and `/sbin/init` to that same executable; the correction
and final PASS markers are appended in the transcript.

`RC7_RECOVERY=PASS`

## Decision

`XPR_OS_RC7_CANDIDATE=TECHNICALLY_PASS`

Candidate F is the exact hardware-tested RC7 artifact. Publication remains a
separate owner decision, and the embedded pre-validation status must be handled
without replacing the tested runtime bytes. The standalone toolkit remains
excluded while its separate distribution review is held.

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

`RC7_PUBLICATION_PREP=PASS`

`RC7_PUBLICATION=AWAITING_OWNER_AUTHORIZATION`
