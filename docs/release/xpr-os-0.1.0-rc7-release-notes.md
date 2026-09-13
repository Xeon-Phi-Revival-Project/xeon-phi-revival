# XPR-OS v0.1.0-rc7

RC6 proved the revived operating environment. RC7 makes that environment more
practical to use by adding source-accounted CPython 3.12.13 and packaging the
`xpr-init` host integration path with an isolated XPR SSH alias. This remains prerelease software
for legacy Intel Xeon Phi hardware.

## Highlights

- CPython 3.12.13 is included and hardware-validated on the Xeon Phi 5110P.
- `xpr-init` provides installation, automatic final-root handoff, status, and
  exact stock recovery.
- The public-clean root uses fresh source-built K1OM runtime inputs.
- First installation configures `ssh xpr-mic0` with a persistent,
  deployment-specific server identity and strict host-key checking.
- Exact candidate validation and reproducibility results accompany the frozen
  archives as external evidence; embedded metadata is not changed after testing.

## Python

Python is installed at `/usr/bin/python3.12`; `python3` and `python` resolve to
that interpreter. The build is source-accounted, reports K1OM, and includes the
core standard-library profile validated for RC7. Hardware tests covered `sys`,
`os`, `pathlib`, `json`, `math`, `threading`, and `platform`, including a real
threaded calculation. Broad optional extension-module support is not claimed.

## Validation

The tested hardware baseline is Intel Xeon Phi 5110P with CentOS 7.4 and MPSS
3.4.10. Exact Candidate G2 passed installation, automatic handoff, native/Python
smokes, plain `ssh xpr-mic0`, card reboot/reuse, reinstall, and exact stock
recovery. See the [G2 validation record](xpr-os-0.1.0-rc7-candidate-g-validation.md).
The card-only reboot test explicitly rearmed the one-shot handoff service;
automatic card-reset detection is not claimed.

## Reproducibility And Source Accounting

The release set pairs the binary archive with corresponding source, SPDX 2.3,
and notices/licenses. Consult external checksums and validation results for the
exact candidate. Generic archives contain no deployment keys; installation
creates private per-host deployment images instead.

## Host Workflow

Follow the [complete RC7 guide](../getting-started/rc7.md) for artifact
verification, bounded final-root readiness, SSH, Python and recovery. The
reference below is not a substitute for waiting for readiness after boot.

After extracting the binary archive, install `xpr-init`, run its install step,
and use the normal MPSS lifecycle:

```bash
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init
sudo xpr-init --install
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
# Complete the final-root readiness check in the guide before connecting.
ssh xpr-mic0
python3 --version
```

Return to stock MPSS with `sudo xpr-init --recover`, then use normal `ssh mic0`.
Installation preserves the user's normal stock SSH configuration and known-host
records. The XPR alias and its separate `~/.ssh/xpr_os_known_hosts` persist for
reinstallation; the alias must not authenticate stock uOS while stock is active.
The client private key stays on the host. A separate ECDSA P-256 server key is
stored privately under `/var/lib/xpr-init/ssh/mic0` and provisioned into the
RAM-backed deployment roots. Do not share those private deployment images.

## Limitations

- RC7 is a prerelease and is not a modern production-ready Linux distribution.
- Hardware validation currently centers on the tested Xeon Phi 5110P setup.
- Physical-card host control still uses separately obtained MPSS, `micctrl`,
  and `xpr-init`.
- A standalone source-built K1OM toolkit has been technically validated, but
  its separate public release remains held for qualified review. Its binary is
  not an RC7 asset.

## Artifacts

- `xpr-os-0.1.0-rc7.tar.gz`
- `xpr-os-0.1.0-rc7-sources.tar.gz`
- `xpr-os-0.1.0-rc7.spdx.json`
- `xpr-os-0.1.0-rc7-notices.tar.gz`
- `SHA256SUMS`

Use the external `SHA256SUMS`; an archive cannot embed its own final hash.

Publication and tagging remain subject to owner authorization.
