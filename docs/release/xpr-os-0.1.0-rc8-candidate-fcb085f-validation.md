# XPR-OS 0.1.0-rc8 Candidate fcb085f Validation

This record covers the unpublished candidate assembled from
`fcb085fc77e2da8939e088c2d1eda6d7090500bd`. It is distinct from earlier RC8
checkpoints and is the exact artifact tested below.

## Exact Artifacts

| Artifact | SHA-256 |
| --- | --- |
| `xpr-os-0.1.0-rc8.tar.gz` | `20d046d61c4e0022a4ac8fabb56b09e0afb4f8404f68359ae06f323a02405eb3` |
| `xpr-os-0.1.0-rc8-sources.tar.gz` | `18faa35110aec289c28d4073a27fec67eb9377c905ac0546d29c42f1e5d963fc` |

The candidate was assembled from fresh source-built BusyBox, Dropbear,
eglibc, libgcc, and the source-accounted Python 3.12.13 core. The Base CPIO
uses the validated `2.6.38.8+mpss3.5.1` module directory and its builder
verified each module vermagic before packaging. Static staging completed the
existing archive, source-policy, SPDX, license, generic-key-free payload, and
prebuilt-image checks.

## 5110P Validation

The exact binary archive was deployed through `xpr-init` on the established
CentOS 7.4 / MPSS 3.4.10 host to `mic0` (Intel Xeon Phi 5110P).

| Check | Result |
| --- | --- |
| Automatic bootstrap-to-final-root handoff | PASS |
| Final XPR `/sbin/init` as PID 1 | PASS |
| micveth networking | PASS |
| Authenticated Dropbear SSH | PASS |
| `xpr-hello` | PASS |
| `xpr-pthread-smoke` | PASS |
| `xpr-dlopen-smoke` | PASS |
| `python3 --version` | PASS, Python 3.12.13 |
| Python core smoke | PASS, including `threading`, `math`, and `platform.machine() == "k1om"` |

The tested card-side executable hashes were:

```text
5bbd8fa60e7dadcbe35b11c18b7f54bca982fd37ef9b8bb43a13d4cc7bf5aa5e  /usr/bin/python3.12
0f1f4841031350eae3bec6cf18517a2ba786d8a7897a62fbdf928670cd162582  /usr/bin/xpr-hello
3c66d2f0fa462fabfb4ec1f6bcaa3b0f67c3d967547b95bb7e87da3212c99df3  /usr/bin/xpr-pthread-smoke
9193fa26b75ad8de4bfacbf4ebedec64feaebd6982385c2cb78c64ad46a712cc  /usr/bin/xpr-dlopen-smoke
```

## Recovery

`xpr-init --recover` completed and restored the exact stock MPSS
configuration hash:

```text
9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

After recovery, `mic0` was online with the stock image; stock SSH reported
`k1om` and PID 1 `init`.

## Status

`XPR_OS_RC8_CANDIDATE=TECHNICALLY_PASS`

`TOOLKIT_RC8_INCLUSION=HOLD_HUMAN_REVIEW`

No RC8 tag, public release, or asset upload was created. Remaining work before
publication is the release-engineering review of the exact candidate and its
sidecar metadata, not another runtime reconstruction pass.
