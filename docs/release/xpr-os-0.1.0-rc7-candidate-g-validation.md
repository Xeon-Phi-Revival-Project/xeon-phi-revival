# RC7 Candidate G2 Validation

Candidate G2 is unpublished. Its source revision
is `079521e895b82fb3ccec2fe0b29cfb3ea0e1bb1d`. Candidate F remains historical
evidence; its runtime containers were preserved byte-for-byte in G.

## Frozen Staging Results

| Artifact | Size (bytes) | SHA-256 |
| --- | ---: | --- |
| `xpr-os-0.1.0-rc7.tar.gz` | 20901346 | `6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c` |
| `xpr-os-0.1.0-rc7-sources.tar.gz` | 383327044 | `9d1261fd42f87697ee84b3cff749487c92bf11eb9eba952fcf6ead3be6df4c4a` |

Two independent staging runs produced identical binary and source archives.
Both passed the precompiled release verifier. Publication-stage root audit:
771 files, zero errors. Embedded SPDX 2.3 validates with nine packages and
63 files, including explicit mappings for the host installer, SSH helper, and
deployment provisioner. All 17 audited card ELF files are K1OM.

Actual private-key payloads, universal authorization keys, Python 3.5 payload,
MPSS SDK binary payload, and standalone toolkit binary payload: zero.
The helper's OpenSSH private-key header parser literal is not key material.
Generic archives contain no generated SSH state.

## SSH Implementation And Host Tests

- `ssh xpr-mic0` selects the invoking user's actual client identity and separate
  `~/.ssh/xpr_os_known_hosts` with strict host-key checking.
- A private per-device ECDSA P-256 server identity is generated on the host and
  provisioned only into private bootstrap/final-root deployment images.
- Client private keys never enter the card image. Server identity and alias
  survive recovery for subsequent installations.
- CentOS 7 Bash/Python 2.7 install/recover fixtures pass: fresh RSA generation,
  identity reuse, idempotence, original user-config preservation, stock trust
  preservation, archive-hash binding, and cross-user reinstall rejection.
- An isolated non-root account test confirms invoking-user ownership and mode
  0600 for SSH configuration. Deployment host-key conversion and actual CPIO
  insertion passed on CentOS without altering the running deployment.
- Python 3 host tests pass all 14 public-key cases and the new CPIO host-key
  permission/non-directory rejection cases.

Lead and Luna reviewed the narrow SSH design. The proposed `Host *` precedence
regression was disproved with `ssh -G` and retracted. A retained limitation is
that a failed installation can leave bounded, reusable XPR alias/trust/key
state; these files are not a multi-file transaction. Stock trust remains
untouched, strict checking remains enabled, and installation errors are not
reported as success. Failure-injection coverage for those writes is pending.

## Resolved Hardware Preflight

Candidate F was recovered with the existing installer. Recovery reported PASS;
stock mic0 is online using the stock MPSS kernel. The restored configuration
SHA-256 is exactly:

`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`

Before G installation, normal `ssh mic0` failed with a host-key mismatch.
The unchanged root known-hosts file hashes to
`ca34f3ea8a34ec96d7fb1c6cdced25978d3a9aa8442f9541c82995c06d46f4b7`.
Its old ECDSA fingerprint is
`SHA256:wwisJpcUT+sNblRcJuRb+b/QRVB2ITQih+pbi7TAQ5Y`.
The stock card presents
`SHA256:jDlU/aLcUHPsKrWg5tYRdWWVLAeeVeeDZ+Z7ZqXvrq8`, matching the
stock public key in the trusted host's MPSS MicDir.

This is a pre-existing stock trust mismatch, not a Candidate G regression.
The owner explicitly authorized a backup and replacement of only the stale
`mic0` and `172.31.1.1` records using the independently verified stock public
key. Plain `ssh mic0` then passed. The repaired trust file SHA-256 is
`2f8efe48d85062a952ec7569f8a83bb54ad5358365bfcda2660a83ba2f628176`.
That repaired baseline, not the stale original, is used for subsequent
byte-for-byte stock trust preservation checks. The original remains backed up.

## Candidate Revision Boundary

G1 binary `9293c0cb689c0262a50a8c0a14c9ee8a57b1f09b8554e38177860780c4938b4d`
and source `3e05ed2ff3920106606fd158b86c51ba295dac9130330ce95d6b4dfea0871dea`
remain preserved. G1 passed alias login, native/Python regression, card reboot
reuse, reinstall, and stock recovery, but its embedded publication manifest
still referenced Candidate F archive hashes. It is not the publication set.

G2 generates candidate-local metadata instead. Self-referential archive hashes
are forbidden by a new consistency gate, tested against the rejected G1
manifest. The exact runtime containers, kernel, installer, SSH helper and
provisioner compare byte-identically between G1 and G2. No kernel, runtime,
Python, or authentication behavior changed for this metadata correction.

The source archive's `repository/` subtree preserves the build-revision source
snapshot, including the earlier Candidate F publication manifest and historical
release documents. Those files are not G2 artifact checksums or G2 validation
claims. Its top-level `SHA256SUMS` and generated `manifests/xpr-os.spdx.json`
account for the source delivery. The final external four-asset `SHA256SUMS` and
this record are authoritative for G2. The staging generator does not copy the
snapshot's old publication manifest into the binary: it generates the
candidate-local pending manifest shown by the release-consistency gate.

The first G1 test harness stopped because it used plain `tr`; the minimal root
provides `busybox tr`. Its safety trap recovered stock successfully. Correcting
only the harness allowed the subsequent complete G1 test to pass.

## Exact G2 Hardware Validation: 2026-09-09

The exact G2 archive completed its own three-boot cycle on the Intel Xeon Phi
5110P, CentOS 7.4 / MPSS 3.4.10 host. Results are not inferred from G1.
The [normalized hardware transcript](xpr-os-0.1.0-rc7-candidate-g2-hardware.txt)
has SHA-256
`82417f20d3b230eca6bd588eb67fc84a3a6275f7358c28d2323ca6e120cc3922`;
only the private candidate storage prefix was replaced with `CANDIDATE_G2`.

| Check | Result |
| --- | --- |
| Install exact G2; automatic bootstrap-to-final-root handoff | PASS |
| Plain `ssh xpr-mic0`, without additional options | PASS |
| Password prompt / host-key warning / special flags required | NO / NO / NO |
| Final `/sbin/init` PID 1; micveth; authenticated SSH | PASS |
| hello / pthread / dlopen | PASS / PASS / PASS |
| Python 3.12.13 / core imports / real threaded calculation / K1OM identity | PASS |
| Card reboot and SSH reuse; persistent server identity | PASS |
| Recovery, reinstall, identical managed config and reused client/server keys | PASS |
| Final recovery; stock online; normal `ssh mic0` | PASS |
| Stock known-hosts unchanged from approved repaired baseline | PASS |
| XPR alias rejects stock identity after recovery | PASS |

The card-only reboot test rearmed the existing one-shot handoff service with
`systemctl restart xpr-init-handoff@mic0.service` after reset/wait and before
boot. Automatic card-reset detection is not implemented or claimed. The initial
install and reinstall boots used the installed automatic handoff normally.

Runtime output included `XPR_RC_ROOT_SBIN_INIT_PID1`, `XPR_NETWORK_READY`,
`XPR_HELLO_OK`, `XPR_PTHREAD_OK`, `xpr-dlopen-smoke: ok`, and
`RC7 Python core smoke PASS`. The known Python `<exec_prefix>` warning remains
nonblocking and unchanged. Python host/card SHA-256 matched:
`259b2a33523ab8581cb70648c88f3a0b1be8f285eb2b21c42a60addf27c2a211`.

`xpr-init --status` identified the exact G2 archive hash, XPR mode, enabled
handoff unit and available recovery. Its inactive state after successful handoff
is expected for the one-shot unit. Stable server fingerprint:
`SHA256:G7LzZlIUoGmOv5CYhojHZueOPuXYaRjg7pHdGBlW5h4`.

Final stock PID 1 was observed as `/sbin/init.sysvinit`, not systemd. Stock
architecture was `k1om`; configuration SHA-256 was restored exactly to
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.
The G2 archive hash remained unchanged after the complete test. The machine is
left in stock mode. The original stale known-hosts backup remains preserved.

## Final Sidecars And Review

The [artifact inventory](xpr-os-0.1.0-rc7-artifact-inventory.md) and
[checksums](xpr-os-0.1.0-rc7-SHA256SUMS) identify the four final assets.
SPDX is an exact copy of the embedded SBOM. Notices were deterministically
packed from the embedded LICENSE, NOTICE.md and LICENSES directory. Neither
binary nor source archive was rebuilt after hardware validation.
Local revalidation passed SPDX 2.3 release coverage (nine packages, 63 files),
all four final checksums, byte identity of the external and embedded SPDX, and
exact content coverage of all 11 embedded license/notice files in the sidecar.
The final `SHA256SUMS` file hashes to
`8247c9f44f0042778f5d60db942afbf0726d6765df292e87f00cefcc84ef312e`.

Lead review and a Luna Medium narrow security review found no concrete RED
SSH isolation or recovery blocker. Retained failed-install convenience state
and missing failure-injection coverage are explicit nonblocking limitations,
not claims of transactionality. A final sidecar/hardware-binding review is
completed by the lead and a separate Luna Medium pass. The reviewer initially
flagged historical source-snapshot metadata, then retracted the blocker after
tracing the staging and verification paths: the historical manifest is not an
active validation input. The explicit snapshot/sidecar boundary above resolves
the remaining documentation ambiguity. No concrete RED issue remains.
Further convenience changes are deferred beyond RC7.

`FINAL_RC7_SSH_REVIEW=PASS`

## Status

`RC7_CANDIDATE_G=TECHNICALLY_PASS`

`RC7_PUBLICATION_PREP=PASS`

`RC7_PUBLICATION=AWAITING_OWNER_AUTHORIZATION`

`TOOLKIT_RC7_INCLUSION=HOLD_HUMAN_REVIEW`

No RC7 tag, public release, or public asset upload was created. Candidate G2
is the final metadata-corrected Candidate G, pending owner publication approval.
