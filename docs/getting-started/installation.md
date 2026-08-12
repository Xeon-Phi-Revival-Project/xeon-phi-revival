# Installing XPR-OS On An Intel Xeon Phi 5110P

This is the canonical RC6 procedure for the **tested** configuration: Intel
Xeon Phi 5110P, CentOS 7.4, and MPSS 3.4.10. It is not a compatibility claim
for every Knights Corner card.

## Before You Begin

You need:

- A 5110P that already reaches `mic0: online` in stock MPSS.
- A Linux MPSS host with root or `sudo` access, `bash`, Python with `argparse`,
  `tar`, `gzip`, `sha256sum`, OpenSSH, and the MPSS `micctrl` command.
- MPSS 3.4.10 obtained separately under Intel's terms. It is not in RC6.
- An RSA OpenSSH key pair. RC6's Dropbear build was validated with `ssh-rsa`.
- Both RC6 downloads: the binary archive **and** its paired source archive.
  The source archive provides the bounded boot/rollback runner.

Keep enough free disk space for the two archives, extraction, logs, and a
temporary deployment copy. Do not use a host where stock MPSS cannot already
boot and accept SSH.

## 1. Confirm The Stock Baseline

Run on the **MPSS host**:

```bash
micctrl --status
ssh mic0 'uname -m; cat /proc/1/comm'
sha256sum /etc/mpss/mic0.conf
```

Expected: `mic0: online`, `k1om`, and `init`. Save the configuration hash; the
runner requires it to prevent accidentally applying an experiment to an
unexpected MPSS configuration. If this fails, stop and use
[Troubleshooting](../troubleshooting/README.md).

## 2. Download And Verify RC6

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

## 3. Extract And Verify The Binary Release

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

## 4. Create Or Locate Your RSA Public Key

If you do not already have one, create a key on the **MPSS host**:

```bash
ssh-keygen -t rsa -b 3072 -f ~/.ssh/id_rsa
```

The public key is `~/.ssh/id_rsa.pub`. Keep `~/.ssh/id_rsa` private. Read
[SSH Access](ssh-access.md) before continuing.

## 5. Create Deployment-Only Copies

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

## 6. Run The Bounded Boot And Rollback Path

The generic release includes artifacts; the paired source archive includes the
tested runner. From `xpr-os-0.1.0-rc6/`, run on the **MPSS host**:

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

The runner creates a timestamped log directory below
`$HOME/xpr-candidate-kernel-test/`. It first verifies stock MPSS, uses an
alternate configuration, captures logs, and rolls back automatically on error.
`--leave-running` is honored only after the complete minimal smoke path passes.

If the command exits or a smoke test fails, it restores stock MPSS. Do not
interrupt a boot/reset cycle with firmware or flash operations.

## 7. Connect And Verify

When the runner reports success, connect from the **MPSS host**:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa mic0
```

Then follow [Verify XPR-OS](verifying-xpr-os.md). When finished, follow
[Rollback](rollback.md) to return to stock MPSS.

## If A Step Fails

Use [Troubleshooting](../troubleshooting/README.md). Preserve the runner's log
directory and report the card model, host OS, MPSS version, command, and
whether stock rollback succeeded.

