# XPR-OS 0.1.0-rc4 Adversarial Release Audit

Date: 2026-08-11
Decision: `BLOCKED_BY_CONCRETE_ISSUES`

This is a factual release-engineering audit of the frozen RC4 archives. It is
not a publication action and does not change RC3 or the frozen RC4 artifacts.

## Artifact Evidence

| Artifact | SHA-256 |
| --- | --- |
| Binary archive | `b92986789313c64fb2d8d4d5b80ebec508e0222d70c406b00be1cda3c749828b` |
| Source archive | `361eb20033b0e7b3692982ffeb0b12330c5914e72c098aa48f23bcebd969efdb` |
| Checksum manifest | `4c0bb4bff3f1a4f27989cffdeb6ef574723293347f73212082d947c05ee54831` |
| Kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| Base CPIO | `bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779` |
| Generic final payload | `5866743b0899e91fda0879aca9c449378b81a541ab78c5e7247fb6f8e7baeced` |

Two independently staged builds produced byte-identical binary archives,
source archives, and checksum manifests. A clean extraction passed the shipped
checksum verifier, generic-payload key-free check, license-bundle check, and
the shipped SPDX sanity checker. The source archive contains the Solros,
modules, BusyBox, Dropbear, eglibc, GCC, GMP, MPFR, and MPC source archives.

## Routing And Review Method

Parent: Terra High.
Execution mode: `LIMITED_SUBAGENTS`.
Luna routing: `DIRECT`.

Five Luna Medium reviewers were admitted concurrently. The direct-agent thread
limit then required closing completed reviewers before the sixth Luna Medium
reviewer could run. All six reviews were independent and read-only. The main
orchestrator performed the archive-only checks needed to distinguish a local
checkout from the actual frozen remote archives.

| Reviewer | Scope | Conclusion |
| --- | --- | --- |
| 1 | RC3 blocker regression | Kernel reproduction, notice delivery, and generic key-free payload passed; release-level SPDX coverage remains incomplete. |
| 2 | SBOM/SPDX | Syntax check passed, but container artifacts and release-level relationships are absent. |
| 3 | Corresponding source | Source archives are present; the bootstrap/final-root assembly still requires private CPIO inputs. |
| 4 | Licenses/notices/provenance | No concrete missing license-text or notice defect in the paired frozen archives. |
| 5 | Security/proprietary/secrets | No fixed key, private key, credential, MPSS payload, firmware, or unknown ELF was found; malformed public keys are accepted by the provisioner. |
| 6 | Archive/release consistency | Actual archive hashes and A/B equality passed; stale RC1 metadata and incomplete artifact binding remain. |

## RC3 Regression Check

| RC3 blocker | Result | Evidence |
| --- | --- | --- |
| LF configs and self-contained kernel reproduction | PASS | The source bundle contains both configs and reproduction wrappers. The config integrity tool rejects CR bytes and hash mismatches. The historical-path wrapper reproduced the shipped `d529` kernel exactly. |
| SPDX 2.3 syntax | PASS with completeness blocker below | The shipped document reports SPDX 2.3 and passes the shipped syntax checker. It is not sufficiently complete for this release. |
| License and notice delivery | PASS | The frozen binary contains GPL-2.0, module GPL-2.0, BusyBox GPL-2.0, LGPL-2.1, GPL-3.0, GCC Runtime Library Exception, Dropbear, and XPR MIT texts; the paired source archive contains the named sources. |
| Fixed root `authorized_keys` | PASS | The generic payload has no `authorized_keys`; the packaged generic verifier passed. The deployment provisioner has a separate malformed-key blocker below. |

## Concrete Blockers

| ID | Component and path | Evidence | Required correction | Changes |
| --- | --- | --- | --- | --- |
| B1 | Frozen release metadata: `manifests/tested-artifacts.json`, `docs/public-clean-stack-validation.md`, `README.md`, and `manifests/release.yml` inside the binary archive | `tested-artifacts.json` is RC1-named, records commit `803a522...`, and records payload `e5c252...`; the actual packaged and hardware-validated payload is `586674...`. The embedded README and release manifest also say the hardware/repeatability gate remains pending. | Create an immutable RC5 artifact manifest for the actual kernel, modules, Base CPIO, payload, source revision, A/B hashes, and hardware evidence. Update embedded release documentation, then restage and audit new archives. | Source archive and binary archive; no firmware or stock state. |
| B2 | SSH provisioner: `tools/release/provision-xpr-authorized-key.py` | A temporary key file containing `ssh-rsa aGVsbG8= malformed` was accepted with exit code 0 and produced a deployment payload. This is not a valid SSH RSA public-key blob. | Decode and validate the OpenSSH binary key structure and key type before accepting it. Add regression tests for syntactically Base64 but structurally invalid keys. Rebuild and re-audit the release tools. | Source archive and binary archive; no hardware artifact change. |
| B3 | Corresponding-source path: `docs/release/build-xpr-os-rc-from-source.md` and `tools/release/build-split-root-control.sh` | The source document explicitly states that the public repository does not recreate every accepted binary. The split-root builder requires a private bootstrap CPIO pair and a private final-root CPIO, then transforms them. Those source-equivalent inputs are not in the RC4 source archive. | Supply a canonical source-only builder that constructs the bootstrap and final payload from the pinned sources/configs/recipes, or include complete source-equivalent inputs with their own provenance. Rebuild the affected payload/Base CPIO and rerun the bounded hardware gate. | Source archive, binary archive, and hardware-tested artifacts. |
| B4 | SPDX document: `manifests/xpr-os.spdx.json` in the frozen binary archive | The SBOM records 24 files: runtime executables/libraries, kernel, System.map, and modules. It has no file entry or package relationship for the shipped `bootstrap/xpr-bootstrap.cpio.gz` or `payload/xpr-rootfs.cpio.gz`, and no `SPDXRef-DOCUMENT` `DESCRIBES` relationship. The release verifier does not compare SBOM paths/hashes with extracted archive content. | Generate a complete release-level SPDX document that maps the bootstrap and payload containers as shipped artifacts, adds document/package relationships, and verifies all recorded paths and hashes against the extracted archive. | Source archive and binary archive; no hardware artifact change. |

## Non-Blocking Or Resolved Findings

| Finding | Status | Counterevidence or disposition |
| --- | --- | --- |
| License files or source archives absent from the Git checkout | RESOLVED | They are intentionally absent from Git but present in the frozen binary/source archives and passed the packaged license verifier. |
| Module `downloadLocation: NOASSERTION` | NON-BLOCKING | The exact module source archive is included and hash-pinned in the paired source archive. The original public download location is unknown, but this is not a missing corresponding-source file. |
| Temporary fixed paths in the staging script | NON-BLOCKING | This is a concurrent-build hardening issue, not a defect in the frozen archive. Replace before RC5 if the staging workflow is retained. |
| `imp` in shipped Python tools | NON-BLOCKING FOR THE TESTED CENTOS 7 HOST | The tested host uses Python 2.7.5, where it works. The `python3` shebang makes it incompatible with Python 3.12, so replace it with `importlib` for RC5 portability. |
| Generic private-key detector misses one PEM marker form | NON-BLOCKING FOR RC4 CONTENT | The actual generic payload is key-free. Expand the detector before RC5 defense-in-depth testing. |

## Component Matrix

| Component | Binary shipped | Source shipped | Revision/hash pinned | License/notices | Build/config present | Corresponding source complete | SBOM mapping | Concrete blocker |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Compatibility kernel | yes | yes | yes | yes | yes | yes | yes | no |
| ringbuffer.ko | yes | yes | yes | yes | yes | yes | yes | no |
| dma_module.ko | yes | yes | yes | yes | yes | yes | yes | no |
| micscif.ko | yes | yes | yes | yes | yes | yes | yes | no |
| mpssboot.ko | yes | yes | yes | yes | yes | yes | yes | no |
| intel_micveth.ko | yes | yes | yes | yes | yes | yes | yes | no |
| BusyBox | inside payload | yes | yes | yes | yes | source archive only | yes | B3 |
| Dropbear | inside payload | yes | yes | yes | yes | source archive only | yes | B3 |
| eglibc | inside payload | yes | yes | yes | yes | source archive only | yes | B3 |
| GCC | no | yes | yes | yes | yes | yes as libgcc build input | not applicable | no |
| libgcc | inside payload | yes | yes | yes | yes | source archive only | yes | B3 |
| GMP | no | yes | yes | not separately delivered | build prerequisite recorded | yes as prerequisite | not applicable | no |
| MPFR | no | yes | yes | not separately delivered | build prerequisite recorded | yes as prerequisite | not applicable | no |
| MPC | no | yes | yes | not separately delivered | build prerequisite recorded | yes as prerequisite | not applicable | no |
| XPR bootstrap/init | yes | yes | revision pinned in source archive | MIT | yes | bootstrap container is not source-built | partial | B3, B4 |
| XPR tooling | yes | yes | revision pinned in source archive | MIT | yes | yes | partial | B2, B4 |
| Smoke tests | inside payload | yes | revision pinned in source archive | MIT | yes | payload is not source-built | yes | B3 |

The source archives for BusyBox, Dropbear, eglibc, GCC, GMP, MPFR, MPC, kernel,
and modules are present. The incomplete part is the reproducible assembly of
the complete shipped bootstrap/final-root artifacts from those sources.

## RC4 Validation Cross-Check

The packaged kernel, Base CPIO, and generic payload hashes match the validated
hardware set. The three logged rollback-protected runs established:

| Gate | Result |
| --- | --- |
| Boot 1 | PASS |
| Boot 2 | PASS |
| Boot 3 | PASS |
| Project PID 1 | PASS |
| Network | PASS |
| Authenticated final-root SSH | PASS |
| Dynamic hello | PASS |
| pthread | PASS |
| dlopen | PASS |
| Stock rollback | PASS |

The technical hardware claim is therefore supported for the actual kernel,
Base CPIO, and payload hashes. B1 prevents the frozen archive's own embedded
metadata from accurately stating that fact.

## Final Classification

`BLOCKED_BY_CONCRETE_ISSUES`

No issue in this audit requires an abstract legal interpretation to resolve.
The owner should not publish the frozen RC4. The smallest safe next action is
to create RC5: fix B2, close B3 with a source-only artifact builder, correct
B1/B4 metadata and SPDX coverage, then restage, audit, and hardware-validate
the resulting artifact set.
