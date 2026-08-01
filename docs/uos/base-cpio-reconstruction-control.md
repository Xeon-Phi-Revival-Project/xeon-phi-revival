# Base CPIO Reconstruction And Project Init Control

Date: 2026-08-01

This report records the control experiments that established a safe archive
replacement path for the MPSS Base CPIO and the first successful
project-authored early `/init` handoff.

## No-Op Reconstruction

The stock Base CPIO was parsed as a gzip-compressed SVR4/newc archive and
serialized without intentional content changes. The project tool preserves
member order, raw newc headers, names, padding, payloads, trailer placement,
and trailing archive bytes. The output is recompressed with deterministic gzip
settings; its gzip wrapper is expected to differ.

Stock input:

```text
compressed SHA-256: 44ecb9b0dbfbe9c5d880cbfe85fe53b65b000e1b66d6c1e779821f4e36923acd
decompressed SHA-256: 8012e449d92c02d33d02a1cf37826ef2c4cdb753dfa2df9c4df66c1318115755
decompressed bytes: 53,687,296
visible cpio members: 1,787
parser entries including TRAILER!!!: 1,788
trailer offset: 53,687,124
trailing bytes: 0
```

The no-op output had a different compressed SHA-256 because its gzip metadata
was normalized, but its decompressed bytes and all parsed archive metadata
matched the stock input exactly. It booted `mic0` to `online` through an
alternate MPSS configuration, and stock rollback succeeded.

This rules out unpack/repack alone, member order, raw entry metadata,
alignment, trailer placement, decompressed archive size, and deterministic
gzip recompression as the immediate cause of the previous Base CPIO failures.

## Same-Length Marker

The next control replaced one fixed-length stock `/init` payload fragment with
a project marker while preserving the complete archive layout. A marker written
under `/etc` was recovered over SSH before rollback. This proved that a
project-controlled edit to the early `/init` executes on the real card when
the archive is serialized with the new parser.

## Project Early Init Handoff

The project-authored `src/uos/xpr_early_init.sh` then replaced the Base CPIO
`/init`. It directly loads the MPSS communication modules from documented
kernel-command-line environment values, copies the initial ramfs into a tmpfs
root, installs a project `/sbin/init`, and calls `switch_root`.

The project `/sbin/init` recorded an SSH-visible marker and then execed the
preserved stock `init.sysvinit` so MPSS networking and SSH could remain on the
known-good compatibility path.

Successful image:

```text
SHA-256: 4d4f89d172eaee819edebfed89c98b2ec1bc6551a63aa478f5f988a47925b7db
```

Live evidence:

```text
boot_pass=1
ssh_marker_pass=1
rollback_pass=1
experiment SSH: uname -m=k1om
experiment PID 1 after project handoff: init.sysvinit
```

The experimental run used only a private alternate MPSS configuration. After
the run, `mic0` was online, `mpss.service` was active, stock SSH returned
`k1om`, and the original `/etc/mpss/mic0.conf` SHA-256 was restored.

## Current Boundary

The Base CPIO serialization path and project early `/init` are now proven.
The next task is a clean project-owned rootfs: it must provide the project
`/sbin/init`, shell and filesystem tools, pthread smoke, MPSS virtual
networking, and SSH without depending on stock card-side userspace after the
handoff. That rootfs must pass three consecutive boots with verified rollback
before RAM-only loader work begins.
