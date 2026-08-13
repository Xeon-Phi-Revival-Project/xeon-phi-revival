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
| Sysroot construction | PASS: RC6 payload runtime plus source-built XPR eglibc headers/CRT/link inputs and user-supplied SDK compiler support |
| Hello compile | PASS |
| Pthread compile | PASS |
| ELF machine | PASS: Intel K1OM |
| Interpreter | PASS: `/lib64/ld-linux-k1om.so.2` |
| Dynamic path leak | PASS: no host or SDK path in dynamic metadata |

Host-built hashes during the validation:

```text
hello    63dbed29bc67ec4d9c18d8e959d7fa181b4240617eb2e6c600c4f87427652b7a
pthread  248725441cd6ec49740ad7b11d86d9fd5751b90d8cfd2f0136320d9fc5d01b53
```

## Live 5110P Result

The final XPR root on the 5110P ran both source-built-CRT toolkit programs over
authenticated SSH:

```text
Hello from XPR-OS on K1OM
XPR toolkit pthread result=123
```

The card-side binary hashes matched the host-built values above. The final root
was reached through the normal `xpr-init` automatic handoff. No kernel, MPSS,
or runtime-image change was required.

`LIVE_TOOLKIT_OUTPUT=PASS`

## Recovery

`xpr-init --recover` passed. The stock configuration hash returned to
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`;
stock SSH returned `k1om` and PID 1 `init`.
