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

## RC Init And SSH Control

The clean-root control with only the RC `/sbin/init` replacement initially
reached `online` and the project status endpoint but refused SSH. A preserved
post-connection log identified the exact cause:

```text
Early exit: Failure reading random device /dev/urandom
```

The RC init had created `/dev/console` and `/dev/null` but not `/dev/zero`,
`/dev/random`, or `/dev/urandom`. Adding the three standard character nodes
made the RC init control pass candidate online, status TCP, project SSH, RC
PID 1, hello, pthread, Dropbear public-key authentication, readiness, and
stock rollback. This is the first real-hardware execution of the project RC
init on the candidate kernel.

A static project port-22 probe also passed from the host. This separated
Dropbear's initial random-device failure from MPSS virtual networking or port
22 filtering.

## Full Root And Unpack Workload

The corrected full RC root still remained `booting` before userspace evidence.
Its nested root archive is 38,748,569 compressed bytes and expands to
127,552,616 bytes. A clean-root control padded with inert zero data to exactly
that unpacked nested-root size passed candidate online and project SSH.

Therefore the remaining full-RC boundary is not Base CPIO size, nested archive
compressed size, nested archive unpacked size, early unpack memory pressure,
or the project RC init itself. The full root uses a dynamically linked
`/bin/busybox` as `/bin/sh`; the passing clean root uses a static BusyBox.
The next isolated test should replace only full-root `/bin/busybox` with the
known-good static BusyBox and add the already-proven static status endpoint.
Do not retry the unchanged full root.

## Static BusyBox Full-Root Control

After reclaiming stale generated host artifacts, a second full-RC control
replaced the dynamic RC BusyBox with the known-good static BusyBox. The
candidate input image SHA-256 was
`b28da0f987acb1c36346df3f144e97a784afd7f6e1f7ebb348edce43484f9bb6`.
MPSS generated the final ramfs successfully, but `mic0` remained `booting`
through all 24 bounded polls. No project SSH, PID 1, or release-smoke
evidence was produced. Automatic rollback restored stock `mic0` online, stock
SSH, and the baseline configuration hash.

Replacing dynamic BusyBox alone therefore did not resolve the full-RC boot
boundary. No additional hardware test was started after this control.

## Synthetic Size Control

A 102 MiB unpacked, 67.5 MB compressed deterministic hash-padding control
based on the passing Base CPIO reached candidate `online` on poll 6. This
exceeded the failing RC Base CPIO in both unpacked and compressed size while
preserving the working root, modules, and bootstrap. Its one-shot SSH check
did not wait for Dropbear startup and is not counted as a project-SSH pass.
Rollback restored stock online, SSH, and the baseline configuration hash.

Size, transport capacity, and outer member count are therefore not sufficient
to explain the RC failure. The next control must isolate nested-root content.
See [rc-root-size-analysis.md](rc-root-size-analysis.md).
