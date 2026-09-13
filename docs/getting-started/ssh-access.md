# SSH Access

## RC7 Candidate G2

Use the [RC7 guide](rc7.md) for installation and final-root readiness. After
installing and booting G2, connect from the MPSS host as the invoking user:

```bash
ssh xpr-mic0
```

The installer selects one compatible RSA (`ssh-rsa`) pair or automatically
creates `~/.ssh/xpr_os_rsa` when none exists. Existing `id_rsa` and
`id_rsa.pub` can be reused. Multiple or incomplete pairs require explicit
selection; private keys are never overwritten. For an intentional existing pair:

```bash
sudo xpr-init --install --release /path/to/xpr-os-0.1.0-rc7.tar.gz \
  --authorized-key ~/.ssh/id_rsa.pub --identity ~/.ssh/id_rsa
```

A managed block in `~/.ssh/config` selects the actual client key and isolated
`~/.ssh/xpr_os_known_hosts`. Strict checking remains enabled. The host stores a
private deployment-specific ECDSA server identity and provisions it only into
private boot images. Client private keys never go to the card; generic release
archives contain no credentials. Do not share deployment images.

Do not run SSH with sudo when installation was invoked by a non-root user.
The alias belongs to that user's home. Normal stock trust is not replaced.
After `sudo xpr-init --recover`, use `ssh mic0` for stock. The persistent XPR
alias should reject stock's different host key; do not bypass that protection.

## Frozen RC6

RC6 lacks the new SSH helper. Use the
[pinned RC6 installer](xpr-init-preview.md#frozen-rc6-workflow), not the current
RC7 installer. The older path also supports dedicated RSA generation, but does
not provide G2's persistent isolated alias. Use the matching client key as
explained in that guide:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/xpr_os_rsa mic0
```

If an existing pair was selected instead, use its matching private-key path.
A host-key mismatch is not a password problem: verify the expected identity
before changing trust. Never globally disable host-key checking.

## Bootstrap Versus Final SSH

Bootstrap SSH exists only to transfer the final root. It disappears during
`switch_root`; final Dropbear starts afterward. A connection alone does not
prove the final root is ready. Use the bounded marker check in the RC7 guide.
The host handoff unit becomes inactive after successful completion; this is
normal for its one-shot behavior, not necessarily a failure.

RSA client authentication is the validated legacy-host compatibility path.
The server ECDSA identity is a separate key with a different purpose.
