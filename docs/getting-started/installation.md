# Install, Boot, And Use XPR-OS On An Intel Xeon Phi 5110P

For the tested CentOS 7.4 + MPSS 3.4.10 + Xeon Phi 5110P configuration, the
recommended beginner path is [xpr-init](xpr-init-preview.md). It validates the
release, provisions your public key, installs the MPSS configuration, performs
the final-root handoff automatically, and provides `sudo xpr-init --recover`
for returning to stock MPSS. The manual procedure below remains available for
advanced users and troubleshooting.

This is the canonical RC6 procedure for the **tested** configuration: Intel
Xeon Phi 5110P, CentOS 7.4, and MPSS 3.4.10. It is not a compatibility claim
for every Knights Corner card.

## Before You Begin

You need:

- A 5110P that already reaches `mic0: online` in stock MPSS. If you have not
  installed MPSS yet, start with [Installing MPSS 3.4.10](mpss-setup.md).
- A Linux MPSS host with root or `sudo` access, `bash`, Python with `argparse`,
  `tar`, `gzip`, `sha256sum`, OpenSSH, and the MPSS `micctrl` command.
- MPSS 3.4.10 obtained separately under Intel's terms. It is not in RC6.
- An RSA OpenSSH key pair. RC6's Dropbear build was validated with `ssh-rsa`.
- Both RC6 downloads: the binary archive **and** its paired source archive.
  The source archive provides the bounded boot/rollback runner.

Keep enough free disk space for the two archives, extraction, logs, and a
temporary deployment copy. Do not use a host where stock MPSS cannot already
boot and accept SSH.

## 1. Copy The Release To The MPSS Host

Download both RC6 archives on your workstation, then copy them to the MPSS
host. Replace `mpss-host` with the hostname or address of that host:

```bash
scp xpr-os-0.1.0-rc6.tar.gz xpr-os-0.1.0-rc6-sources.tar.gz \
  root@mpss-host:~/xpr-os-rc6/
ssh root@mpss-host
cd ~/xpr-os-rc6
```

You may instead download the two release assets directly on the MPSS host. All
remaining commands in this guide run on that host.

## 2. Start MPSS And Confirm The Stock Baseline

Run on the **MPSS host**:

```bash
sudo systemctl start mpss
micctrl --status
ssh mic0 'uname -m; cat /proc/1/comm'
sha256sum /etc/mpss/mic0.conf
```

Expected: `mic0: online`, `k1om`, and `init`. Save the configuration hash; the
runner requires it to prevent accidentally applying an experiment to an
unexpected MPSS configuration. If this fails, stop and use
[Troubleshooting](../troubleshooting/README.md).

## 3. Verify RC6

Download both files from the [RC6 release page](https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc6):

```text
xpr-os-0.1.0-rc6.tar.gz
xpr-os-0.1.0-rc6-sources.tar.gz
```

Verify their SHA-256 values on the **MPSS host**:

```bash
sha256sum xpr-os-0.1.0-rc6.tar.gz xpr-os-0.1.0-rc6-sources.tar.gz
```

Expected values:

```text
94867d9f58c12e7b04dcd0f2a8bfb176054d41b3c8e02f6c584c6efef4124d6c  xpr-os-0.1.0-rc6.tar.gz
bb530e170e9871627903644f52d8271c1f9c3375d4d3bc1d62c0c4eaa60a6558  xpr-os-0.1.0-rc6-sources.tar.gz
```

Do not continue if either value differs.

## 4. Extract And Verify The Binary Release

```bash
tar -xzf xpr-os-0.1.0-rc6.tar.gz
tar -xzf xpr-os-0.1.0-rc6-sources.tar.gz
cd xpr-os-0.1.0-rc6
./tools/verify.sh --archive ../xpr-os-0.1.0-rc6.tar.gz \
  --version 0.1.0-rc6 --expected-commit 97ad93d7d872744cba1d94dd4725a1931a1c54ae \
  --expect-validation passed
```

Expected final line: `PRECOMPILED_RC_VERIFY=PASS`. This checks the archive
contents, release metadata, SPDX, licenses, known artifacts, and key-free
generic payload.

## 5. Create Or Locate Your RSA Public Key

If you do not already have one, create a key on the **MPSS host**:

```bash
ssh-keygen -t rsa -b 3072 -f ~/.ssh/id_rsa
```

The public key is `~/.ssh/id_rsa.pub`. Keep `~/.ssh/id_rsa` private. Read
[SSH Access](ssh-access.md) before continuing.

## 6. Create Deployment-Only Copies

The generic RC6 payload deliberately contains no login key. Create deployment
copies containing **your public key only**:

```bash
mkdir -p deployment
python tools/provision-authorized-key.py \
  --generic-payload payload/xpr-rootfs.cpio.gz \
  --generic-bootstrap bootstrap/xpr-bootstrap.cpio.gz \
  --authorized-key ~/.ssh/id_rsa.pub \
  --output deployment/xpr-rootfs.cpio.gz \
  --bootstrap-output deployment/xpr-bootstrap.cpio.gz \
  --report deployment/key-provisioning.json
```

Expected output begins with `SSH_KEY_PROVISIONING_VALIDATION=PASS`. Never give
the command your private key file.

## 7. Manually Load And Boot XPR-OS With MPSS And `micctrl`

This is the direct operator path. It uses an alternate MPSS configuration, so
the stock `/etc/mpss/mic0.conf` remains unchanged. Run these commands as root
on the MPSS host from the extracted `xpr-os-0.1.0-rc6/` directory:

```bash
run_dir="$HOME/xpr-os-manual-$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$run_dir/conf"
cp -a /etc/mpss/. "$run_dir/conf/"

base=$(readlink -f deployment/xpr-bootstrap.cpio.gz)
kernel=$(readlink -f kernel/bzImage)
map=$(readlink -f kernel/System.map)
payload=$(readlink -f deployment/xpr-rootfs.cpio.gz)

sed -i "s|^Base CPIO .*|Base CPIO $base|" "$run_dir/conf/mic0.conf"
sed -i "s|^OSimage .*|OSimage $kernel $map|" "$run_dir/conf/mic0.conf"
sed -i "s|^RootDevice Ramfs .*|RootDevice Ramfs $run_dir/mic0.image.gz|" \
  "$run_dir/conf/mic0.conf"

micctrl --shutdown mic0
until micctrl --status | grep -q 'mic0: ready'; do sleep 5; done
micctrl --configdir="$run_dir/conf" --updateramfs mic0
micctrl --configdir="$run_dir/conf" --boot mic0
```

Wait for the bootstrap environment to reach `online`, then connect with your
deployment key:

```bash
until micctrl --status | grep -q 'mic0: online'; do sleep 5; done
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null \
  mic0 'uname -m; cat /proc/1/comm'
```

## 8. Transfer The Final XPR-OS Root And Switch To It

The first SSH command transfers the per-deployment final-root payload to the
bootstrap. The second verifies its SHA-256 and asks the bootstrap to stage and
switch to the final XPR root:

```bash
payload_sha=$(sha256sum "$payload" | awk '{print $1}')
payload_bytes=$(wc -c < "$payload")

ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mic0 \
  'cat > /tmp/xpr-rootfs.cpio.gz' < "$payload"

ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mic0 \
  "actual_bytes=\$(/bin/busybox wc -c < /tmp/xpr-rootfs.cpio.gz); \
   actual_sha=\$(sha256sum /tmp/xpr-rootfs.cpio.gz | awk '{print \$1}'); \
   test \"\$actual_bytes\" = \"$payload_bytes\" && \
   test \"\$actual_sha\" = \"$payload_sha\""

ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mic0 \
  "/opt/xeon-phi-revival/bin/xpr-stage-root /tmp/xpr-rootfs.cpio.gz $payload_sha"
```

The staging command causes the transition from the bootstrap to final XPR-OS.
Wait for SSH to return, then log into the final root:

```bash
until ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=8 mic0 \
  'test -f /run/xpr-os-init && cat /proc/1/comm'; do
  sleep 5
done
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mic0
```

At this point XPR-OS stays running. It does not return to stock automatically.
Use it normally, then follow [Returning To Stock MPSS](rollback.md) when you
want to end the session.

## 9. Optional: Use The Scripted Boot Method

The paired source archive contains a convenience runner for users who prefer a
single rollback-protected command. It performs the same alternate-config
`micctrl` boot and payload handoff as the manual steps above, while collecting
logs and restoring stock MPSS if a step fails. From `xpr-os-0.1.0-rc6/`, run:

```bash
stock_sha=$(sha256sum /etc/mpss/mic0.conf | awk '{print $1}')
bash ../xpr-os-0.1.0-rc6-sources/repository/tools/kernel/run-candidate-base-cpio-control.sh \
  --base deployment/xpr-bootstrap.cpio.gz \
  --kernel kernel/bzImage \
  --map kernel/System.map \
  --payload deployment/xpr-rootfs.cpio.gz \
  --expected-stock-sha "$stock_sha" \
  --minimal-public-smoke \
  --leave-running
```

Because this command includes `--leave-running`, a **successful** run leaves
XPR-OS booted instead of immediately restoring stock MPSS. That is the normal
mode when you want to use the operating system. Keep the printed run-directory
path; it contains the deployment logs and evidence.

If the command fails before completion, it restores stock MPSS automatically.
Do not interrupt a boot/reset cycle with firmware or flash operations.

## 10. Reconnect After A Scripted Boot

The manual path already ends in an XPR-OS SSH shell. When the convenience
runner reports success, connect from the **MPSS host**:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa \
  -o PubkeyAcceptedKeyTypes=+ssh-rsa \
  -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null mic0
```

Then follow [Verify XPR-OS](verifying-xpr-os.md), use the shell and programs as
needed, and run the manual [Rollback](rollback.md) procedure only when you want
to return to stock MPSS.

## 11. Use XPR-OS

This is a small release-candidate environment, not a desktop distribution. The
following commands provide a useful first check from the XPR-OS shell:

```bash
uname -a
cat /etc/os-release
pwd
ls /
mount
/usr/bin/xpr-hello
/usr/bin/xpr-pthread-smoke
/usr/bin/xpr-dlopen-smoke
```

Stay connected and use the system for as long as you need. The runner does not
restore stock MPSS after a successful `--leave-running` boot. Return to the
MPSS host and follow [Returning To Stock MPSS](rollback.md) only when you are
ready to end the XPR-OS session.

## If A Step Fails

Use [Troubleshooting](../troubleshooting/README.md). Preserve the runner's log
directory and report the card model, host OS, MPSS version, command, and
whether stock rollback succeeded.
