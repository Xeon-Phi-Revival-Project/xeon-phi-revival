# XPR-OS 0.1.0-rc4 Validation

Status: `AUTOMATED_CHECKS_PASS_HUMAN_LEGAL_REVIEW_PENDING`  
Date: 2026-08-10  
Tested hardware: Intel Xeon Phi 5110P on a Dell PowerEdge R730, CentOS
7.4.1708 host, MPSS 3.4.10.

## Frozen Artifacts

| Artifact | SHA-256 |
| --- | --- |
| K1OM kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| System.map | `631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6` |
| Outer Base CPIO | `bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779` |
| Generic public payload | `5866743b0899e91fda0879aca9c449378b81a541ab78c5e7247fb6f8e7baeced` |
| RC4 binary archive | `b92986789313c64fb2d8d4d5b80ebec508e0222d70c406b00be1cda3c749828b` |
| RC4 source archive | `361eb20033b0e7b3692982ffeb0b12330c5914e72c098aa48f23bcebd969efdb` |
| RC4 checksum manifest | `4c0bb4bff3f1a4f27989cffdeb6ef574723293347f73212082d947c05ee54831` |

Two independently staged RC4 builds produced byte-identical binary archives,
source archives, and checksum manifests. The source-compliance, prebuilt-image,
SPDX 2.3, license-bundle, generic-payload, archive checksum, and clean-extract
verification gates passed for both builds.

## Hardware Repeatability

The generic payload was not modified. A local deployment copy was created only
to install the host operator's public key; neither that copy nor any private key
is part of the artifact set above.

| Boot | Public final root | PID 1 | Network and SSH | Probes | Stock rollback |
| --- | --- | --- | --- | --- | --- |
| 1 | pass | pass | pass | hello, pthread, dlopen pass | pass |
| 2 | pass | pass | pass | hello, pthread, dlopen pass | pass |
| 3 | pass | pass | pass | hello, pthread, dlopen pass | pass |

Each boot captured the project handoff and final-root markers, including
`XPR_SWITCH_ROOT_EXEC`, `XPR_RC_INIT_ENTERED`,
`XPR_RC_ROOT_SBIN_INIT_PID1`, `XPR_NETWORK_READY`, `XPR_SSH_READY`, and
`XPR_SMOKE_PASS`. The final root reported `ID=xpr-uos`, `uname -m` reported
`k1om`, and the SSH server authenticated the provisioned operator public key.

After every run, the host restored stock `mic0` online state, stock SSH, stock
`init`, and the stock configuration SHA-256
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.

## Release Boundary

This report closes RC4's automated technical gates. It does not authorize
publication. The next required action is qualified human legal review of the
frozen binary/source archives and the corresponding-source/provenance material
for the kernel and five card-side modules.
