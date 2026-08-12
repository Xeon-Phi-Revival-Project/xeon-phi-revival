# XPR-Init Host Integration Preview

`xpr-init` is a post-RC6 host-side convenience tool under development for the
next XPR-OS release. It is not part of the frozen RC6 archive and has not yet
received hardware validation. It exists to make the normal operator flow:

```text
install -> micctrl updateramfs -> micctrl boot -> handoff -> SSH -> recover
```

After validating it on hardware, the intended workflow is:

```bash
sudo ./tools/host/xpr-init install --release ./xpr-os-<version> \
  --authorized-key ~/.ssh/id_rsa.pub
# install places the command at /usr/local/sbin/xpr-init
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

Do not use this preview on hardware until a dedicated bounded validation has
been recorded. For RC6, use the supported [manual procedure](installation.md)
or its rollback-protected scripted alternative.
