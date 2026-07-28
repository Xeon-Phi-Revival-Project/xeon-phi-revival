# From Card To Code

This is the practical path from "I have a Xeon Phi card" to "I can compile and
run a native K1OM program." It is written around the project's verified 5110P
baseline, but the checks are useful for other Knights Corner cards too.

## 0. Know The Boundary

This project does not provide MPSS, Intel firmware, Intel compilers, extracted
uOS images, or Intel runtime libraries. You need to obtain those separately
under their own terms.

The current verified baseline is:

- Intel Xeon Phi 5110P / Knights Corner
- Dell PowerEdge R730
- CentOS 7.4-era host
- MPSS 3.4.10
- `mpss-sdk-k1om-3.4.10-1.x86_64`
- `k1om-mpss-linux-*` compiler and binutils prefix

## 1. Install The Card Safely

1. Use a server with enough PCIe power, slot clearance, and BIOS support.
2. Provide serious front-to-back airflow. Most 5110P cards are passively cooled.
3. Confirm the card appears in firmware/iDRAC/BIOS inventory.
4. Boot the host OS and identify the card:

```bash
lspci -nn | grep -i phi
```

For the verified 5110P, the observed PCI device ID is `8086:2250`.

## 2. Prepare A Compatible Host

1. Use an MPSS-era Linux distribution and kernel. The verified host is CentOS
   7.4 with kernel `3.10.0-693.el7.x86_64`.
2. Install MPSS packages that match the host kernel/module situation.
3. Do not flash firmware as a first troubleshooting step.
4. Start MPSS and check card state:

```bash
systemctl status mpss
micctrl --status
micinfo
```

The first target is:

```text
mic0: online
```

## 3. Get SSH Working

The MPSS virtual network normally exposes:

```text
host side: 172.31.1.254
card side: 172.31.1.1
target: mic0
```

Check SSH from the host:

```bash
ssh mic0 uname -a
ssh mic0 cat /proc/cpuinfo
```

Keep SSH attempts bounded while the card is rebooting or resetting. Repeated
unbounded retries make troubleshooting harder.

## 4. Install Or Expose The K1OM SDK

Inspect the SDK package before installing it. The project has a public-safe
preinstall report for `mpss-sdk-k1om-3.4.10-1.x86_64`.

After install, load the environment:

```bash
source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
```

Then check tools:

```bash
command -v k1om-mpss-linux-gcc
command -v k1om-mpss-linux-readelf
k1om-mpss-linux-gcc --version
```

## 5. Build A Native Hello Program

Use the project smoke test:

```bash
tools/runners/run-hello-knc.sh
```

The expected card-side output includes:

```text
machine=k1om
sizeof(void*)=8
sizeof(long)=8
```

Every native binary should be checked before running:

```bash
k1om-mpss-linux-readelf -h ./your-binary | grep Machine
```

The expected machine is:

```text
Intel K1OM
```

## 6. Move Into Runtime Tests

After hello works, run narrow tests before big ports:

1. Freestanding `_start` exit-code test.
2. Dynamically linked libc hello.
3. File I/O smoke.
4. `libm` smoke.
5. pthread smoke.
6. Vector instruction smoke.
7. Python/zlib/ncurses userland smoke.

Do not jump straight to a large port until the small tests show which runtime
pieces are present.

## 7. Try The Experimental Ubuntu-Style Profile

The current project lane builds local `Architecture: k1om` packages, indexes
them into a Noble-style archive, simulates a dpkg install, installs them into
MPSS MicDir staging, boots `mic0`, runs smoke checks, and rolls back.

The current private profile is intentionally not committed because it contains
locally supplied K1OM payloads. The public tools are:

```text
tools/ubuntu-port/build-k1om-bootstrap-packages.sh
tools/ubuntu-port/index-k1om-local-archive.sh
tools/ubuntu-port/audit-k1om-package-set.sh
tools/ubuntu-port/simulate-k1om-package-install.sh
tools/ubuntu-port/run-k1om-bootstrap-package-set-experiment.sh
```

Current verified conveniences inside the profile:

```bash
ls
python3
python
cat /var/lib/dpkg/status
```

The Python wrappers currently default to no-site startup because normal
`site.py` startup still needs `_sysconfigdata`.

## 8. Keep Rollback Boring

Every live uOS or MicDir experiment should have:

- A stock config hash.
- A backup of changed MicDir paths.
- A generated rollback script.
- A post-rollback SSH check.
- A check that project markers are absent from stock.

If the card gets stuck at `ready`, `booting`, or `resetting`, stop and collect
state before changing firmware, boot images, or kernel modules.
