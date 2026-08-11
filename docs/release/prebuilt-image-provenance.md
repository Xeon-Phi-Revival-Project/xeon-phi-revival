# Prebuilt Image Provenance Status

This is an engineering evidence record, not a legal approval. The source/BYO-MPSS
RC2 remains the only public release lane.

## Historical Private Candidate

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

## Public-Clean Replacement Root

The separate public-clean root assembler has been exercised with only
project-owned files, the pinned source-built BusyBox, and pinned source-built
Dropbear. It produced 35 files, passed `audit-prebuilt-image.py --stage
candidate` with zero findings. The completed form now contains 78 files and
passed three identical hardware boots with the source-built runtime, final PID
1, networking, SSH, native smokes, and rollback.

## Complete RC3 Review Bundle

The source ledger records exact hashes for all shipped components. The private
RC3 review source archive includes:

- Solros K1OM Linux source and exact reproduction metadata;
- the complete MPSS 3.4.10 module source archive and dependency map;
- BusyBox 1.19.4 and Dropbear 2022.83;
- eglibc 2.19 orig and Ubuntu Debian delta plus XPR overlay;
- GCC KNC source plus GMP, MPFR, and MPC prerequisites;
- the exact project tree, configs, patches, recipes, notices, and manifests.

Independent staging builds have produced byte-identical binary and source
archives. Their final build commit, hashes, and automated gate results are
recorded after the package inputs are frozen in the
[RC3 review report](xpr-os-0.1.0-rc3-review-report.md).

See [the machine-readable source ledger](../../manifests/release/prebuilt-source-ledger.json)
and [the clean profile policy](../../manifests/release/prebuilt-clean-profile.json).

## Remaining Publication Gate

Mechanical provenance, corresponding-source staging, hardware validation, and
archive reproducibility are complete. A qualified human must still confirm the
GPLv2 distribution analysis for the five module binaries and review the exact
binary/source archives and notices. Until then RC2 remains the only public
release and no RC3 tag or attachment may be created.

Run the audit against a private candidate only:

```bash
python tools/release/audit-prebuilt-image.py \
  --rootfs /private/extracted-rootfs \
  --ledger manifests/release/prebuilt-clean-profile.json \
  --output /private/prebuilt-audit.json
```

The RC3 clean payload passes this audit. A passing automated audit still
requires human legal review before publication.
