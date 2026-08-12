# XPR-Init Host Integration Preview

`xpr-init` is a post-RC6 host-side convenience tool under development for the
next XPR-OS release. It is not part of the frozen RC6 archive and has not yet
received hardware validation. It exists to make the normal operator flow:

```text
install -> micctrl reset/wait/boot -> handoff -> SSH -> recover
```

After validating it on hardware, the intended workflow is:

```bash
# Install the host command once from the source tree or future release package.
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
# CentOS 7 sudo commonly omits /usr/local/sbin from secure_path.
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init

# The downloaded xpr-os-*.tar.gz is in the invoking user's Downloads folder.
# xpr-init finds one unambiguous release and one compatible RSA public key.
sudo xpr-init --install

# A card that is already online must return to ready before micctrl can boot it.
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa mic0

# Later, when finished:
sudo xpr-init --recover
```

Use an explicit override when discovery is ambiguous or your files are stored
elsewhere:

```bash
sudo xpr-init --install \
  --release /path/to/xpr-os-0.1.0-rc6.tar.gz \
  --authorized-key /path/to/id_rsa.pub
```

`--install` copies deployment-specific XPR artifacts below `/opt/xpr-os`, backs
up and hashes the active stock MPSS configuration, and changes that active
configuration to reference the XPR kernel and Base CPIO. `handoff` transfers
and hash-checks the final root after the bootstrap comes online. The installed
systemd helper invokes it automatically after a normal XPR `micctrl --boot`.
`--recover` disables that helper, restores the backed-up stock configuration,
resets `mic0` to ready, and boots it back into stock MPSS.

`sudo xpr-init --status` reports whether an XPR configuration is installed and
then prints `micctrl --status`.

The explicit fallback remains available as `sudo xpr-init handoff` if systemd
is unavailable or the automatic helper has been disabled.

The install/status/recover lifecycle, direct archive input, auto-discovery, and
service installation have host-only fixture coverage, but the preview has not
yet been booted on a Xeon Phi. Do not use it on hardware until a dedicated
bounded validation has been recorded. For RC6, use the supported
[manual procedure](installation.md) or its rollback-protected scripted
alternative.
