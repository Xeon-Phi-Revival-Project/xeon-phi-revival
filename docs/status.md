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
- A reusable MicDir PID 1 handoff runner now exists at
  `tools/uos/run-micdir-pid1-handoff-experiment.sh`.
- The reusable runner completed the phased handoff ladder: marker-only PID 1
  handoff, tiny early-boot action, `hello-knc` from PID 1, and core CPython
  3.5 from PID 1 all passed with stock rollback verified after each phase.
- Python expansion notes: ordinary `site.py` startup still needs
  `_sysconfigdata`, and the earlier generated demo's `platform` import pulled
  in `_posixsubprocess`; the passing PID 1 Python test is intentionally
  core-only and runs with `python3.5 -S`.
- A reusable second-stage service runner now exists at
  `tools/uos/run-micdir-second-stage-service-experiment.sh`.
- The second-stage project uOS profile passed through stock init: marker,
  `hello-knc`, Python, and full profile phases all ran from
  `/opt/xeon-phi-revival` after stock runlevel-5 startup, with stock rollback
  verified after each phase.
- The project is ready to start true Ubuntu K1OM architecture-port design, but
  should not call the current profile a true Ubuntu port.
- The first package-built K1OM bootstrap profile passed: a local
  `xeon-phi-revival-profile_0.1.0_k1om.deb` was built, indexed into an unsigned
  Noble `binary-k1om` archive, installed into MicDir staging, booted on `mic0`,
  ran `hello-knc` and Python, and rolled back to stock.
- The first multi-package K1OM bootstrap archive passed and has since expanded
  to thirty-four packages. It now includes project dpkg/APT shims, hello/Python
  smoke packages, split libc/libgcc/libm/pthread/dl/rt/util runtime packages,
  split zlib/ncurses/readline/OpenSSL-1.0 runtime packages, BusyBox-backed
  command entrypoints, `pcietool`, runtime smoke packages, packaged CPython
  3.12.13 runtime and smoke packages, and the SysV second-stage service. See
  `docs/ubuntu-port/k1om-bootstrap-package-set-report.md` for the exact list.
- The K1OM package-set audit now passes before live install. It verifies the
  local archive advertises `Architectures: k1om`, every package declares
  `Architecture: k1om`, `Packages` filenames and SHA-256 values match the
  `.deb` files, declared dependencies are present in the local archive, and no
  non-directory payload path is owned by more than one package.
- A non-executing K1OM package install simulator now passes before live install.
  It resolves the package dependency order, extracts payloads into a staged
  rootfs, generates `/var/lib/dpkg/status`, writes per-package `.list` files
  under `/var/lib/dpkg/info`, and verifies required bootstrap paths exist before
  the MicDir boot test begins.
- K1OM bootstrap package construction is now deterministic under the runner:
  two builds with `SOURCE_DATE_EPOCH=1704067200` produced identical package
  names and SHA-256 values before the live boot test.
- The K1OM bootstrap archive is now more Ubuntu/APT-shaped: package controls
  include `Source`, sections, optional `Depends`, `md5sums`, and `conffiles`;
  the archive emits both `Packages` and deterministic `Packages.gz`; and
  `Release` includes `MD5Sum`, `SHA1`, and `SHA256` blocks for both indexes.
- A harmless host-side APT sandbox test passed against the local K1OM archive.
  With `APT::Architecture=k1om`, `apt-get update` parsed the local
  `noble/main/binary-k1om` file repository and `apt-cache show` reported
  `base-files-k1om` as `Architecture: k1om`. The current archive contains
  thirty packages after the runtime-library split.
- The deterministic package set expanded from five to seven packages by adding
  `zlib-smoke-k1om` and `ncurses-smoke-k1om`. Both package-installed payloads
  ran on `mic0` through the second-stage service: `zlib_rc=0` reported
  `zlib version=1.3`, and `ncurses_rc=0` reported
  `ncurses 6.4.20240113`.
- The package set then expanded to eight packages by splitting
  `libtinfo5-k1om` out as a reusable runtime package. `ncurses-smoke-k1om`
  now depends on `libtinfo5-k1om`, and the live `mic0` smoke still passed.
- The package set then expanded to eleven packages by splitting the old
  one-piece Python payload into `python3.5-minimal-k1om`,
  `python3.5-stdlib-k1om`, `python3.5-lib-dynload-k1om`, and
  `python3.5-smoke-k1om`. The live `mic0` smoke still passed, the simulated
  dpkg database was copied into the MicDir overlay, and `/var/lib/dpkg/status`
  reported eleven installed package records on-card.
- The package set then expanded to twelve packages by adding
  `xpr-shell-compat`. It installs `/usr/bin/python3`, `/usr/bin/python`, an
  `/etc/profile.d/xeon-phi-revival.sh` profile fragment, and convenience
  wrappers under `/opt/xeon-phi-revival/bin`. `ls` resolves through the stock
  BusyBox `/bin/ls`, while `python3 -c 1` and `python -c 1` now return `0` by
  defaulting the wrappers to the validated no-site startup mode.
- The package set then expanded to fourteen packages by adding
  `xpr-busybox-compat` and `xpr-pci-tools`. The BusyBox compatibility package
  exposes common command entrypoints such as `cat`, `grep`, `sed`, `awk`, and
  `find` under `/opt/xeon-phi-revival/bin`. The PCI tools package installs
  `/usr/bin/pcietool`, which ran successfully on `mic0`; the current card uOS
  exposed no PCI device lines through that helper during this run.
- The package set then expanded to twenty-four packages by adding
  `dpkg-k1om`, `apt-k1om`, reusable project libc-stack packages
  (`libc6-k1om`, `libgcc1-k1om`, `libm6-k1om`, `libpthread0-k1om`,
  `libdl2-k1om`, `librt1-k1om`, and `libutil1-k1om`), and
  `libc-stack-smoke-k1om`. The live run verified `/usr/bin/dpkg`,
  `/usr/bin/apt-get`, and `/usr/bin/apt-cache`, verified
  `/var/lib/dpkg/status`, ran `apt-get update`, used `apt-cache show` to
  report `Architecture: k1om`, and ran `apt-get install --reinstall
  xpr-pci-tools` from the on-card local file repository. The libc stack smoke
  used the packaged loader and library path to run `hello-knc` and the Python
  core test against `/opt/xeon-phi-revival/lib64`.
- The package set then expanded to thirty packages by splitting additional
  runtime libraries into standalone packages: `zlib1g-k1om`,
  `libncurses5-k1om`, `libreadline6-k1om`, `libcrypto1.0.0-k1om`,
  `libssl1.0.0-k1om`, and `xpr-runtime-libs-smoke`. The live run
  `k1om-bootstrap-package-set-20260729-022039` verified `package_count=30`,
  `apt_update_rc=0`, `apt_install_rc=0`, `apt_runtime_install_rc=0`,
  `runtime_libs_rc=0`, and stock rollback. The `dpkg-k1om` shim now checks
  dependencies before first install, checks file ownership conflicts for new
  package installs, and permits reinstall of already-installed packages.
- The package set then expanded to thirty-four packages by adding an
  Ubuntu-shaped CPython 3.12.13 runtime package group:
  `python3.12-minimal-k1om`, `python3.12-stdlib-k1om`,
  `python3.12-sysconfig-k1om`, and `python3.12-smoke-k1om`. The live run
  `k1om-bootstrap-package-set-20260729-041555` verified `package_count=34`,
  deterministic package hashes, archive audit, simulated install, `/usr/bin/python3.12`,
  `python312_version_rc=0`, direct packaged smoke `python312_direct_rc=0`,
  second-stage service `python312_rc=0`, and
  `apt-get install --reinstall python3.12-smoke-k1om` with
  `apt_python312_install_rc=0`. The smoke covered zlib, hash modules, XML,
  pickle, CSV, asyncio import, sysconfig, threading, decimal, socket, pathlib,
  and other core modules. Stock rollback was verified afterward with
  `python312_absent`, `python312_bin_absent`, `python312_smoke_absent`,
  `dpkg_status_absent`, `apt_get_absent`, `dpkg_absent`, and stock `init`.
- CPython 3.12.13 now has a rollback-verified expanded runtime smoke on
  `mic0`. The K1OM cross build still requires `--disable-ipv6`, `-std=gnu1x`
  instead of `-std=c11`, `static_assert` and `_Alignof` compatibility shims,
  and a K1OM-specific `_Py_atomic_thread_fence` patch replacing unsupported
  `mfence` with `__sync_synchronize()`. The latest private runtime build
  statically enabled core modules and accelerators including `math`, `_struct`,
  `_json`, `_decimal`, `_socket`, `_pickle`, `_csv`, `_random`, `_queue`,
  `pyexpat`, `_elementtree`, `hashlib` backing modules, and `zlib`. The live
  run `python312-static-expanded-sysconfig-overlay-20260729-031953` booted
  `mic0`, ran Python 3.12.13 from `/usr/bin/python3.12`, imported and exercised
  the expanded module set, reported `pysmoke_rc=0` and `pyimports_rc=0`, then
  restored stock uOS and verified the Python 3.12 overlay paths were absent.
  This work has now been converted into local K1OM packages in the
  thirty-four-package archive, but it is still a bootstrap distribution rather
  than an official Ubuntu Python build.
- The latest rollback-verified package-set run completed at
  `/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-041555`.
  Stock rollback succeeded afterward: SSH worked, the project profile,
  `/var/lib/dpkg/status`, and the Python 3.12 staging paths were absent, and
  PID 1 was stock `init`.

## Current Public Artifacts

- `README.md`
- `docs/getting-started-card-to-code.md`
- `docs/source-index.md`
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
- `docs/uos/python-3.12-k1om-probe-report.md`
- `docs/uos/pid1-boot-path.md`
- `docs/uos/stock-rollback-baseline.md`
- `docs/uos/first-project-pid1-report.md`
- `docs/uos/project-uos-profile-report.md`
- `docs/ubuntu-port/k1om-architecture-port-start.md`
- `docs/ubuntu-port/true-ubuntu-port-readiness.md`
- `docs/ubuntu-port/k1om-bootstrap-package-report.md`
- `docs/ubuntu-port/k1om-bootstrap-package-set-report.md`
- `docs/ubuntu-port/k1om-apt-sandbox-report.md`
- `docs/toolchain/minimum-k1om-runtime.md`
- `docs/toolchain/k1om-package-requirements.md`
- `docs/toolchain/mpss-sdk-k1om-3.4.10-preinstall-report.md`
- `docs/toolchain/mpss-sdk-k1om-3.4.10-postinstall-report.md`
- `docs/architecture/observed-k1om-elf-abi.md`
- `docs/toolchain/open-k1om-toolchain-feasibility.md`
- `docs/handbook/glossary.md`
- `tools/uos/run-micdir-pid1-handoff-experiment.sh`
- `tools/uos/run-micdir-second-stage-service-experiment.sh`
- `tools/ubuntu-port/check-k1om-package-determinism.sh`
- `tools/ubuntu-port/audit-k1om-package-set.sh`
- `tools/ubuntu-port/simulate-k1om-package-install.sh`
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
- `manifests/experiments/second-stage-uos-profile.yml`
- `manifests/experiments/k1om-profile-package-bootstrap.yml`
- `manifests/experiments/k1om-bootstrap-package-set.yml`
- `manifests/experiments/k1om-apt-sandbox.yml`
- `manifests/experiments/python-3.12-k1om-probe.yml`
- `manifests/experiments/python-3.12-k1om-expanded-runtime.yml`

## Safest Next Technical Action

Port the missing Python 3.12 optional-module dependencies into the K1OM package
lane: OpenSSL development headers for `_ssl`/OpenSSL-backed `_hashlib`,
readline headers, sqlite, libffi for `_ctypes`, bz2, lzma, and the separate
`_curses` build-system issue. Continue avoiding committed proprietary or
uncertain-redistribution payloads.
