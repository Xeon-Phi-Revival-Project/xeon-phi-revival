# Phase 1 Bring-Up

Phase 1 proves that a real Knights Corner card can move from passive PCIe
enumeration to a repeatable native program run.

## Success Criteria

- `mic0` reaches `online` or `ready`.
- SSH to `mic0` works.
- Files can be copied to the card.
- `hello-knc` runs natively on the card.
- Hardware and experiment manifests are written.
- Public repository contents exclude proprietary Intel payloads.

## Current Result

Completed:

- 5110P passively enumerated at `0000:82:00.0`.
- MPSS 3.4.10 starts persistently after reboot.
- `mic0` reaches `online`.
- Host-side MIC network is `172.31.1.254/24`.
- Card-side target is `mic0` / `172.31.1.1`.
- SSH to `root@mic0` works.
- Medium R730 fan offset reduced the card die temperature substantially.
- `mpss-sdk-k1om-3.4.10-1.x86_64` was installed after preinstall inspection and
  dry-run validation.
- The K1OM SDK tool prefix is `k1om-mpss-linux-*`.
- A freestanding `tests/native/start-exit42.S` binary was built as `Intel K1OM`
  ELF, copied to `mic0`, executed, and returned exit code `42`.
- A dynamically linked `tests/native/hello-libc.c` binary was built as
  `Intel K1OM` ELF, requested `/lib64/ld-linux-k1om.so.2`, copied to `mic0`,
  executed, printed `hello from k1om libc`, and returned exit code `0`.
- The higher-level `tools/runners/run-hello-knc.sh` wrapper built and ran
  `tests/smoke/hello-knc.c` on `mic0`; it reported `machine=k1om`,
  `sizeof(void*)=8`, and `sizeof(long)=8`.
- Additional runtime smoke tests passed for return-code propagation, file I/O,
  `libm`, pthread creation/join, and a real inline-assembly zmm vector add.

Watch item:

- Direct `k1om-mpss-linux-as` can produce ordinary x86-64 objects for
  x86-looking assembly unless invoked with the right target options. The current
  validated path uses `k1om-mpss-linux-gcc -c` for `.S` input and then
  `k1om-mpss-linux-ld`.
- The native execution harness now checks `readelf -h` for
  `Machine: Intel K1OM`; it no longer relies on `file` output or path names.

## Next Work

1. Map the minimum runtime/sysroot pieces needed by each passing test.
2. Use these results to start the Python and Doom feasibility lanes.
3. Add larger pthread/OpenMP and vector benchmarks only after the minimum map is
   documented.
