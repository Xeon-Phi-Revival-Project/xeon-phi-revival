# First Project PID 1 Report

Public-safe report for the first project-controlled K1OM `/init` boot image.
The image and rootfs contain non-redistributable or uncertain-redistribution
runtime files and remain private.

## Objective

Boot the stock MPSS K1OM kernel with a project-owned `/init` process running as
PID 1, while preserving a verified rollback to the stock uOS.

## Current Result

Status: prepared, not activated.

The private bootable rootfs was assembled from the already passing K1OM
compatibility-demo rootfs. The image has not been selected in active MPSS
configuration and has not been booted.

## Prepared `/init`

The project `/init` does the following:

- writes immediately to `/dev/console` when available
- creates `/dev`, `/proc`, `/sys`, `/run`, `/tmp`, `/root`, and `/var/log`
- mounts `/proc`
- mounts `/sys`
- mounts `devtmpfs` on `/dev`, falling back to `tmpfs`
- creates `/dev/null`, `/dev/zero`, `/dev/console`, `/dev/urandom`, and
  `/dev/random` when required
- sets `PATH`, `HOME`, and `LD_LIBRARY_PATH`
- records `uname -a`, PID, mounts, and environment
- runs `/usr/bin/hello-knc`
- runs `/usr/bin/python3.5 /usr/share/knc-demo/python-core-pid1.py`
- starts a recovery shell and restarts it if it exits

## Image Checks

The private packed image is gzip-compressed SVR4/newc cpio.

```text
image_sha256=ad72f322cb923a7e8970730cd2cbb337c98cc7f409660e232e26667132031188
manifest_sha256=2b7985e613a882c032ea779da181867e130016e135d17e8369858c7d6a563d07
init_sha256=04690d7cdbcff315baaf12c849cf94cfa06eb2d52d4261df55c5a6b5b5927ca4
python_demo_sha256=3ad82d899fdec2fbbc835fd862ef2cc8191db60a40b3ccea40f5e99e7914ecd6
compressed_size=14679629
uncompressed_size=51078656
```

Required entries confirmed in the archive:

```text
.
dev/console
dev/null
dev/random
dev/urandom
dev/zero
init
proc
sys
usr/bin/hello-knc
usr/bin/python3.5
usr/share/knc-demo/python-core-pid1.py
```

Rootfs validation confirmed all checked ELF files are K1OM `e_machine=181` and
that runtime dependencies resolve inside the staged rootfs.

## Activation Procedure

Do not run this procedure without explicit approval.

Prepare an alternate MPSS configuration directory:

```sh
PROJECT_IMAGE="<private-build-dir>/image/k1om-project-pid1.cpio.gz"
PROJECT_CONF="<private-build-dir>/mpss-conf"
PROJECT_RAMFS="<private-build-dir>/mic0.project-pid1.image.gz"

mkdir -p "$PROJECT_CONF"
cp -a /etc/mpss/. "$PROJECT_CONF/"
sed -i "s|^Base CPIO .*|Base CPIO $PROJECT_IMAGE|" "$PROJECT_CONF/mic0.conf"
sed -i "s|^RootDevice Ramfs .*|RootDevice Ramfs $PROJECT_RAMFS|" "$PROJECT_CONF/mic0.conf"
micctrl --configdir="$PROJECT_CONF" --config mic0
```

Activate only `mic0`:

```sh
micctrl --shutdown mic0 || true
micctrl --wait mic0 || true
micctrl --configdir="$PROJECT_CONF" --updateramfs mic0
micctrl --configdir="$PROJECT_CONF" --boot mic0
micctrl --wait mic0
micctrl --status
```

Capture evidence:

```sh
dmesg | grep -iE 'mic|mpss|k1om|knc|xeon phi' | tail -160
tail -160 /var/log/mpssd
cat /proc/mic_ramoops/mic0 2>/dev/null || true
cat /proc/mic_ramoops/mic0_prev 2>/dev/null || true
timeout 20 cat /dev/ttyMIC0
ssh -o BatchMode=yes mic0 'ps -p 1 -o pid,ppid,comm,args; mount; /usr/bin/hello-knc; /usr/bin/python3.5 /usr/share/knc-demo/python-core-pid1.py' || true
```

Rollback to stock:

```sh
micctrl --shutdown mic0 || true
micctrl --wait mic0 || true
micctrl --boot mic0
micctrl --wait mic0
micctrl --status
ssh -o BatchMode=yes mic0 'uname -a; ps -p 1 -o pid,ppid,comm,args; cat /proc/cmdline'
```

## Pass Criteria

The first PID 1 boot passes only if all of these are true:

- PID 1 is project-controlled `/init`
- `/proc` is mounted
- `/sys` is mounted
- `/dev` is usable
- `hello-knc` passes
- Python core test passes
- console or shell access is available
- rollback to stock succeeds
- stock uOS boots normally afterward

Until activation and rollback are both verified, this remains a prepared image,
not a completed boot milestone.
