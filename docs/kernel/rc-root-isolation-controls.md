# Release-Candidate Root Isolation Controls

Date: 2026-08-02

These two bounded RAM-only controls isolate the first failed full
release-candidate (RC) root integration. Both used the independent K1OM
candidate kernel and rebuilt candidate module set. Neither changed firmware,
flash, persistent card storage, the stock kernel, or the active MPSS
configuration. Each automatically restored stock MPSS afterward.

## Control 1: Outer Base CPIO Size

The known-good small project root was retained. An inert,
non-executed `xpr-size-control.bin` member was added to the outer Base CPIO so
that its unpacked size exactly matched the failed RC Base CPIO.

| Item | Value |
| --- | --- |
| Image SHA-256 | `52632e905ff2c1fd9b150578b6a2339e817b520048be2de9e9ea7a68a0843405` |
| Compressed bytes | `62,112,401` |
| Unpacked bytes | `101,601,908` |
| Members | `1,804` |
| Candidate result | `online` |
| Rollback | stock `mic0` online and stock configuration hash restored |

This eliminates outer Base CPIO size and placement as the primary explanation.

## Control 2: Nested Root Archive Size And Unpack

The known-good clean project root was retained, including its project PID 1,
Dropbear, and smoke programs. An inert member was inserted inside that root
archive until it matched the failed RC root archive's compressed size within
three gzip-framing bytes:

```text
RC nested root target: 38,748,569 bytes
control nested root:   38,748,572 bytes
```

The final outer archive again had exactly `101,601,908` unpacked bytes.

| Item | Value |
| --- | --- |
| Image SHA-256 | `edb75131bebf10f9df3d93214c1c8a727608d575ff0e9bac71a8a57a827f8fe5` |
| Compressed bytes | `62,267,477` |
| Unpacked bytes | `101,601,908` |
| Members | `1,803` |
| Candidate result | `online` |
| Project SSH | passed |
| Project markers | PID 1, `k1om`, hello, pthread, Dropbear, readiness |
| Rollback | stock `mic0` online, stock SSH passed, baseline config hash restored |

This proves the project early init can decompress and unpack a root archive at
the RC workload size, then `switch_root` into a working project userspace.

## Boundary And Next Control

The failed RC image is therefore not blocked by CPIO size, placement, or the
early root archive unpack. The failure is after the RC root becomes active and
before it completes the MPSS readiness path. The likely remaining boundary is
RC `/sbin/init` startup or an RC-specific runtime dependency. This is an
inference from the controls, not a direct console trace.

The next single control should use the known-good clean root and replace only
its `/sbin/init` with the project RC init script, retaining the clean root's
known-good static shell, Dropbear, and smoke binaries. That isolates the RC
init script from the broader RC root contents. Do not retry the full RC root
unchanged.
