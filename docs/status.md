# Project Status

## Current Release Work

Development is active. [XPR-OS 0.1.0-rc6](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6)
is the published precompiled release candidate. It preserves the exact runtime
artifacts validated during the RC5 three-boot gate and passed the RC6 targeted
release audit.

RC6 is a prerelease, not a stable release. It includes the project-built kernel,
modules, bootstrap, and final payload plus a paired source archive. Intel MPSS,
firmware, stock uOS contents, and extracted sysroots remain separate
user-supplied prerequisites.

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
- RC6 was packaged deterministically, independently audited, and published as
  a prerelease. The release tag and assets remain immutable release evidence.

## Historical Evidence

Earlier experiment reports, package-port work, and release candidates remain
in the repository as historical engineering evidence. Public source packages
include the source, configuration, build, license, and current release material
needed to reconstruct the candidate; machine-specific experiment transcripts
are intentionally excluded from those packages.
