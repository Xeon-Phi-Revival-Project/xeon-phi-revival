# RC8 Engineering Progress

## Baseline

- `v0.1.0-rc7` is frozen and published at binary SHA-256
  `6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c`.
- Development starts from `5ae45ec1670bc21e99a5da9f536119acbf864ff3`.
- The standalone toolkit remains `HOLD_HUMAN_REVIEW` for its separate KNC
  binutils source-distribution issue and is not an RC8 release component.

## Completed

- Phase 0 baseline and RC8 roadmap started.

## Current Work

- Phase 1: extend the bounded XPR SSH configuration to make `ssh mic0` route
  to the active XPR deployment, while preserving `ssh xpr-mic0` and removing
  only the managed override during recovery.
- Phase 2: add explicit runtime-state reporting and a bounded `--wait-ready`
  path that reports final-root readiness before directing users to SSH.
- Phase 3 Python diagnosis: RC7 omitted the `lib-dynload` exec-prefix
  landmark and did not build `_random`; the RC8 core profile now records both
  corrections for the next clean source build.

## Validation Notes

- Python syntax and shell syntax checks pass for the updated host helpers.
- The full host fixture is a Linux/MPSS-host fixture. Git for Windows cannot
  model its ownership/mode contract: its `install -d -m 700` step fails with
  `Permission denied` before installer logic. Run it on the supported CentOS
  host before marking Phase 1 hardware-validated.
- `EXEC_PREFIX_ROOT_CAUSE=IDENTIFIED`: no staged `lib-dynload` directory.
- `PYTHON312_EXTENSION_BASELINE=RECORDED`: `_random` was neither static nor
  installed dynamically in the minimal RC7 profile.

## RESUME STATE

- LAST_COMPLETED_PHASE=3
- CURRENT_HEAD=5ae45ec1670bc21e99a5da9f536119acbf864ff3
- HARDWARE_STATE=not touched during RC8 baseline
- CURRENT_BLOCKER=none
- NEXT_EXACT_ACTION=obtain the current source-built toolkit and CPython source on the Linux build host; run the corrected Python core build, then validate its exact package on the 5110P
- IMPORTANT_PATHS=tools/host/xpr-init,tools/host/xpr-ssh-setup.py,tools/host/test-xpr-init-install.sh
- IMPORTANT_HASHES=RC7 binary 6d69b98a20de83b67867cec21c69cf700edeb71fc8d62d92e2bcdf54ca01e89c
- DO_NOT_REPEAT=RC7 release/publication audit; do not alter frozen RC7 assets or tag
