# Candidate Kernel Repeatability Gate

Date: 2026-08-02

The independent `linux-2.6.38+mpss3.5.1` compatibility reconstruction passed
three consecutive bounded boots using the same candidate kernel, rebuilt
candidate modules, and corrected minimal project-root Base CPIO.

| Item | Value |
| --- | --- |
| Candidate kernel SHA-256 | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| Minimal Base CPIO SHA-256 | `7ce52df3fd115984f3ec191abb4a1fb2b336f477797103806b79064c011afe0e` |
| Compressed / unpacked bytes | `29,313,792` / `68,657,588` |
| Member count | `1,803` |
| Stock config SHA-256 | `9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51` |

## Valid Boots

1. Project-root verification: candidate `online` on poll 4, project Dropbear
   authenticated, and `/run/xpr-os-init` recorded project `/sbin/init` PID 1,
   `k1om`, `XPR_HELLO_OK`, `XPR_PTHREAD_OK`, and readiness notification.
2. Repeat `20260802-044250`: candidate `online` on poll 4, project SSH
   succeeded, and stock rollback passed.
3. Repeat `20260802-044956`: candidate `online` on poll 4, project SSH
   succeeded, and stock rollback passed.

The first earlier repeat attempt is intentionally excluded: it checked project
SSH before Dropbear had completed startup. It did not change the image or
establish a regression, but it is not counted as evidence.

After every valid run the alternate MPSS configuration was removed, stock
`mic0` returned to `online`, stock SSH reported `k1om`, and the original
configuration hash matched exactly. The final stock check reported normal stock
PID 1 `systemd`. No firmware, flash, ROM,
persistent card storage, stock kernel, or active stock configuration was
modified.

This establishes repeatability for the small project-root path only. It does
not validate the larger release-candidate root archive or its broader package
smoke suite.
