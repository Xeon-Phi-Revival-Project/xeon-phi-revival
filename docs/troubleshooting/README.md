# XPR-OS Troubleshooting

Start with the symptom, keep SSH attempts bounded, and preserve runner logs.
Do not flash firmware as a troubleshooting step.

| Symptom | Safe first checks | Next page |
| --- | --- | --- |
| `mic0` is absent or not online | `lspci -nn`, `systemctl status mpss`, `micctrl --status` | [Hardware](../hardware/supported-hardware.md) |
| Stock SSH does not work | `ssh mic0 'uname -m; cat /proc/1/comm'` | [Rollback](../getting-started/rollback.md) |
| RC6 verifier fails | Recheck archive SHA-256 and rerun `./tools/verify.sh` | [Installation](../getting-started/installation.md) |
| RSA key is rejected | Confirm `id_rsa.pub`, not `id_rsa`, was supplied | [SSH Access](../getting-started/ssh-access.md) |
| Boot stops or remains booting | Keep the runner log directory; inspect `summary.txt`, `run.log`, and console capture | [Boot Process](../concepts/boot-process.md) |
| Payload checksum or transfer fails | Recreate deployment copies from verified generic artifacts | [Installation](../getting-started/installation.md) |
| SSH cannot reach final XPR-OS | Check runner summary, micveth, and the chosen RSA key | [SSH Access](../getting-started/ssh-access.md) |
| Smoke tests fail | Record exact probe output and rollback result | [Verification](../getting-started/verifying-xpr-os.md) |
| Rollback does not finish | Stop further experiments; collect MPSS state and logs | [Rollback](../getting-started/rollback.md) |

When reporting an issue, include card model, PCI ID, host OS, MPSS version,
XPR-OS version, command, output, and whether stock rollback succeeded. Never
post a private key, password, or private network details.

