# XPR K1OM Toolkit Validation, 2026-08-13

## Host-only Results

Host: CentOS 7.4 with MPSS 3.4.10 and separately installed
`mpss-sdk-k1om-3.4.10`.

| Component | Evidence |
| --- | --- |
| Compiler | `k1om-mpss-linux-gcc` 4.7.0 20110509 experimental |
| Target | `k1om-mpss-linux` |
| GCC SHA-256 | `e4becb8ba03656d06751cf485f5302eadc7516c9284f28a6b8ee2d999dfc43fb` |
| readelf SHA-256 | `36c200ef5c0ebfbd59dbf8989e2b61af89466dc10fa082b0c9805ea66982e3ea` |
| Binutils | 2.22.52.20120302 |
| Sysroot construction | PASS: RC6 payload runtime plus user-supplied SDK headers/CRT/link inputs |
| Hello compile | PASS |
| Pthread compile | PASS |
| ELF machine | PASS: Intel K1OM |
| Interpreter | PASS: `/lib64/ld-linux-k1om.so.2` |
| Dynamic path leak | PASS: no host or SDK path in dynamic metadata |

Host-built hashes during the validation:

```text
hello    3ed219a5d86b38be0aaf54fcf9af5947ac58ccaf9e24a0c9b99bf2e9896f2093
pthread  48e41563e16367519c30e63d48dd061597e86346c9c30509f01c1b8e031f7e5f
```

## Live 5110P Result

The binaries transferred and executed with exit status zero on final XPR-OS,
but neither emitted its expected `puts` output. Existing project helpers built
with the source-built RC6 runtime did emit output in the same SSH session.

`LIVE_TOOLKIT_OUTPUT=FAIL`

The observed difference is the startup-object path: the toolkit used SDK CRT
objects because the project-built eglibc CRT objects are not yet a declared
public toolkit input. This is a precise sysroot-closure blocker. No kernel,
boot, MPSS, or runtime image change was attempted.

## Recovery

`xpr-init --recover` passed. The stock configuration hash returned to
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`;
stock SSH returned `k1om` and PID 1 `init`.
