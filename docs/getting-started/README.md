# Getting Started With XPR-OS

The RC6 path is tested on an Intel Xeon Phi 5110P attached to a CentOS 7.4 host
running MPSS 3.4.10. Read the pages in order:

1. [Install MPSS 3.4.10](mpss-setup.md)
2. [Copy, install, boot, and use XPR-OS](installation.md)
3. [SSH Access](ssh-access.md)
4. [Verify XPR-OS](verifying-xpr-os.md)
5. [Return To Stock MPSS when finished](rollback.md)

The planned simplified host integration is documented separately as an
unvalidated [XPR-Init preview](xpr-init-preview.md). It does not replace the
RC6 procedure yet.

> [!WARNING]
> This is release-candidate software for legacy coprocessor hardware. Do not
> run the boot path on an untested card or host without first confirming that
> stock MPSS boot and SSH work. The runner performs rollback automatically
> unless explicitly instructed to leave a successful XPR-OS session running.
