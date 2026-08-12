# XPR-Init Host Integration Preview

`xpr-init` is a post-RC6 host-side convenience tool under development for the
next XPR-OS release. It is not part of the frozen RC6 archive and has not yet
received hardware validation. It exists to make the normal operator flow:

```text
install -> micctrl updateramfs -> micctrl boot -> handoff -> SSH -> recover
```

After validating it on hardware, the intended workflow is:

```bash
# Install the host command once from the source tree or future release package.
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init

# Configure the host one time for this deployment.
sudo xpr-init install --release ./xpr-os-<version> \
  --authorized-key ~/.ssh/id_rsa.pub

# Use normal MPSS commands whenever you want to start XPR-OS.
sudo micctrl --updateramfs mic0
sudo micctrl --boot mic0
sudo xpr-init handoff
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa mic0

# Later, when finished:
sudo xpr-init recover
```

`install` copies deployment-specific XPR artifacts below `/opt/xpr-os`, backs
up and hashes the active stock MPSS configuration, and changes that active
configuration to reference the XPR kernel and Base CPIO. `handoff` transfers
and hash-checks the final root after the bootstrap comes online. `recover`
restores the backed-up stock configuration before regenerating its ramfs and
booting `mic0`.

`sudo xpr-init boot` is also available as a convenience command for the normal
shutdown, `micctrl --updateramfs`, `micctrl --boot`, and handoff sequence.
`sudo xpr-init status` reports whether an XPR configuration is installed and
then prints `micctrl --status`.

The install/status/recover lifecycle has a host-only fixture test, but the
preview has not yet been booted on a Xeon Phi. Do not use it on hardware until
a dedicated bounded validation has been recorded. For RC6, use the supported
[manual procedure](installation.md) or its rollback-protected scripted
alternative.
