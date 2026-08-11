# Project Status

## Current Status - Active Development

Development is active. On August 10, 2026, the source-accounted public-clean
XPR-OS stack passed three identical final-root hardware boots with SSH, native
smokes, and verified rollback. The corrected public source/BYO-MPSS release is
RC2. The RC4 binary/source review bundle now passes its two-build
reproducibility, archive, hardware, provenance, and rollback gates. Public
attachment remains blocked only by qualified human review of the five module
grants and the frozen RC4 archives.

The corrected source/metadata/BYO-MPSS prerelease is published at
<https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/releases/tag/v0.1.0-rc2>.
It intentionally contains no private boot binaries or Intel/MPSS payloads.

Current public-clean hardware artifact state:

- Candidate compatibility kernel:
  `d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8`
- Outer Base CPIO:
  `bdb19076b7ba8dd6619b3bce4696bdb942b768fb9f11dc0a60c1533f7ff35779`
- Public final-root payload:
  `5866743b0899e91fda0879aca9c449378b81a541ab78c5e7247fb6f8e7baeced`
- Stock configuration baseline:
  `9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`

## Latest Public-Clean Stack Validation

The current clean payload completed three rollback-protected boots with the
same kernel, Base CPIO, and payload hashes. Final project PID 1, micveth,
final-root Dropbear SSH, `/dev`, hello, pthread, and `dlopen` all passed. The
exact evidence and publication boundary are in
[Public-Clean Stack Hardware Validation](release/public-clean-stack-validation.md).

The accepted split-root path includes the independent KNC-compatible kernel and
five rebuilt modules, project early init, payload transfer with byte and
SHA-256 validation, a static project switch helper, a static final-init
trampoline, project PID 1, readiness, micveth, final-root Dropbear SSH, native
hello/pthread, Python 3.12.13, local dpkg/APT operation, and stock rollback.

The durable marker chain proved the final transition:

```text
XPR_SWITCH_HELPER_ENTERED
XPR_SWITCH_HELPER_CHDIR_OK
XPR_SWITCH_HELPER_MOVE_ROOT_OK
XPR_SWITCH_HELPER_CHROOT_OK
XPR_RC_TRAMPOLINE_ENTERED
XPR_RC_INIT_ENTERED
XPR_RC_ROOT_SBIN_INIT_PID1
```

Two clean builds produced identical bootstrap-root, Base-CPIO, and final-root
payload hashes. The accepted run passed the full release smoke suite, including
`apt-get install --reinstall xpr-pci-tools`, then restored stock online state,
stock SSH, stock PID 1, and the exact baseline MPSS configuration hash.

Later hardware usability checks also proved:

- the XPR-OS ASCII banner is emitted by final-root PID 1 and installed as the
  login MOTD;
- an interactive Dropbear session reaches the BusyBox `ash` prompt after
  mounting `devpts` and creating the KNC kernel's legacy `/dev/ptmx` node;
- Python 3.12's `exit()` and `quit()` helpers work after removing the private
  payload wrapper's hardcoded `-S` startup flag.

The public-clean image and source-built runtime completed the three-boot gate.
The earlier 2,916-file private payload and its 2,448 fail-closed findings are
historical evidence only. Python 3.5, Readline, and OpenSSL 1.0.x are excluded
from RC3. Kernel reproduction, module dependency mapping, eglibc, and
`libgcc_s` source builds are complete; the exact binary/source archives now
have SPDX metadata and two-run byte reproducibility. See
[prebuilt-image provenance](release/prebuilt-image-provenance.md).

Current execution checklist:

1. Keep the published RC2 source/BYO-MPSS release free of Intel/MPSS payloads
   and private generated binaries.
2. Preserve exact private artifact hashes and sanitized hardware evidence.
3. Obtain qualified human review of the five module grants and exact RC4
   binary/source archives before publication.
4. Preserve the reviewed hashes if a `v0.1.0-rc4` prerelease is approved.
5. Repeat the eventual publishable artifact on additional compatible KNC hardware
   when available.

Safety remains unchanged: no firmware, ROM, flash, or persistent card-storage
modification; alternate MPSS configuration only; automatic rollback; no public
Intel binaries, firmware, private keys, private logs, or unreviewed payloads.

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

There is no known boot blocker for the private 0.1.0-rc1 image on the tested
Xeon Phi 5110P. The blocker to a public prebuilt image is redistribution and
provenance review: the private build contains generated or locally supplied
K1OM components that cannot yet be published responsibly. The immediately
releasable form is source, metadata, and BYO-MPSS build tooling.

The no-op reconstruction control and project early-init evidence are recorded
in `docs/uos/base-cpio-reconstruction-control.md`.

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

The clean-root, final PID 1, networking, SSH, package-manager, and Python paths
are now established. Further package expansion is optional RC follow-up work;
the active release blocker is binary provenance and redistribution review.

## Project PID 1 uOS Boot Track

This section is a chronological milestone log. Early failure descriptions are
retained as evidence and are superseded by the current summary above and the
[RC live report](ubuntu-port/xpr-uos-0.1-rc-live-report.md).

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
- The clean project root performs the MPSS online notification through a
  project-owned readiness path. Three identical bounded boots reached `online`
  and returned a project TCP marker; each recovered to stock SSH.
- The later split-root RC proved project-owned final-root Dropbear SSH,
  interactive shell allocation, package management, Python, and project PID 1.
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
  `k1om-bootstrap-package-set-20260729-053340` verified `package_count=34`,
  deterministic package hashes, archive audit, simulated install, `/usr/bin/python3.12`,
  `python312_version_rc=0`, direct packaged smoke `python312_direct_rc=0`,
  second-stage service `python312_rc=0`, and
  `apt-get install --reinstall python3.12-smoke-k1om` with
  `apt_python312_install_rc=0`. The smoke covered zlib, hash modules, XML,
  pickle, CSV, asyncio import, sysconfig, threading, decimal, socket, pathlib,
  `bz2`, `lzma`, `readline`, `sqlite3`, `curses`, `curses.panel`, and other
  core modules. Stock rollback was verified afterward with
  `python312_absent`, `python312_bin_absent`, `python312_smoke_absent`,
  `dpkg_status_absent`, `apt_get_absent`, `dpkg_absent`, and stock `init`.
- The latest package-set run expanded to thirty-five packages by adding
  `ncurses-base-k1om`, a tiny terminfo package carrying the `linux` terminal
  entry needed by `curses.setupterm()`. The live run
  `k1om-bootstrap-package-set-20260729-174525` verified deterministic package
  hashes, archive audit, simulated install, `package_count=35`,
  `/usr/bin/python3.12`, `/usr/bin/dpkg-deb`, `dpkg_audit_rc=0`,
  `apt-cache pkgnames`, `apt-cache depends`, `apt-cache search`,
  `apt-get download`, direct packaged smoke `python312_direct_rc=0`,
  second-stage service `python312_rc=0`, and
  `apt-get install --reinstall python3.12-smoke-k1om` with
  `apt_python312_install_rc=0`. The Python 3.12 smoke now proves
  OpenSSL-backed modules and terminfo-backed curses behavior on `mic0`:
  `ssl=OpenSSL 3.0.13 30 Jan 2024`,
  `hashlib_openssl=2d711642`, `curses=2.2`, `curses_panel=True`,
  `curses_cols=80`, and `curses_lines=24`/`25`. `_ctypes` is intentionally
  skipped in the passing package smoke because the minimal private libffi
  shim can import `_ctypes` and report `ctypes.sizeof(ctypes.c_void_p) == 8`,
  but any `ctypes.CDLL` function call still segfaults. A standalone K1OM C
  harness can call `getpid()` through the same shim, so the remaining blocker
  is the `_ctypes`/libffi call integration rather than OpenSSL, curses, or
  Python import support.
- The next live run expanded to thirty-six packages with `libffi8-k1om` and
  completed the Python 3.12 FFI lane. The clean rebuild
  `libffi-k1om-repro-20260729-185225` produced K1OM static/shared libffi
  libraries. Its on-card acceptance test passed eight integer arguments,
  float, double, pointer, aggregate return, and closure callback cases. The
  package run `k1om-bootstrap-package-set-20260729-185939` passed deterministic
  builds, archive audit, simulated install, PID 1 handoff, SSH, and all
  existing smokes with `package_count=36`. Python reported
  `ctypes_ptr=8`, `ctypes_strlen=3`, and `ctypes_callback=42`. A deterministic
  `xpr-shell-compat` correction then made both `python3` and `python` select
  Python 3.12.13; a final live check passed `ctypes_strlen=11` and callback
  result `511`. The corrected profile remains online for inspection, with
  rollback at
  `/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-185939/rollback-stock.sh`.
- A minimal Ubuntu-shaped K1OM rootfs builder and validator now pass in a
  private toolcheck run:
  `k1om-minimal-rootfs-toolcheck-20260729-174425`. The generated rootfs has
  Ubuntu identity files, local `k1om` APT sources, `/var/lib/dpkg/status`,
  root-level `/bin`, `/usr/bin`, `/lib64`, `/etc`, `/dev`, `/proc`, `/sys`,
  and `/tmp` layout, `python3 -> python3.12`, package-manager entrypoints, and
  required device nodes. Validation confirmed symlink integrity and every
  detected ELF as K1OM machine `181`. The rootfs output remains private because
  it can contain locally supplied MPSS runtime files and K1OM binaries.
- CPython 3.12.13 now has a rollback-verified expanded runtime smoke on
  `mic0`. The K1OM cross build still requires `--disable-ipv6`, `-std=gnu1x`
  instead of `-std=c11`, `static_assert` and `_Alignof` compatibility shims,
  and a K1OM-specific `_Py_atomic_thread_fence` patch replacing unsupported
  `mfence` with `__sync_synchronize()`. The latest private runtime build
  statically enabled core modules and accelerators including `math`, `_struct`,
  `_json`, `_decimal`, `_socket`, `_pickle`, `_csv`, `_random`, `_queue`,
  `pyexpat`, `_elementtree`, `hashlib` backing modules, `zlib`, `_bz2`,
  `_lzma`, `readline`, `_sqlite3`, `_curses`, and `_curses_panel`. The latest
  package run proved those
  additions through `python3.12-smoke-k1om`: `bz2=bz-ok`, `lzma=lzma-ok`,
  `readline=True`, `sqlite3=42:3.45.1`, `curses=2.2`, and
  `curses_panel=True`. This work is still a bootstrap distribution rather than
  an official Ubuntu Python build.
- The latest rollback-verified package-set run completed at
  `/root/xeon-phi-revival-local/ubuntu-port-runs/k1om-bootstrap-package-set-20260729-174525`.
  Stock rollback succeeded afterward: SSH worked, the project profile,
  `/var/lib/dpkg/status`, and the Python 3.12 staging paths were absent, and
  PID 1 was stock `init`.
- Ubuntu Noble dpkg `1.22.6ubuntu6.6` and Noble libmd were cleanly cross-built
  for K1OM. Seven core dpkg executables were audited as machine 181, a clean
  reproducibility run passed, and real dpkg completed both a package smoke and
  a full 36-package isolated transaction on `mic0`.
- Ubuntu APT `1.0.1ubuntu2.24` was built as a native K1OM compatibility bridge
  with a PIC Noble zlib. Fourteen staged ELF files passed machine-181 audit.
  On `mic0`, real APT updated from the local Noble-style `file:` archive,
  resolved dependencies, installed three packages through real dpkg, then
  installed and configured all 36 packages into a fresh isolated root.
  `dpkg --audit` was clean and Python 3.12 ran from the APT-created root with
  `ctypes`, SQLite, and zlib.
- Ubuntu Noble APT `2.8.3` was probed but not built. It requires C++17, while
  MPSS K1OM GCC 4.7 accepts `gnu++0x` and rejects `gnu++11`, `gnu++14`, and
  `gnu++17`. A modern K1OM compiler and compatible C++ runtime are now an
  explicit architecture-port dependency.
- The Ubuntu-source eglibc 2.19 side-by-side runtime probe now passes the
  immediate pthread boundary. K1OM `ld-linux-k1om.so.2`, `libc.so.6`,
  `libpthread.so.0`, `libm.so.6`, `libdl.so.2`, `librt.so.1`, and
  `libutil.so.1` were built under `/opt/xeon-phi-revival/eglibc-2.19`.
  On the real `k1om` uOS, the dynamic hello smoke printed
  `eglibc-v21 hello pid=4901` and exited `0`; the pthread smoke printed
  `eglibc-v21 pthread value=219 same=1` and exited `0`.
- The package builder now accepts `--libc-root`; pointed at the eglibc 2.19
  prefix, it produced a deterministic 36-package bootstrap set with
  eglibc-backed `libc6-k1om`, `libpthread0-k1om`, `libm6-k1om`, `libdl2-k1om`,
  `librt1-k1om`, and `libutil1-k1om`.
- The live eglibc-backed package gate now passes. The earlier ABI failure was
  resolved by rebuilding `hello-knc`, CPython 3.12.13, zlib/ncurses smokes,
  libffi, and runtime payload layout against the eglibc loader/libc stack. The
  final run `k1om-bootstrap-package-set-20260730-050604` booted on `mic0`,
  showed Ubuntu/K1OM identity, populated 36 dpkg status records, ran APT update
  and install paths, verified `python3`/`python` as Python 3.12.13, passed
  `_ctypes` calls and callbacks, passed zlib/ncurses/runtime-library/OS smokes,
  and rolled back to stock MPSS uOS.
- Residual cleanup: the legacy Python 3.5 compatibility package still logs
  MPSS `GLIBC_2.14` symbol-version mismatches under the eglibc profile, and
  several Python 3.12 optional extension modules remain outside this minimal
  eglibc gate: `_bz2`, `_lzma`, `readline`, `_sqlite3`, `_curses`, `_ssl`, and
  `_hashlib`.
- The first K1OM uOS 0.1 release-candidate pipeline now passes live. Build run
  `xpr-uos-rc-20260730-053125` produced a private coherent rootfs
  (`126M`, compressed archive `37M`, SHA-256
  `55a4cc64d78b7d7aab328f521816dcb5ad2a279f9b82bae481aa776351149147`).
  Live run `xpr-uos-rc-live-20260730-053936` booted through MicDir, presented
  `ID=xpr-uos` / `ID_LIKE=ubuntu`, passed shell/filesystem/package-manager/
  Python 3.12/ctypes/pthread/zlib/ncurses/network/SSH smoke checks, and rolled
  back to stock MPSS.

## Current Public Entry Points

- [Documentation map](README.md)
- [Card-to-code guide](getting-started-card-to-code.md)
- [RC source-build guide](release/build-xpr-os-rc-from-source.md)
- [RC live hardware report](ubuntu-port/xpr-uos-0.1-rc-live-report.md)
- [RC acceptance checklist](ubuntu-port/uos-rc-acceptance-checklist.md)
- [Source index](source-index.md)
- [Compliance review](release/compliance-review.md)
- [Release license review](release/xpr-uos-0.1-license-review.md)

The complete dated experiment and manifest inventory remains in `docs/`,
`manifests/`, and `artifacts/public/`. Use the documentation map instead of
treating every historical report as a current instruction page.

## Highest-Value Next Technical Action

Complete the per-component provenance matrix, replace or rebuild
lineage-uncertain binary inputs, and produce one clean private image containing
the committed banner, PTY, and Python-site fixes. Then run the exact image
through the complete hardware smoke and stock-rollback suite before considering
a prebuilt binary prerelease.
