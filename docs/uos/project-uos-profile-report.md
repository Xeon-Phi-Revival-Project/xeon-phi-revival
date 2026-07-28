# Project uOS Profile Report

Public-safe report for the first practical project-controlled uOS layer on
Intel Xeon Phi 5110P / Knights Corner.

## Status

Status: passed as a reversible stock-init second-stage profile.

This is not a true Ubuntu port and not a full replacement for stock MPSS uOS.
It is the first working project uOS profile:

- stock MPSS kernel and ramfs generation stay in control;
- stock `/sbin/init.sysvinit` remains resident PID 1;
- a project rc5 service runs after stock init reaches runlevel 5;
- project payloads live under `/opt/xeon-phi-revival`;
- logs live under `/var/log/xeon-phi-revival`;
- rollback removes the MicDir overlay and returns stock SSH.

## Reusable Tool

```text
tools/uos/run-micdir-second-stage-service-experiment.sh
```

The tool uses the MPSS MicDir overlay at `/var/mpss/mic0` and does not modify
firmware or stock base MPSS images.

## Profile Layout

The tested layout is:

```text
/opt/xeon-phi-revival/
/opt/xeon-phi-revival/bin/
/opt/xeon-phi-revival/lib/
/opt/xeon-phi-revival/python/
/opt/xeon-phi-revival/share/
/opt/xeon-phi-revival/profile.env
/var/log/xeon-phi-revival/
```

The service hook is:

```text
/etc/init.d/xeon-phi-revival-stage2
/etc/rc5.d/S78xeon-phi-revival-stage2
```

## Passing Runs

```text
marker_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-second-stage-marker-20260728-155336
marker_result=passed
marker_evidence=stage2 service ran, stock PID 1 remained init, mic0 network was up

hello_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-second-stage-hello-20260728-160051
hello_result=passed
hello_evidence=hello_rc=0, machine=k1om, sizeof(void*)=8, sizeof(long)=8

python_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-second-stage-python-20260728-160801
python_result=passed
python_evidence=hello_rc=0, python_rc=0, python stage2 demo ok, prefix=/opt/xeon-phi-revival

profile_run=/root/xeon-phi-revival-local/uos-boot-builds/micdir-second-stage-profile-20260728-161603
profile_result=passed
profile_evidence=XPR_PROFILE_KIND=stock-init-handoff-second-stage, hello_rc=0, python_rc=0
```

## Verified Profile Output

The profile phase showed:

```text
stage2_ssh_ok
pid1=init
XPR_PROFILE_KIND=stock-init-handoff-second-stage
XPR_PHASE=profile
hello_rc=0
python_rc=0
python stage2 demo ok
prefix=/opt/xeon-phi-revival
```

Rollback then showed:

```text
stock_ssh_ok_after_retry
stage2_log_absent
init
```

## Decision

The next uOS lane should use this model:

```text
project PID 1 preflight -> stock init.sysvinit -> project second-stage service
```

This keeps MPSS monitor/network behavior working while giving the project a
controlled place to boot project payloads. A fully resident custom init remains
a research target, but it should not block the Ubuntu-port preparation lane.

