# Project Status

## Current Release Work

Development is active. XPR-OS `0.1.0-rc6` is an unpublished
documentation/package-cleanup candidate. It preserves the exact runtime
artifacts validated during the RC5 three-boot gate and changes only
release-facing metadata and public-source archive membership.

RC6 must pass a targeted independent audit before an owner publication
decision. It is not a GitHub release, tag, or approval to redistribute any
third-party binary.

The published source/metadata/BYO-MPSS prerelease remains
[XPR-OS 0.1.0-rc2](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc2).
It intentionally contains no private boot binaries or Intel/MPSS payloads.

## Verified RC5 Runtime Baseline

The RC5 runtime artifact set passed three identical rollback-protected boots on
an Intel Xeon Phi 5110P with CentOS 7.4 and MPSS 3.4.10. Every boot proved:

- the project final `/sbin/init` as PID 1;
- micveth networking and authenticated Dropbear SSH;
- dynamic hello, pthread, and `dlopen` probes;
- rollback to stock `mic0`, stock SSH, stock init, and the documented stock
  configuration hash.

RC6 may rely on that hardware evidence only while its kernel, five modules,
Base CPIO, nested bootstrap, and final payload remain byte-identical to RC5.
The RC6 review report records that comparison.

## Current Boundaries

- No firmware, ROM, flash, or persistent card-storage modification is used.
- Intel MPSS host software, firmware, SDK payloads, stock uOS contents, and
  extracted Intel sysroots remain external user-supplied prerequisites.
- Generic release containers contain no private key, password, credential, or
  fixed `authorized_keys` file. A user-owned RSA public key is validated and
  applied only to deployment-specific copies.
- The RC6 candidate is frozen for targeted audit after deterministic package
  builds and archive validation. It must not be published until that audit and
  owner decision complete.

## Historical Evidence

Earlier experiment reports, package-port work, and release candidates remain
in the repository as historical engineering evidence. Public source packages
include the source, configuration, build, license, and current release material
needed to reconstruct the candidate; machine-specific experiment transcripts
are intentionally excluded from those packages.
