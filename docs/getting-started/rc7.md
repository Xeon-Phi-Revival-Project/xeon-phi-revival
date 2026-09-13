# Try XPR-OS RC7

RC7 Candidate G2 is **unpublished**. This guide is for owner-provided candidate
files; it does not announce a public download. The tested setup is an Intel
Xeon Phi 5110P with CentOS 7.4 and separately obtained Intel MPSS 3.4.10.
Other cards and host stacks are not validated by these instructions.

## 1. Start With Working Stock MPSS

Run these commands on the **MPSS host**, not on the card or a Windows PC:

```bash
micctrl --status
ssh mic0 'uname -m; readlink /proc/1/exe'
```

Require an online card, working stock SSH, and `k1om`. The project's stock
PID 1 is `/sbin/init.sysvinit`. If stock does not work, stop and follow
[MPSS setup](mpss-setup.md) first. Do not disable host-key checking to bypass a
stock SSH mismatch; verify its identity independently.

MPSS is not included with XPR. This procedure neither installs MPSS nor flashes
the card. Programs and files on the running card are RAM-resident and are lost
when it resets; copy anything important back to the host before recovery.

## 2. Verify And Install The Candidate

Place the binary, source, SPDX, notices archive and `SHA256SUMS` from the same
G2 set in `~/Downloads/xpr-rc7`. Names and hashes are in the
[artifact inventory](../release/xpr-os-0.1.0-rc7-artifact-inventory.md).
The ordinary install uses the **binary** archive, not the source archive.

On the **host**:

```bash
cd ~/Downloads/xpr-rc7
sha256sum -c SHA256SUMS
# Stop if any checksum fails.
release="$PWD/xpr-os-0.1.0-rc7.tar.gz"
tar -xzf "$release"
cd xpr-os-0.1.0-rc7
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init
sudo xpr-init --install --release "$release"
```

Use the installer in this candidate. **Do not pair the current RC7 installer
with frozen RC6**, which lacks the required SSH helper. RC6 has a
[separate pinned-installer workflow](xpr-init-preview.md#frozen-rc6-workflow).

No manual key creation is normally needed: one compatible RSA pair is reused,
or a dedicated `~/.ssh/xpr_os_rsa` pair is generated if none exists. Ambiguous
or incomplete pairs fail safely; specify your intended pair with
`--authorized-key ~/.ssh/id_rsa.pub --identity ~/.ssh/id_rsa` if needed.
Under sudo, SSH configuration belongs to the invoking user. Use that same user
for subsequent SSH commands, without sudo. Never share private deployment
images or keys. See [SSH details](ssh-access.md).

The command is now available from any directory. Explicit `--release` avoids
auto-discovery ambiguity between the archive and its extracted directory.
Installation saves stock configuration and enables automatic handoff; it does
not boot the card itself.

## 3. Boot And Wait For The Final Root

On the **host**:

```bash
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
```

The boot command returns before XPR is ready. The September 10 test needed
another 77 seconds; this is an observation, not a fixed deadline. Bootstrap
SSH appears and disappears during handoff. Do not mistake it for the final root.
Use this bounded check on the host before connecting interactively:

```bash
ready=no
for attempt in $(seq 1 60); do
    if timeout 10 ssh xpr-mic0 'grep -q XPR_RC_ROOT_SBIN_INIT_PID1 /run/xpr-os-init && grep -q XPR_NETWORK_READY /run/xpr-os-init' 2>/dev/null; then
        ready=yes
        break
    fi
    sleep 4
done
printf 'Final XPR ready: %s\n' "$ready"
```

Continue only when it prints `yes`. If it prints `no`, inspect
`sudo xpr-init --status` and
`sudo journalctl -u xpr-init-handoff@mic0.service -n 30 --no-pager`, then run
`sudo xpr-init --recover`. Do not bypass host-key checks or repeatedly reset an
unhealthy card.

## 4. Connect And Use XPR

On the **host**, as the user who installed it:

```bash
ssh xpr-mic0
```

No extra identity flags, password or host-key confirmation should be needed.
On the **card**:

```bash
cat /run/xpr-os-init
uname -m
/usr/bin/xpr-hello
/usr/bin/xpr-pthread-smoke
/usr/bin/xpr-dlopen-smoke
command -v python3
python3 --version
python3 - <<'PY'
import json, math, pathlib, platform, sys, threading
assert sys.version_info[:3] == (3, 12, 13)
assert platform.machine() == "k1om"
result = []
t = threading.Thread(target=lambda: result.append(math.sqrt(144)))
t.start()
t.join()
assert result == [12.0]
p = pathlib.Path("/tmp/xpr-example.json")
p.write_text(json.dumps({"result": result}))
assert json.loads(p.read_text())["result"] == [12.0]
p.unlink()
print("Python threading and JSON/file workflow PASS")
PY
```

Expected native output: `XPR_HELLO_OK`, `XPR_PTHREAD_OK`, and
`xpr-dlopen-smoke: ok`. Python is 3.12.13. The known
`Could not find platform dependent libraries <exec_prefix>` warning remains in
G2; these core operations pass despite it. Optional compression, TLS, database,
and ctypes modules are not promised by this core package. This is a minimal
prerelease runtime, not a full distribution: `which` is absent, so use the shell
builtin `command -v`; use `busybox tar` when extracting files on the card.

You can keep using XPR until you choose to recover. No test timer automatically
rolls back a normal installation.

## 5. Return To Stock When Finished

Leave the card shell and run recovery on the **host**:

```bash
exit
sudo xpr-init --recover
micctrl --status
ssh mic0 'uname -m; readlink /proc/1/exe'
```

Require recovery PASS, stock online, and working normal `ssh mic0`. Recovery
verifies your saved configuration hash. The project's baseline hash is evidence
for its host, not a configuration value to impose on other users' hosts.

The XPR alias and its isolated trust persist for reuse. While stock is active,
`ssh xpr-mic0` intentionally rejects the different stock identity; use `ssh mic0`.
If recovery fails, stop and preserve the backup. See [rollback](rollback.md).

## Later Reboots

Host-side installation persists; XPR is not permanently installed on the card.
If you reset only the card after handoff has completed, rearm the one-shot
service between wait and boot, on the host:

```bash
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo systemctl restart xpr-init-handoff@mic0.service
sudo micctrl --boot mic0
```

Then repeat the readiness check. Automatic card-reset detection is not
implemented. After a host reboot, inspect `micctrl --status` and XPR readiness
before issuing another boot; do not blindly reinstall on every host reboot.

## Release Boundary

The [G2 validation record](../release/xpr-os-0.1.0-rc7-candidate-g-validation.md)
binds testing to exact archive hashes. This guide is an external documentation
update; it does not change the frozen candidate. The standalone K1OM toolkit
binary remains excluded pending its separate qualified terms review.
No RC7 tag or public release is authorized by this guide.
