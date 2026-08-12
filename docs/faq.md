# Frequently Asked Questions

## What is the Xeon Phi Revival Project?

It is an AI-assisted, Codex-driven preservation and engineering project focused
on restoring useful software-development paths for Intel Xeon Phi Knights Corner
coprocessors and the K1OM architecture. XPR-OS is one major project track, not
the entire project.

## What is XPR-OS?

XPR-OS is the project's revived, source-accounted K1OM Linux operating
environment. The current public milestone is XPR-OS 0.1.0-rc6, hardware-tested
on an Intel Xeon Phi 5110P.

## What is xpr-init?

`xpr-init` is the host-side installer, MPSS integration helper, automatic
bootstrap-to-final-root handoff service, status tool, and recovery helper. It
does **not** replace Intel MPSS or `micctrl`; `micctrl` remains responsible for
normal card reset/wait/boot control.

See [xpr-init Host Integration](getting-started/xpr-init-preview.md).

## Is xpr-init part of the RC6 archive?

No. RC6 was frozen before `xpr-init` was developed and validated. The RC6 binary
archive supplies the XPR-OS runtime, while the current `xpr-init` helper is
obtained from this repository.

## Does xpr-init install XPR-OS permanently onto the Xeon Phi?

No. XPR-OS is booted into volatile card memory; it does not flash a persistent
XPR installation onto the card. A power loss removes the running card-side
instance.

The host-side `xpr-init` installation is persistent: its XPR images, state,
saved stock MPSS configuration, and enabled handoff service are stored on the
host. The exact cold-host-reboot cycle is still awaiting explicit live
validation, so the project does not yet label that behavior hardware-validated.

## Why use SSH keys instead of a root password?

The generic release should not contain a universal administrator credential.
Public-key authentication lets each deployment authorize its own key without
shipping a shared password, and it also lets the host-side automatic handoff use
SSH noninteractively without storing a password in a script or state file.

Only the public key is provisioned into the XPR deployment. The private key
stays on the host.

## Why RSA keys?

RSA is the authentication path that has been validated across the current
legacy host/OpenSSH and K1OM/Dropbear environment. This is a compatibility
choice, not a claim that RSA is the only desirable modern SSH key type.
Additional key types can be evaluated later and must be tested before becoming
part of the supported path.

## Does xpr-init generate an RSA key if I do not have one?

Not currently. It can auto-discover exactly one compatible `ssh-rsa` public key
in the invoking user's SSH directory, or you can provide a public key and its
matching private identity explicitly. Automatic creation of a dedicated XPR key
pair is tracked as a future improvement.

See [SSH Access](getting-started/ssh-access.md) and the
[xpr-init future changes roadmap](development/xpr-init-future-changes.md).

## Why does SSH disconnect during the automatic handoff?

There are two SSH phases. The temporary bootstrap starts Dropbear so `xpr-init`
can transfer and verify the final root payload. During `switch_root`, that
bootstrap SSH daemon is intentionally stopped, so its connection may close.
The final XPR root then starts its own Dropbear server. `xpr-init` treats final-
root readiness—not survival of the bootstrap connection—as authoritative.

## What hardware is supported?

The project currently makes a strong hardware-validation claim only for the
Intel Xeon Phi 5110P on the documented CentOS 7.4 + MPSS 3.4.10 host baseline.
Other Knights Corner cards are unvalidated. Knights Landing is a different
platform and is not an XPR-OS target.

See [Supported Hardware](hardware/supported-hardware.md).

## Is MPSS included in this repository?

No. Intel MPSS and other separately licensed Intel software are not distributed
by XPR. The tested host baseline uses MPSS 3.4.10 obtained separately under the
terms applicable to that software.

## Is the old manual RC6 installation procedure still useful?

Yes, but it is no longer the recommended beginner path. It remains valuable for
troubleshooting, release validation, and understanding the underlying Base CPIO,
payload transfer, and switch-root process.

See [Installing XPR-OS](getting-started/installation.md).

## Where should I read old experiments and failed approaches?

Use the [Research index](research/README.md). Historical notes are deliberately
preserved because failed experiments and old vendor behavior are useful evidence,
but they are separated from current user instructions.
