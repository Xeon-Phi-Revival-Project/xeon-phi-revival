# xpr-init Host Integration

## RC7 Candidate G

Use the complete [RC7 install, readiness, use and recovery guide](rc7.md).
The short reference below assumes you have already verified the candidate.

Candidate G is unpublished. Use its packaged installer, not an older release's
installer, and do not use the current installer with frozen RC6: RC6 lacks the
new SSH setup helper. From an extracted Candidate G binary directory:

```bash
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init
sudo xpr-init --install --release /path/to/xpr-os-0.1.0-rc7.tar.gz
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
# Wait for final-root readiness using the check in the RC7 guide.
ssh xpr-mic0
# Later, on the host:
sudo xpr-init --recover
ssh mic0
```

The installer configures the invoking user's selected RSA identity, an isolated
XPR alias, and `~/.ssh/xpr_os_known_hosts`. Strict host-key checking remains on.
The deployment-specific server identity persists privately under
`/var/lib/xpr-init/ssh/mic0`; it is inserted only into private deployment images,
never the generic release. Client private keys remain on the host.

The alias and XPR trust remain after recovery for reuse. They intentionally do
not authenticate stock uOS. Stock `mic0` config and trust entries remain separate;
a pre-existing stock mismatch requires independently verified repair, not
disabling host-key checks.

For a card-only reset after a completed handoff, rearm the existing one-shot
service after `micctrl --reset` and `micctrl --wait`, before `micctrl --boot`:

```bash
sudo systemctl restart xpr-init-handoff@mic0.service
```

See the [exact Candidate G validation](../release/xpr-os-0.1.0-rc7-candidate-g-validation.md).

## Frozen RC6 Workflow

`xpr-init` is a host-side convenience tool for the tested RC6 workflow. It is
not part of the frozen RC6 runtime archive. It has been live-validated on the
project's CentOS 7.4 + MPSS 3.4.10 + Intel Xeon Phi 5110P configuration:

```text
install -> boot/handoff -> SSH -> reboot persistence -> recover
```

## Before You Begin

You need:

- a Xeon Phi 5110P that already boots stock MPSS and accepts stock SSH;
- the separately obtained MPSS 3.4.10 host stack used by the tested path;
- the XPR-OS 0.1.0-rc6 **binary** archive (`xpr-os-0.1.0-rc6.tar.gz`);
- an XPR repository checkout from which to retrieve the pinned RC6-compatible
  helper below, because it was added after RC6 was frozen; and
- an RSA SSH key pair, or OpenSSH's `ssh-keygen`. `xpr-init` provisions only
  the public key into deployment copies and never copies your private key into
  XPR-OS.

The pinned helper is obtained from this repository, so Git is also required.
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
# Obtain the repository containing the pinned RC6 host helper.
git clone https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival.git
cd xeon-phi-revival

# Use the earlier RC6-compatible helper, not the current RC7-only installer.
git show 61ab99ae15d0327b3c6b20fa5d6318cab2e76dcc:tools/host/xpr-init > /tmp/xpr-init-rc6
sudo install -m 755 /tmp/xpr-init-rc6 /usr/local/sbin/xpr-init
# CentOS 7 sudo commonly omits /usr/local/sbin from secure_path.
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init

# The downloaded xpr-os-*.tar.gz is in the invoking user's Downloads folder.
# xpr-init finds one unambiguous release and a compatible RSA key, or creates
# a dedicated ~/.ssh/xpr_os_rsa key pair for XPR-OS.
sudo xpr-init --install

# For an explicit first boot, or whenever mic0 is not already online with XPR:
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0

# The installed host service waits for the bootstrap, transfers and verifies
# the final root, and completes the handoff automatically.
# If xpr-init generated the dedicated key, connect with:
ssh -o IdentitiesOnly=yes -i ~/.ssh/xpr_os_rsa mic0

# If xpr-init reused an existing compatible RSA key instead, use that key's
# matching private-key path. xpr-init --status can help identify the installed
# key state without printing private-key material.

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

After an XPR `micctrl --boot`, the service waits for bootstrap SSH, transfers
the final-root payload, verifies its byte count and SHA-256, requests the
`switch_root` transition, and waits for final XPR PID 1/network readiness. The
bootstrap SSH connection disappearing during `switch_root` is expected; the
final XPR root starts its own Dropbear SSH service.

`sudo xpr-init --status` reports the installed release, active configuration
mode, saved stock hash, current configuration hash, handoff-service state,
public-key hash, recovery availability, and `micctrl --status`. It does not
change card state or print private-key material.

`--recover` disables the handoff helper, restores and verifies the backed-up
stock configuration, resets `mic0`, waits for ready, and boots it back into
stock MPSS. The explicit fallback remains available as `sudo xpr-init handoff`
if systemd is unavailable or the automatic helper has been disabled.

## What Happens After A Host Reboot

The host-side installation, deployed artifacts, saved stock backup, active XPR
MPSS configuration, and enabled handoff unit all persisted through a normal
reboot of the tested host. **Do not rerun `xpr-init --install` after a normal
reboot.**

On the validated CentOS 7.4 + MPSS 3.4.10 host, `mic0` was already reported
online with the installed XPR kernel when the host returned from that reboot,
and the persisted handoff service successfully reached the final XPR root. No
XPR-owned automatic boot wrapper and no `xpr-init --boot` command were required.

The project has not yet isolated the exact MPSS startup path responsible for
that observed card boot, so this is documented as tested behavior rather than a
general guarantee for every MPSS host. If `mic0` is not online with XPR after a
reboot, use the normal MPSS lifecycle:

```bash
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
```

The card-side XPR instance remains RAM-resident and is **not** flashed to the
Xeon Phi. Host-side XPR configuration persists; the running card-side instance
must be booted again after card/host power loss by whatever supported MPSS path
is active on that host.

## Validation Scope

The install/status/recover lifecycle, direct archive input, auto-discovery,
dedicated RSA-key generation, and service installation have host fixture
coverage and live 5110P validation. A fresh-user-state run on the existing
known-good CentOS 7.4 + MPSS 3.4.10 host passed archive discovery, automatic RSA
key generation, install, handoff, authenticated SSH, all three runtime smokes,
and exact stock recovery. That was not a literal fresh CentOS/MPSS installation.

The live runs proved automatic handoff, final PID 1, micveth, authenticated
final-root SSH, `xpr-hello`, `xpr-pthread-smoke`, and `xpr-dlopen-smoke`.
`xpr-init --recover` repeatedly restored the known stock configuration hash,
stock boot, and stock SSH. This validation applies to the tested host/card
configuration only; other MPSS hosts and KNC cards remain unvalidated.
