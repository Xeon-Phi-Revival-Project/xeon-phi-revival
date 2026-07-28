# Project Status

## Current Verified State

- Intel Xeon Phi 5110P works under CentOS 7.4 and MPSS 3.4.10.
- `mic0` reaches `online`.
- MIC networking works.
- SSH to `mic0` works.
- Host-side development packages are installed.
- `mpss-sdk-k1om-3.4.10-1.x86_64` is installed on the CentOS host.
- The MPSS SDK K1OM environment is available at
  `/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux`.
- K1OM GCC/binutils tools are available with the `k1om-mpss-linux-*` prefix.
- Stock uOS metadata inventory is complete enough for first ABI mapping.
- Public-safe ELF metadata artifacts were generated under `artifacts/public/`.
- The dry-run native execution harness rejects ordinary x86-64 binaries before
  any card execution path.
- A freestanding K1OM `_start` executable was built, verified as
  `e_machine=181`, copied to `mic0`, executed, and returned exit code `42`.
- A dynamically linked K1OM libc hello-world was built, verified as
  `e_machine=181` with interpreter `/lib64/ld-linux-k1om.so.2`, copied to
  `mic0`, executed, printed `hello from k1om libc`, and returned exit code `0`.
- The higher-level `tools/runners/run-hello-knc.sh` wrapper built and executed
  `tests/smoke/hello-knc.c` on `mic0`; it printed `machine=k1om`,
  `sizeof(void*)=8`, `sizeof(long)=8`, and returned exit code `0`.
- Additional dynamic K1OM smoke tests ran on `mic0`:
  - `return-constant`: returned `37`
  - `file-io-smoke-test`: printed `file io ok`, returned `0`
  - `math-smoke-test`: linked with `-lm`, printed `sqrt=12.0`, returned `0`
  - `thread-smoke-test`: linked with `-pthread`, printed `pthread result=123`,
    returned `0`
  - `vector-smoke-test`: inline assembly emitted `vbroadcastsd`, `vaddpd`, and
    `vmovapd` on `zmm` registers; printed `vector sum first=11.0 last=11.0`,
    returned `0`
- Minimum runtime mapping is documented for the passing binaries: freestanding
  needs no dynamic libraries, ordinary C needs loader plus `libc`, math adds
  `libm`, pthread adds `libpthread`, and the zmm smoke adds no extra shared
  library beyond `libc`.

## Current Blocker

The first native execution milestone is no longer blocked. The narrowest next
technical blocker is using the proven C/runtime baseline to advance the first
small port feasibility lanes:

- Python feasibility from libc, `libm`, pthreads, file I/O, and dynamic loading;
- Doom feasibility from libc, file I/O, timing/input/video abstraction, and
  minimal framebuffer or terminal output strategy;
- Ubuntu 24.04 uOS feasibility from the stock MPSS boot model, beginning with a
  tiny local-only K1OM rootfs rather than a full Ubuntu boot;
- keep proprietary MPSS payloads out of the repository.

## Ubuntu 24.04 uOS Track

The Ubuntu 24.04 uOS research track has passed Level 1, completed Level 2
enough to open Level 3, and started Level 3:

- Level 0 stock uOS inventory is complete enough to begin tiny-rootfs planning.
- The track definitions now separate Ubuntu-compatible, Ubuntu-derived, and
  true Ubuntu-port targets.
- A Level 1 tiny-rootfs candidate manifest exists under `uos/ubuntu2404/`.
- A metadata-only ELF gap report was generated from
  `artifacts/public/uos-elf-inventory.csv`.
- A public-safe file-list report was derived from an ignored local stock uOS
  inventory summary; the raw log remains local-only.
- A local-only tiny K1OM rootfs was staged, validated, copied temporarily to
  `mic0`, tested through `chroot`, and removed from the card.
- Ubuntu 24.04 Noble `zlib` source package `1:1.3.dfsg-3.1ubuntu2` was rebuilt
  for K1OM as `libz.a`; a zlib smoke binary ran on `mic0`.
- Ubuntu 24.04 Noble `ncurses` source package `6.4+20240113-1ubuntu2.1` was
  rebuilt for K1OM; a simple `curses_version()` smoke binary ran on `mic0`.
- `sqlite3` and `libffi` source packages were verified and patched but blocked
  on specific host build-tool gaps.
- CPython 3.5.10 was cross-built for K1OM and ran a `print(42)` smoke script on
  `mic0` with a temporary `PYTHONHOME`.
- A fuller K1OM demo rootfs now runs `hello-knc`, Ubuntu-source `zlib`,
  Ubuntu-source `ncurses`, CPython core imports, `threading`, `math`, and `zlib`
  from inside a reversible `mic0` chroot.
- The true Ubuntu architecture-port lane has started with proposed `k1om`
  architecture metadata, dpkg metadata fragments, a local archive skeleton, and
  a source-package status matrix.

The Ubuntu package-expansion lane is paused while the uOS boot lane advances.
The current narrowest dependency is proving a tiny native K1OM PID 1 handoff
with an observable marker before adding Python or broader userland to the boot
image.

## Project PID 1 uOS Boot Track

- The exact stock MPSS boot inputs were mapped read-only.
- Stock kernel, System.map, base initramfs, generated card ramfs, and MPSS
  configuration hashes are documented.
- The active stock root image format is gzip-compressed SVR4/newc cpio.
- The active stock kernel command line is documented.
- A private project-controlled K1OM rootfs was assembled from the passing
  compatibility-demo rootfs.
- The private rootfs contains a project-owned `/init` that mounts `/proc`,
  `/sys`, prepares `/dev`, logs to console, runs `hello-knc`, runs the Python
  core demo, and drops into a persistent recovery shell.
- The rootfs validator confirmed checked ELF files are K1OM `e_machine=181`
  and required runtime libraries resolve inside the rootfs.
- A private gzip/newc cpio image was packed and hashed.
- Activation was attempted through direct `micctrl --configdir`, service
  environment selection, temporary `/etc/sysconfig/mpss.conf` selection,
  dynamic `Ramfs`, direct `StaticRamFS`, and foreground
  `mpssd -l -d <alternate-config>`.
- Early `micctrl` and service-selector attempts failed before project PID 1,
  reporting `Boot aborted - no configuation file present` and
  `Boot aborted - no configuation file present: File exists`.
- Foreground `mpssd -l -d <alternate-config>` successfully selected alternate
  `StaticRamFS` images without overwriting stock MPSS files.
- A copied stock `StaticRamFS` image booted to `online`.
- An unpacked/repacked stock `StaticRamFS` image booted to `online`, proving the
  public packer shape can boot stock content.
- Project PID 1 variants were selected by MPSS but remained in `booting` until
  timeout or `boot failed`; no project `/init` or ELF PID 1 marker was observed.
- The project `/init` banner was not observed.
- A reversible MPSS MicDir overlay boot proof succeeded: stock dynamic MPSS
  boot was preserved, a project `/etc/issue` banner and SysV rc5 boot snippet
  were injected through `/var/mpss/mic0`, `mic0` reached `online`, SSH worked,
  `/project-boot-snippet.txt` was observed on the card, and rollback removed
  the marker.
- A persistent shell-as-`/sbin/init` MicDir overlay reached MPSS `online` but
  did not bring SSH up in six bounded checks; rollback required a normal
  `micctrl --reset` to return stock SSH.
- A tiny project `/sbin/init` handoff overlay succeeded: the custom init ran as
  PID 1, wrote `/project-pid1-handoff-marker.txt` with `project_pid=1`, logged
  its handoff, execed stock `/sbin/init.sysvinit`, and SSH verified the marker
  after the stock runlevel-5 boot completed.
- Stock rollback succeeded: `/etc/sysconfig/mpss.conf` was restored absent,
  stock MPSS service booted `mic0` to `online`, SSH worked, and PID 1 was stock
  `init`.

## Current Public Artifacts

- `artifacts/public/uos-elf-inventory.csv`
- `artifacts/public/uos-dependency-graph.json`
- `docs/uos/stock-uos-elf-inventory.md`
- `docs/uos/stock-uos-library-dependencies.md`
- `docs/uos/ubuntu-24.04-uos-research.md`
- `docs/uos/ubuntu-24.04-level1-gap-report.md`
- `docs/uos/ubuntu-24.04-level1-filelist-report.md`
- `docs/uos/ubuntu-24.04-level1-runtime-report.md`
- `docs/uos/ubuntu-24.04-level2-zlib-report.md`
- `docs/uos/ubuntu-24.04-level2-completion-report.md`
- `docs/uos/ubuntu-24.04-level3-python-report.md`
- `docs/uos/k1om-compat-demo-report.md`
- `docs/uos/ubuntu-24.04-python-userland-report.md`
- `docs/uos/pid1-boot-path.md`
- `docs/uos/stock-rollback-baseline.md`
- `docs/uos/first-project-pid1-report.md`
- `docs/ubuntu-port/k1om-architecture-port-start.md`
- `docs/toolchain/minimum-k1om-runtime.md`
- `docs/toolchain/k1om-package-requirements.md`
- `docs/toolchain/mpss-sdk-k1om-3.4.10-preinstall-report.md`
- `docs/toolchain/mpss-sdk-k1om-3.4.10-postinstall-report.md`
- `docs/architecture/observed-k1om-elf-abi.md`
- `docs/toolchain/open-k1om-toolchain-feasibility.md`
- `docs/handbook/glossary.md`
- `manifests/experiments/native-runs/20260727-212630-start-exit42.yml`
- `manifests/experiments/native-runs/20260727-212700-hello-libc.yml`
- `manifests/experiments/native-runs/20260727-212720-hello-libc.yml`
- `manifests/experiments/native-runs/20260727-213155-hello-knc.yml`
- `manifests/experiments/native-runs/20260727-213424-return-constant.yml`
- `manifests/experiments/native-runs/20260727-213441-file-io-smoke-test.yml`
- `manifests/experiments/native-runs/20260727-213454-math-smoke-test.yml`
- `manifests/experiments/native-runs/20260727-213506-thread-smoke-test.yml`
- `manifests/experiments/native-runs/20260727-214058-vector-smoke-test.yml`
- `manifests/experiments/first-project-pid1.yml`

## Safest Next Technical Action

Turn the successful PID 1 handoff into a reusable, generated experiment script
with bounded SSH polling and automatic stock recovery. Keep the resident custom
init lane separate: the next resident-init attempt needs to preserve the stock
MPSS monitor/network startup semantics or move userland tests into a second
stage after stock init brings the card online.
