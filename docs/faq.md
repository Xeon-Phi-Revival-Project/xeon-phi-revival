# XPR-OS FAQ

## What is XPR-OS?

An open-source boot and Linux userspace environment for Intel Xeon Phi Knights
Corner coprocessors. See [Concepts](concepts/xpr-os.md).

## Does it work on the Xeon Phi 5110P?

Yes. RC6's runtime artifact set was validated on a 5110P with CentOS 7.4 and
MPSS 3.4.10.

## Does it work on a 7120P or another KNC card?

Not currently tested by this project. Do not assume compatibility from the
5110P result.

## Does it support Knights Landing?

No. Knights Landing is a different product generation and is not an XPR-OS
target.

## Do I still need MPSS?

Yes. The tested RC6 path uses a separately obtained MPSS 3.4.10 host install
and its host driver. RC6 does not redistribute MPSS or firmware.

## Does XPR-OS replace firmware?

No. The tested path is RAM-only and includes stock rollback; it does not flash
firmware or modify persistent card storage.

## Can I SSH into the card?

Yes on the tested path, using Dropbear and a deployment-only RSA public key.
See [SSH Access](getting-started/ssh-access.md).

## Can I use Ed25519?

Not in the validated RC6 path. Use an RSA public key.

## Is RC6 production-ready?

No. It is a hardware-tested release candidate, not a stable release.

## Can I build the image from source?

The release includes a corresponding source archive and build material. See
[Development](development/README.md) and [Release](release/README.md).

