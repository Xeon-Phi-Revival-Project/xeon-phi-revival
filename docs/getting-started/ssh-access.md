# SSH Access To XPR-OS

RC6 has no shared password and no universal authorized key. You provide one
RSA **public** key when creating a local deployment copy.

## Public And Private Keys

```text
PRIVATE - keep secret: ~/.ssh/id_rsa
PUBLIC  - provide to XPR-OS: ~/.ssh/id_rsa.pub
```

Never upload, paste, commit, or pass `id_rsa` to the XPR provisioner. The
provisioner accepts one LF-terminated `ssh-rsa` public-key line, validates its
SSH wire format, and rejects private-key material.

Create a compatible key on the **MPSS host** if needed:

```bash
ssh-keygen -t rsa -b 3072 -f ~/.ssh/id_rsa
```

Provision it with the exact command in [Installing XPR-OS](installation.md).
The output copies are local deployment artifacts; do not redistribute them.

## Connect

After the bounded runner has completed successfully with `--leave-running`, run
on the **MPSS host**:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/id_rsa mic0
```

The tested MPSS virtual network uses host `172.31.1.254` and card
`172.31.1.1`; the `mic0` SSH host alias is the preferred connection target.

## Common Failures

- `Permission denied (publickey)`: verify that the public key supplied to the
  provisioner matches the private key selected by SSH.
- `No route to host` or timeout: wait for the runner to finish and inspect its
  log directory. Do not repeatedly hammer SSH while the card is booting.
- Key rejected before boot: confirm the file is `~/.ssh/id_rsa.pub`, not
  `~/.ssh/id_rsa`. Only RSA is supported by the tested RC6 Dropbear path.

See [Troubleshooting](../troubleshooting/README.md) for safe next actions.

