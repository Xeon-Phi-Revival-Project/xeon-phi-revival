# xpr-init Host Integration

`xpr-init` is a host-side convenience tool for the tested RC6 workflow. It is
not part of the frozen RC6 runtime archive. It has been live-validated on the
project's CentOS 7.4 + MPSS 3.4.10 + Intel Xeon Phi 5110P configuration:

```text
install -> micctrl reset/wait/boot -> automatic handoff -> SSH -> recover
```

## Before You Begin

You need:

- a Xeon Phi 5110P that already boots stock MPSS and accepts stock SSH;
- the separately obtained MPSS 3.4.10 host stack used by the tested path;
- the XPR-OS 0.1.0-rc6 **binary** archive (`xpr-os-0.1.0-rc6.tar.gz`);
- the current XPR repository checkout, because `xpr-init` was added after the
  frozen RC6 archives were published; and
- an RSA SSH key pair, or OpenSSH's `ssh-keygen`. `xpr-init` provisions only
  the public key into deployment copies and never copies your private key into
  XPR-OS.

The current helper is obtained from this repository, so Git is also required.
On the tested CentOS 7 host, install it before cloning when it is absent:

```bash
sudo yum install -y git
```

For the simplest auto-discovery path, place the RC6 binary archive in the
invoking user's `~/Downloads` directory. `xpr-init` uses exactly one compatible
RSA public key with its matching private key when it finds one. If it finds no
such key, it creates `~/.ssh/xpr_os_rsa` and `~/.ssh/xpr_os_rsa.pub` for XPR-OS
only. Multiple candidates and incomplete dedicated key pairs fail safely; use
the explicit options shown below when discovery is ambiguous.

## Validated Workflow

```bash
# Obtain the current host helper.
git clone https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival.git
cd xeon-phi-revival

# Install the host command once.
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
# CentOS 7 sudo commonly omits /usr/local/sbin from secure_path.
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init

# The downloaded xpr-os-*.tar.gz is in the invoking user's Downloads folder.
# xpr-init finds one unambiguous release and a compatible RSA key, or creates
# a dedicated ~/.ssh/xpr_os_rsa key pair for XPR-OS.
sudo xpr-init --install

# A card that is already online must return to ready before micctrl can boot it.
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0

# The installed host service waits for the bootstrap, transfers and verifies
# the final root, and completes the handoff automatically. Then connect:
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

`--install` verifies the selected release, creates deployment-specific copies,
backs up and hashes the active stock MPSS configuration, installs XPR artifacts
below `/opt/xpr-os`, and changes the active MPSS configuration to reference the
XPR kernel and Base CPIO. It also installs the host handoff service.

After a normal XPR `micctrl --boot`, the service waits for bootstrap SSH,
transfers the final-root payload, verifies its byte count and SHA-256, requests
the `switch_root` transition, and waits for final XPR PID 1/network readiness.
The bootstrap SSH connection disappearing during `switch_root` is expected;
the final XPR root starts its own Dropbear SSH service.

`sudo xpr-init --status` reports the installed release, active configuration
mode, saved stock hash, current configuration hash, handoff-service state,
public-key hash, recovery availability, and `micctrl --status`. It does not
change card state or print private-key material.

`--recover` disables the handoff helper, restores and verifies the backed-up
stock configuration, resets `mic0`, waits for ready, and boots it back into
stock MPSS. The explicit fallback remains available as `sudo xpr-init handoff`
if systemd is unavailable or the automatic helper has been disabled.

The host-side installation, deployed artifacts, saved stock backup, and enabled
handoff unit persisted through one normal reboot of the tested host. Do not run
`--install` again after a normal reboot. The card-side XPR instance is
RAM-resident, not flashed: once `mic0` has booted again, use the normal
`micctrl --reset`, `--wait`, and `--boot` sequence and the persisted service
will complete the handoff.

The install/status/recover lifecycle, direct archive input, auto-discovery, and
service installation also have host-only fixture coverage. The live 5110P run
proved automatic handoff, final PID 1, micveth, authenticated final-root SSH,
and the hello/pthread/dlopen smoke programs. `xpr-init --recover` restored the
known stock configuration hash, stock boot, and stock SSH. This validation
applies to the tested host/card configuration only; other MPSS hosts and KNC
cards remain unvalidated.
