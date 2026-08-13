# xpr-init RSA Validation, 2026-08-12

Tested hardware: Intel Xeon Phi 5110P, CentOS 7.4 host, Intel MPSS 3.4.10,
`mic0`. The test began from the verified stock configuration hash
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.

## Host Fixtures

`tools/host/test-xpr-init-install.sh` passed. It covers explicit, zero, one,
multiple, reusable, and incomplete key states; install/reinstall/recovery;
status output; and the payload-stdin regression check.

## Live Generated-Key Flow

A fresh disposable invoking user with an empty `.ssh` directory ran
`xpr-init --install`. The helper generated:

```text
/home/xprkeylive/.ssh/xpr_os_rsa
/home/xprkeylive/.ssh/xpr_os_rsa.pub
```

The generated `.ssh` directory was owned by the invoking user with mode `700`;
the private key was mode `600`; and the public key was mode `644`. Neither key
appeared under the installed XPR artifacts. The private key was used only by
the host to authenticate to the deployment.

The documented `micctrl --reset`, `--wait`, and `--boot` sequence passed.
Automatic handoff reached final XPR PID 1, micveth, authenticated SSH with the
generated key, `xpr-hello`, `xpr-pthread-smoke`, and `xpr-dlopen-smoke`.

`xpr-init --recover` restored the exact stock configuration hash. `mic0`
returned online; stock SSH reported `k1om` and PID 1 `init`.

## Cold-Reboot Status

PASS. After one normal host reboot, the saved XPR state, stock backup, deployed
files, XPR MPSS configuration, and enabled handoff unit all persisted. No
reinstall was run. `mic0` appeared online with the installed XPR kernel after
host startup; the documented reset/wait/boot sequence was then run and the
persisted handoff service again reached final PID 1, micveth, generated-key
SSH, and all three smoke programs. Recovery again restored the exact stock
configuration hash and stock SSH (`k1om`, PID 1 `init`).
