# SSH Access

XPR-OS uses **SSH public-key authentication**. The generic release does not ship
with a shared root password or a universal administrator key.

For the tested `xpr-init` workflow, the host uses an RSA key pair:

- the **public** key is provisioned into deployment-specific copies of the XPR bootstrap and final root;
- the matching **private** key stays on the host and is used for authentication.

## Simplest Current Setup

Current `xpr-init` auto-discovery looks for compatible `ssh-rsa` public keys in
the invoking user's `~/.ssh` directory. If exactly one compatible public key is
found, it can be selected automatically.

The current default private identity is:

```text
~/.ssh/id_rsa
```

with the matching public key:

```text
~/.ssh/id_rsa.pub
```

If that pair already exists, the normal beginner path is simply:

```bash
sudo xpr-init --install
```

`xpr-init` does **not** currently generate a key pair automatically.

## If You Need A Dedicated XPR RSA Key

You can create one manually:

```bash
ssh-keygen -t rsa -b 3072 -f ~/.ssh/xpr_os_rsa -C "XPR-OS Xeon Phi access"
```

Then tell `xpr-init` about **both halves by path**—the public key for provisioning
and the private identity for host-side SSH:

```bash
sudo xpr-init --install \
  --authorized-key ~/.ssh/xpr_os_rsa.pub \
  --identity ~/.ssh/xpr_os_rsa
```

The private key is never copied into XPR-OS.

If multiple compatible RSA public keys already exist, `xpr-init` deliberately
stops rather than guessing which identity you intended. Use the explicit options
above.

## Connect To The Final XPR Root

After the normal reset/wait/boot sequence and automatic handoff completes:

```bash
ssh mic0
```

If you used a dedicated key and your SSH client does not select it automatically:

```bash
ssh -o IdentitiesOnly=yes -i ~/.ssh/xpr_os_rsa mic0
```

## Why Keys Instead Of A Password?

A shared password would create a universal credential for every copy of the
release. Generating a deployment password would also require password prompting,
hashing, storage, and noninteractive credential handling for the automatic
handoff.

With public-key authentication, the release can remain credential-free. Each
user authorizes a deployment-specific public key, while the secret private key
remains on the host. The same mechanism permits `xpr-init` to perform its
bootstrap checks and payload handoff without embedding a password in project
files.

## Why RSA?

RSA is the SSH key path that has been validated with the current CentOS 7.4 /
MPSS-era host environment and the Dropbear build used by XPR-OS. It is a legacy-
compatibility choice for the tested path. Other key types may be added only after
they are shown to work cleanly across this environment.

## Bootstrap SSH Versus Final SSH

During boot there are two distinct SSH servers:

1. The temporary XPR bootstrap starts SSH so the host can verify readiness and transfer the final root payload.
2. `xpr-init` verifies the payload and requests the switch to the final root.
3. The bootstrap SSH daemon is intentionally stopped during `switch_root`; its connection may disappear.
4. The final XPR root starts a new Dropbear SSH server.
5. `xpr-init` polls the final root and reports the handoff successful only when final-root readiness is proven.

A bootstrap SSH disconnect during the transition is therefore expected and is
not, by itself, a boot failure.

For installation details, see [xpr-init Host Integration](xpr-init-preview.md).
