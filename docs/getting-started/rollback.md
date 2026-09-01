# Roll Back To Stock MPSS

For an installation made with `xpr-init`, the canonical recovery command is:

```bash
sudo xpr-init --recover
```

This recovery path has been live-validated on the project's Intel Xeon Phi 5110P
with CentOS 7.4 and MPSS 3.4.10.

## What xpr-init Recovery Does

`xpr-init --recover` is designed to:

1. load the saved installation state;
2. verify that the original stock MPSS configuration backup still matches its recorded hash;
3. disable and remove the automatic XPR handoff service;
4. restore the exact saved stock `mic0` configuration;
5. verify the restored configuration hash;
6. reset, wait for, and boot `mic0` using MPSS; and
7. preserve an archived record of the completed XPR installation state.

It does not need to flash firmware or erase the downloaded RC6 archive.

## Verify Recovery

After recovery:

```bash
micctrl --status
```

Confirm that `mic0` returns to the expected stock MPSS state and that the normal
stock environment is reachable using the host's established MPSS procedure.

For the project's validation baseline, recovery restored the known stock MPSS
configuration byte-for-byte and returned the card to the stock K1OM/SSH
environment with `/sbin/init.sysvinit` observed as PID 1.

## If xpr-init Cannot Perform Recovery

Do not improvise destructive firmware or flash operations. The original stock
configuration backup is deliberately preserved under the root-owned `xpr-init`
state area so that recovery can be audited.

The [manual RC6 installation procedure](installation.md) and release-validation
records retain the advanced rollback mechanics for troubleshooting. Historical
manual workflows may include restoring the stock MPSS configuration and then
using `systemctl start mpss`; those commands are **advanced fallback context**,
not the recommended `xpr-init` recovery path.

If the saved backup hash or configuration state is inconsistent, stop and inspect
the evidence rather than overwriting the original backup.
