# Prebuilt Image Provenance Status

This is an engineering evidence record, not a legal approval. The source/BYO-MPSS
RC2 remains the only public release lane.

## Audited Private Candidate

The locally retained `banner-hw-20260810-011819` candidate was audited without
copying its payload into the repository:

- candidate kernel: `0450c4370fb9c023c5229274d9a7a5cc02b8a37838c3220a0c714fc602cb2505`
- bootstrap Base CPIO: `42b7560f8dcc277f1d976e40db57668caedb749125e66171281ea8ba755e3bef`
- final payload: `4d4e3169324afd5d3e360c542c09de7d70f3c013c5d43edbf7b3c63db5e57ac2`
- final payload size: `77,582,100` bytes compressed
- audit result: `FAIL` by policy, with `2,916` files and `2,448` findings.

The dominant removable class is the legacy Python 3.5 tree. Readline and
OpenSSL 1.0.x are also present and excluded by the public-clean policy. The
remaining errors are intentionally fail-closed until each executable and
library has complete source, license, build, and redistribution evidence.

## Clean Replacement Root

The separate public-clean root assembler has been exercised with only
project-owned files, the pinned source-built BusyBox, and pinned source-built
Dropbear. It produced 35 files, passed `audit-prebuilt-image.py --stage
candidate` with zero findings, and generated valid SPDX JSON. This is a
technical candidate gate, not publication approval and not a bootable image:
the kernel, modules, eglibc runtime, and `libgcc_s` are intentionally absent
until their corresponding-source records are complete.

## Components With Exact Cached Source Evidence

The source ledger records exact hashes for these locally cached upstream
archives and current private binary matches:

- BusyBox 1.19.4, with the committed K1OM configuration and a source build
  recipe. The private payload's BusyBox hash matches the source-built artifact.
- Dropbear 2022.83, built using `tools/uos/build-k1om-dropbear.sh`. The private
  payload's Dropbear hash matches the recorded source-built artifact.
- CPython 3.12.13 source archive, verified against Python.org's published
  SHA-256. Its release build recipe and complete notice bundle remain required.

See [the machine-readable source ledger](../../manifests/release/prebuilt-source-ledger.json)
and [the clean profile policy](../../manifests/release/prebuilt-clean-profile.json).

## Non-Negotiable Remaining Blockers

The compatibility kernel, the five runtime modules, the exact eglibc baseline,
and `libgcc_s` lack authoritative corresponding-source provenance. They must
remain out of a public binary release until pinned source, patches, config,
build commands, hashes, and licenses are assembled and a rebuilt image passes
hardware validation.

Run the audit against a private candidate only:

```bash
python tools/release/audit-prebuilt-image.py \
  --rootfs /private/extracted-rootfs \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --output /private/prebuilt-audit.json
```

It is expected to fail until all ledger fields are complete and every excluded
payload has been removed. A passing automated audit still requires human legal
review before publication.
