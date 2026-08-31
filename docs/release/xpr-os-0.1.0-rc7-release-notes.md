# XPR-OS 0.1.0-rc7 Candidate

XPR-OS 0.1.0-rc7 is an unpublished release candidate for the Intel Xeon Phi
5110P. It retains the RC6 kernel, module, networking, SSH, and recovery
foundation while adding the source-accounted CPython 3.12.13 core runtime and
the validated `xpr-init` host integration tool.

## Candidate Capabilities

- XPR `/sbin/init` as PID 1, micveth networking, and authenticated Dropbear SSH.
- Native hello, pthread, and `dlopen` regression programs.
- CPython 3.12.13 at `/usr/bin/python3.12`, with `python3` and `python` links.
- `xpr-init` install, automatic handoff, status, and exact stock recovery.

## Host Workflow

After extracting the candidate, install the host tool and follow the normal
MPSS lifecycle:

```bash
sudo install -m 755 tools/host/xpr-init /usr/local/sbin/xpr-init
sudo ln -sfn /usr/local/sbin/xpr-init /usr/sbin/xpr-init
sudo xpr-init --install
sudo micctrl --reset mic0
sudo micctrl --wait mic0
sudo micctrl --boot mic0
ssh mic0
python3 --version
```

Return to stock MPSS with `sudo xpr-init --recover`.

## Boundaries

This candidate is not published or tagged. The standalone K1OM toolkit binary
is not included while its separate KNC-binutils source-distribution review is
open. Intel MPSS remains a separately obtained prerequisite for the currently
validated physical-card host-control path.
