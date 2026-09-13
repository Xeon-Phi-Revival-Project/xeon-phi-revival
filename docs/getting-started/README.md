# Getting Started With XPR-OS

**Choose your release:** [RC7 Candidate G2](rc7.md) is an unpublished tester
path with its packaged installer and `ssh xpr-mic0`. The instructions below
are for published RC6 and its pinned older installer. Do not mix the two.

The tested RC6 path uses an Intel Xeon Phi 5110P attached to a CentOS 7.4 host
running MPSS 3.4.10. For that tested configuration, the recommended beginner
path is now the live-validated `xpr-init` workflow:

1. [Install MPSS 3.4.10](mpss-setup.md) and confirm stock `mic0` boot and SSH.
2. Download the XPR-OS 0.1.0-rc6 **binary** archive from the project release page.
3. [Install and configure XPR-OS with xpr-init](xpr-init-preview.md).
4. Use normal `micctrl --reset`, `--wait`, and `--boot` commands; `xpr-init`
   performs the bootstrap-to-final-root handoff automatically.
5. [Connect over SSH](ssh-access.md).
6. [Verify XPR-OS](verifying-xpr-os.md).
7. [Return to stock MPSS when finished](rollback.md), normally with
   `sudo xpr-init --recover`.

`xpr-init` was developed and hardware-validated after the frozen RC6 archives
were published, so obtain the pinned RC6-compatible helper using the linked guide, not the
current RC7-only helper from the repository tip.
The RC6 runtime/release assets themselves remain unchanged.

The longer [manual installation procedure](installation.md) remains available
for advanced users, troubleshooting, and understanding the underlying boot and
payload-handoff process.

> [!WARNING]
> This is release-candidate software for legacy coprocessor hardware. Do not
> run the boot path on an untested card or host without first confirming that
> stock MPSS boot and SSH work. The validated `xpr-init` recovery path preserves
> a hashed stock MPSS configuration backup and restores it when requested.
