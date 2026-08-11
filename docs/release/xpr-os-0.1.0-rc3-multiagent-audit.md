# XPR-OS 0.1.0-rc3 Multi-Agent Release Audit

Date: 2026-08-10  
Repository starting HEAD: `aa186882ea7512667c1dc941ab2a275df39ec5e5`  
Audit type: factual release-compliance engineering review; not legal advice  
Final classification: **BLOCKED_BY_CONCRETE_ISSUES**

RC3 was not published. The frozen archives were not modified. No hardware, MPSS configuration, or `mic0` state was accessed.

## Executive Decision

The frozen archives are internally hash-consistent and contain no identified Intel proprietary package, firmware, stock uOS executable, private key, or unexplained ELF payload. The public kernel, five modules, BusyBox, eglibc, libgcc, Dropbear, and XPR binaries all have identifiable source families.

RC3 nevertheless has four concrete blockers:

1. The frozen source archive changes line endings in the exact kernel and BusyBox configurations, so their raw hashes no longer match the source ledgers; the d529 recipe also assumes Git state and a pre-extracted private path that are absent from the archive.
2. The SPDX 2.3 document contains invalid license expressions and an invalid package download location.
3. The binary archive omits the third-party license/notice bundle and does not bind recipients to the exact accompanying source archive by filename and hash.
4. The final-root payload contains a fixed `root/.ssh/authorized_keys`, granting root access to any holder of its corresponding private key.

These are file-level defects, not a generic human-review gate. Correcting them changes both frozen archives, so the current RC3 hashes must not be published as the corrected candidate.

## Frozen Inputs

| Artifact | Expected and observed SHA-256 | Size | Result |
|---|---|---:|---|
| `xpr-os-0.1.0-rc3.tar.gz` | `9ce4ec5a9a6f14252cf5eb0f6859d4908fcfb48845b78f65ccb6d7108d7f36a1` | 20,408,216 | PASS |
| `xpr-os-0.1.0-rc3-sources.tar.gz` | `4d7c52690fb7983ae263f129c7bd4a6b2387c0636b384dbb60d3be19d555403a` | 362,581,454 | PASS |

Every entry covered by each archive's `SHA256SUMS` verified. The binary tar has no duplicate, absolute, traversal, symlink, or special-file outer members. The nested CPIO metadata, relative symlinks, device nodes, and tested artifact hashes are internally consistent.

## Execution And Routing

Execution mode: `MIXED_SUBAGENTS_AND_DELEGATED_CHATS`

The Windows Codex runtime exposed explicit model and effort selection for native/delegated tasks. Terra and Luna were both requestable. Actual post-launch model identity was not observable, so this report records requested routing without claiming an unobservable actual model.

| Review | Requested route | Effort | Method | Completed |
|---|---|---|---|---|
| GPL/license advocate | Terra | High | native/delegated independent task | Yes |
| Adversarial licensing | Terra | High | native/delegated independent task | Yes |
| SPDX/SBOM | Luna | Medium | separate delegated task | Yes |
| Corresponding source | Terra | Medium | separate delegated task | Yes |
| Intel/proprietary contamination | Luna | Medium | native/delegated independent task | Yes |
| Notices/distribution | Luna | Medium | native/delegated independent task | Yes |
| Archive forensics | Luna | Medium | separate delegated task | Yes |
| Pro-objection challenge | Terra | High | separate delegated task | Yes |
| Anti-objection challenge | Terra | High | separate delegated task | Yes |

Child routing capability:

- `DIRECT_TERRA_SUPPORTED`: yes
- `DIRECT_LUNA_SUPPORTED`: yes
- `CUSTOM_LUNA_SUPPORTED`: not needed or tested
- `SEPARATE_LUNA_TASK_SUPPORTED`: yes
- Requested effort selectable: yes
- Actual child model/effort observable after launch: no

First-pass reviewers were given the frozen evidence independently and were not given other reviewers' conclusions. Only the two challenge tasks received the disputed claims.

## Blockers

### B1. Frozen Build-Configuration And Corresponding-Source Chain Is Not Executable

Components: compatibility kernel, the five kernel modules, and BusyBox.

Evidence:

- `xpr-os-0.1.0-rc3-sources/repository/configs/kernel/k1om-solros-tested.config` is 43,023 bytes and hashes to `92df8b0afa0b13ee688155f757956a401e44d158e20f3f37b9c0d10bdbb2f926`.
- `manifests/k1om-tested-kernel-reproduction.json` and `repository/tools/kernel/reproduce-tested-k1om-kernel.sh` require `20f240d00b033c1a0e14ffc8d2023533552adc4040ac0deff3404c79f1f12479`.
- The required file exists in the repository as a 41,355-byte LF-normalized config, but that exact file is not in the frozen source archive.
- The reproduction script executes `git rev-parse --show-toplevel`, although the source archive intentionally contains no `.git` directory.
- The script assumes `/root/xpr-kernel-candidate-solros/phi-kernel` and does not stage the bundled Solros archive itself.
- `xpr-os-0.1.0-rc3-sources/repository/configs/busybox/k1om-1.19.4.config` is 25,261 bytes and hashes to `872a68e4fb9cb7a0b22af23a82b4fb1662e59fcedb8706249901905ebdae3b96`; `repository/manifests/release/prebuilt-source-ledger.json` requires `15e366d935d4171070590039b1085e5818954e78fd8c00a39bffa9b88c6191df`.
- The repository's LF-normalized 24,248-byte BusyBox config hashes to the ledger value. As with the kernel config, this is a staging line-ending change rather than a semantic configuration difference, but the frozen bytes do not satisfy their own raw-hash provenance record.

Impact: the included kernel recipe fails before compilation, the five module builds depend on that exact kernel tree, and the BusyBox build configuration does not match the ledger that maps it to the shipped binary. Source content exists and the normalized configurations are recoverable, but the frozen delivery is not a self-consistent executable corresponding-source package.

Required fix:

1. Preserve LF bytes when staging the exact kernel `20f240...2479` and BusyBox `15e366...91df` configurations.
2. Make the reproduction script work from an extracted source archive without `.git` or fixed `/root` paths.
3. Rebuild the source archive, run the recipe from a clean extraction, and update all affected checksums.

Archive changed: source archive. Binary tested artifacts need not change if the corrected recipe still asserts the already tested d529 hash.

### B2. SPDX 2.3 Metadata Is Mechanically Invalid

Component: `manifests/xpr-os.spdx.json` in both archives.

Evidence:

- `mpss-compatible-modules` uses `GPL-2.0-only; human review pending` for `licenseDeclared` and `licenseConcluded`.
- Dropbear uses `MIT-AND-BSD-STYLE` without defining a `LicenseRef-*`.
- The modules package uses `locally retained public mpss-modules-3.4.10 source archive` as `downloadLocation`.

SPDX 2.3 permits listed identifiers, defined `LicenseRef-*` values, and expressions formed with its defined operators. It requires package download location to be a URL, VCS location, `NONE`, or `NOASSERTION` ([SPDX license expressions](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/), [SPDX package information](https://spdx.github.io/spdx-spec/v2.3/package-information/)). The three values above do not conform.

Required fix:

- Use `GPL-2.0-only` and move review state to non-SPDX release metadata.
- Model Dropbear with valid SPDX identifiers and/or one or more defined `LicenseRef-*` entries containing the retained upstream text.
- Use a conforming download location and add source hashes/references in machine-readable provenance.
- Validate the regenerated JSON with an independent SPDX 2.3 validator.

Archive changed: binary and source archives.

### B3. Binary License/Notice Delivery Is Incomplete

Components: Linux kernel, five modules, BusyBox, eglibc, libgcc, and Dropbear.

Evidence:

- The binary archive carries only the XPR MIT `LICENSE` and a general `NOTICE.md`.
- It has no recipient-facing GPLv2 text, LGPL 2.1 text, GCC Runtime Library Exception, or Dropbear's retained multi-component license/copyright notices.
- `NOTICE.md` explicitly says `LICENSES/LGPL-2.1-or-later.txt` is included, but that path is absent from the binary archive.
- Neither embedded CPIO contains those materials.
- The source archive retains the upstream texts, but the binary README/NOTICE does not name and hash the exact corresponding source archive as its paired source delivery.

This matters independently of the SBOM. GPLv2 object distribution must follow one of its source-delivery mechanisms, LGPL requires prominent notice that the library is used and a copy of the license, the GCC exception applies to files bearing its notice, and Dropbear's permissive notices must be retained. See [GNU GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html), [GNU LGPL 2.1](https://www.gnu.org/licenses/old-licenses/lgpl-2.1.en.html), [GCC Runtime Library Exception](https://gcc.gnu.org/onlinedocs/libstdc%2B%2B/manual/license.html), and [Dropbear upstream](https://matt.ucc.asn.au/dropbear/dropbear.html).

Required fix:

1. Add a top-level `LICENSES/` and component notice index to the binary package.
2. Preserve the exact upstream license/copyright notices shipped with each source.
3. Identify `xpr-os-0.1.0-rc3-sources.tar.gz` (or successor) and its SHA-256 as the corresponding source delivered alongside the binary.
4. State XPR modifications and external MPSS prerequisites without implying Intel redistribution.

Archive changed: binary archive and, because of B1, the successor source archive and binding hash.

### B4. Fixed Root Authorization Credential In Public Payload

Component: final-root access control.

Evidence:

- `payload/xpr-rootfs.cpio.gz` contains `root/.ssh/authorized_keys`, mode `0600`.
- Final init starts Dropbear and uses that authorization file.
- The key is omitted from the SPDX file list and source/provenance ledger.
- The outer archive verifier does not recurse into CPIO payloads, so its `authorized_keys` rejection did not detect this file.

The public key is not secret, but it is an active root authorization credential: anyone holding the matching private key can authenticate to every copy of the image. This is a concrete default-access vulnerability, not a copyright issue.

Required fix:

1. Remove the fixed authorization key from the release payload.
2. Add explicit user-supplied key injection or documented first-boot provisioning.
3. Make the package verifier recurse into nested CPIOs and reject fixed `authorized_keys` unless an explicitly approved test profile is being built.
4. Rebuild and revalidate the payload, networking, final-root SSH, smoke suite, and rollback because the tested payload hash changes.

Archive changed: binary archive and frozen tested artifact.

## Non-Blocking Findings

1. All 24 SPDX file records use `licenseConcluded: NOASSERTION` and `copyrightText: NOASSERTION`; package suppliers and source hashes/external references are also sparse. `NOASSERTION` is permitted, but this underuses evidence already present in source manifests and weakens the owner-review package.
2. The SPDX scope covers 7 packages and 24 hashed files, not every one of the roughly 78 payload members or every bootstrap member. All meaningful shipped ELF families are represented, but configuration, symlinks, device nodes, and the authorization file are not. Add a full payload member manifest and clearly define SBOM scope.
3. Provenance records use different commits for hardware-tested artifacts (`803a522...`), release packaging (`3009614...`), and final audit documentation (`aa18688...`). The hashes reconcile the artifacts, but the staged roles should be described explicitly to prevent an apparent source mismatch.
4. The modules contain a historical `2.6.38.8+mpss3.5.1` vermagic while the documented host prerequisite is MPSS 3.4.10. Hardware compatibility is already proven; this is a labeling/compatibility explanation gap, not evidence of proprietary content.

## Resolved Objections

1. **Intel copyright is not proprietary contamination.** The module source archive contains GPLv2 `COPYING`, and the mapped implementation files carry Intel copyright plus direct GPLv2 grants.
2. **No concrete Intel payload contamination was found.** Neither archive contains MPSS RPMs, firmware, an extracted SDK/sysroot, stock card userspace executables, or an unexplained Intel binary.
3. **Artifact substitution was not found.** Kernel, System.map, Base CPIO, payload, five modules, runtime binaries, and smoke probes match frozen manifests/checksums where tracked.
4. **The old `publication.allowed: false` state is not itself a defect.** It is an administrative gate; the blockers above are the actual defects.
5. **Hardware validation was not disputed or repeated.** The audit found no artifact-hash inconsistency that invalidates the recorded three-boot technical result.

## Disagreement And Challenge Matrix

| Claim | Raised by | Counterargument | Adjudication |
|---|---|---|---|
| Kernel/BusyBox config mismatches block source delivery | Corresponding-source and adversarial reviewers | Differences are line endings only; source itself exists | BLOCKER. Byte normalization explains both mismatches, but the frozen bytes contradict their raw-hash ledgers, the fail-closed kernel recipe rejects its shipped config, and fixed Git/path assumptions independently make that recipe non-executable. |
| Binary must carry third-party texts and source binding | License, SPDX, and notice reviewers | Source archive contains the texts; separate source delivery can satisfy obligations | BLOCKER. Separate delivery is viable, but the frozen binary does not provide the required notices or bind itself to an exact paired source artifact. |
| Invalid SPDX strings block release | SPDX/adversarial reviewers | SPDX is metadata, not the license grant; `NOASSERTION` is permitted | BLOCKER for invalid expressions/download location because the release claims SPDX 2.3 validation. NON_BLOCKING for permitted `NOASSERTION` fields. |
| Fixed `authorized_keys` blocks release | Archive and adversarial reviewers | A public key is not secret and was needed for hardware validation | BLOCKER. It grants reusable root authorization to an external private-key holder; replace it with user provisioning and retest the changed payload. |
| All payload members must be SPDX files | Adversarial reviewer | The SBOM intentionally focuses on component-bearing binaries | NON_BLOCKING if scope is clearly declared and a complete payload manifest exists; the missing authorization entry is independently B4. |
| Different commits prove source mismatch | Notice reviewer | Hardware, packaging, and docs were intentionally frozen at different stages and hashes bind each stage | NON_BLOCKING. Clarify roles; no mismatched binary was found. |

The two Terra High challenge passes were used only for the four material disputes. The anti-objection pass established that the configuration differences normalize exactly and that `NOASSERTION` is permitted; those points narrowed B1 and B2 but did not repair the frozen recipes/ledgers or invalid SPDX package fields. It also confirmed the source archives contain upstream license texts, while the binary's claimed `LICENSES/` path is absent. Neither challenge produced a file-based basis to remove B1, B2, B3, or B4.

## Component Matrix

Legend: `Yes*` means the material exists but a release-wide blocker prevents an unqualified pass.

| Component | Binary | Source | Exact source / pin | License / copyright | Build/config/mods | Corresponding source | Notices | SBOM | Proprietary | Blocker / notes |
|---|---:|---:|---|---|---|---|---|---|---|---|
| Compatibility kernel | Yes | Yes | Solros archive/revision/hash | GPL-2.0-only; COPYING present | Present, but wrong staged config and nonportable recipe | **No*** | Missing in binary | File mapped | None found | B1, B3 |
| `ringbuffer.ko` | Yes | Yes | Exact archive/source map/hash | GPL-2.0-only; Intel copyright | Kbuild/headers/deps present; depends on B1 kernel tree | Yes* | Missing in binary | File mapped; invalid package license | None found | B1, B2, B3 |
| `dma_module.ko` | Yes | Yes | Exact archive/source map/hash | GPL-2.0-only; Intel copyright | Kbuild/headers/deps present; depends on B1 kernel tree | Yes* | Missing in binary | File mapped; invalid package license | None found | B1, B2, B3 |
| `micscif.ko` | Yes | Yes | Exact archive/source map/hash | GPL-2.0-only; Intel copyright | Kbuild/headers/deps present; depends on B1 kernel tree | Yes* | Missing in binary | File mapped; invalid package license | None found | B1, B2, B3 |
| `mpssboot.ko` | Yes | Yes | Exact archive/source map/hash | GPL-2.0-only; Intel copyright | Kbuild/headers/deps present; depends on B1 kernel tree | Yes* | Missing in binary | File mapped; invalid package license | None found | B1, B2, B3 |
| `intel_micveth.ko` | Yes | Yes | Exact archive/source map/hash | GPL-2.0-only; Intel copyright | Kbuild/headers/deps present; depends on B1 kernel tree | Yes* | Missing in binary | File mapped; invalid package license | None found | B1, B2, B3 |
| BusyBox 1.19.4 | Yes | Yes | Archive pinned; frozen config raw hash contradicts ledger | GPL-2.0-only | Recipe/config present, but B1 staging mismatch | No* | Missing in binary | File mapped | None found | B1, B3 |
| Dropbear 2022.83 | Yes | Yes | Archive/hash pinned | Upstream MIT/BSD-style stack | Recipe/config present | Yes | Missing in binary | Invalid expression | None found | B2, B3; B4 affects provisioning |
| eglibc 2.19 | Yes | Yes | Orig/debian archives and overlays pinned | LGPL-2.1-or-later evidence | Build script/overlays present | Yes | Missing in binary | Runtime files mapped | None found | B3 |
| GCC sources | No compiler | Yes | Public KNC source/revision/hash | GPL-3.0-or-later | libgcc build recipe/patches present | Build input | Missing exception text in binary | Package mapping | None found | B3 for runtime notice |
| `libgcc_s.so.1` | Yes | Yes | GCC source/revision/hash | GPL-3.0-or-later WITH GCC-exception-3.1 | Build recipe present | Yes | Missing in binary | File mapped | None found | B3 |
| GMP | No runtime | Yes | Archive/version/hash pinned | Upstream license evidence | Compiler build input | N/A to shipped root | In source | Not a runtime package | None found | No blocker |
| MPFR | No runtime | Yes | Archive/version/hash pinned | Upstream license evidence | Compiler build input | N/A to shipped root | In source | Not a runtime package | None found | No blocker |
| MPC | No runtime | Yes | Archive/version/hash pinned | Upstream license evidence | Compiler build input | N/A to shipped root | In source | Not a runtime package | None found | No blocker |
| XPR bootstrap/init | Yes | Yes | Repository source/hash | MIT; project copyright | Source/build tooling present | Yes | Project MIT present | Files mapped | None found | B4 provisioning only |
| XPR root/build tooling | Scripts | Yes | Repository snapshot | MIT; project copyright | Present | Yes, except B1 execution defects | Project MIT present | Package mapping | None found | B1, B4 verifier gap |
| XPR smoke tests | Yes | Yes | Repository source/hash | MIT; project copyright | Build recipe present | Yes | Project MIT present | Files mapped | None found | No independent blocker |

## Final Archive Assessment

### Binary: `xpr-os-0.1.0-rc3.tar.gz`

- `HASH_VERIFIED`: PASS
- `CONTENTS_AUDITED`: PASS
- `LICENSE_MATERIAL_COMPLETE`: FAIL (B3)
- `SOURCE_MAPPING_COMPLETE`: PASS with non-blocking scope gaps
- `SECRET_SCAN`: PASS for secrets/private keys; FAIL release-security review for fixed root authorization (B4)
- `PROPRIETARY_SCAN`: PASS
- `SBOM_CONSISTENCY`: FAIL (B2)
- `FROZEN_ARTIFACT_CONSISTENCY`: PASS
- `RELEASE_READY_FACTUAL_STATUS`: FAIL

### Source: `xpr-os-0.1.0-rc3-sources.tar.gz`

- `HASH_VERIFIED`: PASS
- `CONTENTS_AUDITED`: PASS
- `LICENSE_MATERIAL_COMPLETE`: PASS at upstream-source level
- `SOURCE_MAPPING_COMPLETE`: FAIL executable reproduction chain (B1)
- `SECRET_SCAN`: PASS
- `PROPRIETARY_SCAN`: PASS
- `SBOM_CONSISTENCY`: FAIL (B2)
- `FROZEN_ARTIFACT_CONSISTENCY`: PASS internally, but internally consistent checksum records preserve the wrong config bytes
- `RELEASE_READY_FACTUAL_STATUS`: FAIL

## Counts And Final Status

- `BLOCKERS`: 4
- `NON_BLOCKING`: 4
- `RESOLVED`: 5
- `HUMAN_INTERPRETATION`: 0

Gate summary:

- Kernel: FAIL corresponding-source delivery
- Five modules: FAIL transitively on exact kernel build prerequisite; source/license mapping itself PASS
- SBOM: FAIL
- Corresponding source: FAIL
- Proprietary-content scan: PASS
- Notices: FAIL
- Archive integrity: PASS, except fixed root authorization makes the binary unsafe to publish

**FINAL CLASSIFICATION: BLOCKED_BY_CONCRETE_ISSUES**

## Minimum Refreeze Plan

1. Correct source staging and make the kernel/module reproduction path run from a clean source-archive extraction.
2. Regenerate valid SPDX 2.3 metadata and validate it independently.
3. Add the component license/notice bundle and exact binary-to-source pairing.
4. Replace fixed root authorization with user key provisioning and make nested-payload verification fail closed.
5. Build new binary/source archives under a successor RC identity, rerun archive/compliance audits, and repeat the bounded three-boot hardware gate for the changed payload.

RC3 itself should remain frozen as audit evidence and should not be published.
