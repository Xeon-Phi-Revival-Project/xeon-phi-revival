# First Candidate Kernel Boot Result

Date: 2026-08-02

One bounded RAM-only boot used an alternate MPSS configuration directory. The
active `/etc/mpss/mic0.conf` was not modified.

| Item | Result |
| --- | --- |
| Candidate kernel | `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8` |
| Candidate Base CPIO | `e458cf6d406a2336c6992853eacfa42796ebe9c34ea8a9a518c0786d56a69433` |
| MPSS image acceptance | passed: `micctrl` reported candidate `bzImage` booting |
| Online transition | failed: remained `booting` through 18 five-second polls |
| Additional candidate boots | none |
| Stock rollback | passed |
| Stock SSH after rollback | passed: `k1om`, PID 1 `init` |
| Stock config SHA-256 | `9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51` |

The experiment reached the kernel-handoff stage but produced no `online`,
network, or SSH evidence for the candidate. The earliest observed failure is
therefore after MPSS accepts the image and before the card-side readiness
handshake completes. No firmware, ROM, flash, persistent card storage, stock
kernel, or stock active MPSS configuration was modified.

The next step is read-only analysis of the private candidate boot log and
candidate-versus-stock early kernel/MPSS handoff differences. Do not repeat the
boot automatically.
