# MPSS SDK K1OM 3.4.10 Postinstall Report

Generated after explicit installation on the CentOS 7.4 MPSS host.

## Installed Package

- Name: `mpss-sdk-k1om`
- Version: `3.4.10`
- Release: `1`
- Architecture: `x86_64`
- Install date: `Mon 27 Jul 2026 09:22:28 PM EDT`
- License field: `various`
- Signature field: `DSA/SHA1, Thu 12 Jan 2017 04:59:02 PM EST, Key ID 0d9f9d8bd910a4f1`
- Source RPM: `mpss-sdk-k1om-3.4.10-1.src.rpm`
- Build date: `Thu 12 Jan 2017 04:59:02 PM EST`
- Build host: `sid-bld24.pdx.intel.com`
- Packager: `Intel Corporation`
- URL: `http://software.intel.com/xeonphi`
- Summary: `SDK package for MPSS on Intel MIC co-processors`
- Description: self-contained cross-toolchain for building programs for K1OM
  coprocessors running MPSS.

## Install Behavior

The installed RPM reports one postinstall script:

```sh
if [ x"$D" = "x" ]; then
	[ -x /sbin/ldconfig ] && /sbin/ldconfig
fi
```

No other installed-package scripts, triggers, or service configuration changes
were observed from `rpm -q --scripts mpss-sdk-k1om`.

## Key Paths

- Environment script:
  `/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux`
- Site config:
  `/opt/mpss/3.4.10/site-config-k1om-mpss-linux`
- Target sysroot:
  `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux`
- Host SDK sysroot:
  `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux`
- Tool directory:
  `/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux`

## Toolchain

After sourcing the environment script, `PATH` includes:

```text
/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin
/opt/mpss/3.4.10/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux
```

Observed tools:

- `k1om-mpss-linux-gcc`: GCC 4.7.0 20110509 experimental
- `k1om-mpss-linux-g++`: GCC 4.7.0 20110509 experimental
- `k1om-mpss-linux-as`: GNU Binutils 2.22.52.20120302
- `k1om-mpss-linux-ld`: GNU Binutils 2.22.52.20120302
- `k1om-mpss-linux-readelf`: GNU Binutils 2.22.52.20120302
- `k1om-mpss-linux-objdump`: GNU Binutils 2.22.52.20120302

The working prefix is `k1om-mpss-linux-`. The alternate
`x86_64-k1om-linux-` prefix was not observed on this host.

## Runtime And Startup Objects

Observed key target files:

- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/ld-linux-k1om.so.2`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/libc.so.6`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/libm.so.6`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/libpthread.so.0`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/lib64/libgcc_s.so.1`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/crt1.o`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/crti.o`
- `/opt/mpss/3.4.10/sysroots/k1om-mpss-linux/usr/lib64/crtn.o`

## Observed Tool Behavior

Direct assembler behavior:

- `k1om-mpss-linux-as -o direct-as-start-exit42.o tests/native/start-exit42.S`
  produced an ordinary x86-64 relocatable:
  `Machine: Advanced Micro Devices X86-64`.

Validated assembly path:

- `k1om-mpss-linux-gcc -c -o gcc-driver-start-exit42.o tests/native/start-exit42.S`
  produced a K1OM relocatable:
  `Machine: Intel K1OM`.

Use the GCC driver for `.S` assembly unless a specific experiment is validating
assembler target flags.

## Native Validation Results

The installed SDK built and ran the following on `mic0`:

- Freestanding `_start` test: returned `42`.
- Dynamic libc hello-world: printed `hello from k1om libc`, returned `0`.
- `hello-knc` wrapper: reported `machine=k1om`, 64-bit pointers, 64-bit longs.
- Return-code probe: returned `37`.
- File-I/O probe: printed `file io ok`, returned `0`.
- Math probe linked with `-lm`: printed `sqrt=12.0`, returned `0`.
- Pthread probe linked with `-pthread`: printed `pthread result=123`,
  returned `0`.
- ZMM vector inline-assembly smoke: disassembly showed `vbroadcastsd`,
  `vaddpd`, and `vmovapd`; printed `vector sum first=11.0 last=11.0` and
  returned `0`.

Raw reports are stored under `manifests/experiments/native-runs/`.
