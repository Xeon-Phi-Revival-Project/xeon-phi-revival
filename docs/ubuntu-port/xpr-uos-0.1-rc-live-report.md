# Xeon Phi Revival uOS 0.1 RC Live Report

Date: 2026-08-10

## Result

Status: split-root final-root gate passed live on `mic0`.

The release-candidate pipeline produced a coherent private K1OM rootfs, booted
the project compatibility kernel and bootstrap through MPSS, transferred the
checksummed final-root payload, entered that root with project PID 1, ran the
full RC smoke test over final-root SSH, and rolled back to stock MPSS.

This is a minimal Ubuntu-derived K1OM uOS release candidate. It is not an
official Ubuntu, Canonical, or Intel release, and it does not replace the stock
firmware or host MPSS driver. The accepted path does not hand off to stock card
init or stock card-side SSH.

## Accepted Split-Root Artifacts

```text
candidate_kernel_sha256=0450c4370fb9c023c5229274d9a7a5cc02b8a37838c3220a0c714fc602cb2505
bootstrap_root_sha256=46fde82d0f5a0afe91719d1266c6e1151ec2b945fb78f96a3af669b1d38ff4f3
base_cpio_sha256=42b7560f8dcc277f1d976e40db57668caedb749125e66171281ea8ba755e3bef
final_payload_sha256=8a410d8577971068888f46cee66b7b6020f675144f9d0cafc6a79efce53b7520
bootstrap_root_bytes=6071745
base_cpio_bytes=29578142
final_payload_bytes=77582489
```

Two clean builds produced identical generated hashes. The accepted hardware
run directory was
`/root/xpr-candidate-kernel-test/base-cpio-control-20260810-002900` and its
summary was:

```text
online=1
project_ssh=1
switched=1
smoke=1
```

The handoff markers proved the transition through the project helper and final
init trampoline:

```text
XPR_SWITCH_HELPER_ENTERED
XPR_SWITCH_HELPER_CHDIR_OK
XPR_SWITCH_HELPER_MOVE_ROOT_OK
XPR_SWITCH_HELPER_CHROOT_OK
XPR_RC_TRAMPOLINE_ENTERED
XPR_RC_INIT_ENTERED
XPR_RC_ROOT_SBIN_INIT_PID1
```

Final PID 1 was BusyBox executing `/sbin/xpr-rc-init.sh`, as designed.

## Earlier MicDir Baseline

The earlier July 30 MicDir profile result began from:

```text
1b6d76e Document passing eglibc K1OM package gate
```

Active MPSS config hash checked before live modification:

```text
9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51
```

## Earlier Private Build Artifacts

Private RC build run:

```text
/root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125
```

Produced artifacts:

```text
rootfs=/root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/rootfs/rootfs
rootfs_archive=/root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/xpr-uos-0.1-k1om-rootfs.tar.gz
rootfs_archive_sha256=55a4cc64d78b7d7aab328f521816dcb5ad2a279f9b82bae481aa776351149147
package_repo=/root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/packages/repo
artifact_manifest=/root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/artifact-manifest.tsv
release_candidate_manifest=/root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/release-candidate.yml
```

Size:

```text
rootfs directory: 126M
rootfs archive:   37M
```

Package count:

```text
36
```

The generated rootfs and `.deb` repository are private artifacts. They are not
committed because they can contain locally supplied MPSS/K1OM material and
generated binaries that require redistribution review.

## Final Smoke Evidence

The final-root card presented K1OM and the project identity. The comprehensive
smoke suite retained all checks below and additionally proved the project
switch-root marker chain and final-root PID 1.

The kernel presented:

```text
Linux unknownf48e38c1a578-mic0.home 2.6.38.8+mpss3.4.10 #1 SMP Thu Jan 12 16:38:30 EST 2017 k1om GNU/Linux
```

Project identity:

```text
NAME="Xeon Phi Revival uOS"
PRETTY_NAME="Xeon Phi Revival Ubuntu-derived K1OM uOS"
ID=xpr-uos
ID_LIKE=ubuntu
VERSION_ID="0.1"
VERSION="0.1 release candidate"
VERSION_CODENAME=noble
ARCHITECTURE="k1om"
```

The RC smoke test passed these checks:

```text
PASS:uname_machine_k1om
PASS:os_id_xpr
PASS:os_like_ubuntu
PASS:os_arch_k1om
PASS:pid1_visible
PASS:sh_command
PASS:cmd_ls
PASS:cmd_cat
PASS:cmd_cp
PASS:cmd_mv
PASS:cmd_rm
PASS:cmd_mkdir
PASS:cmd_mount
PASS:cmd_uname
PASS:cmd_ps
PASS:cmd_env
PASS:file_ops
PASS:proc_dir
PASS:sys_dir
PASS:dev_dir
PASS:run_dir
PASS:tmp_writable
PASS:proc_mounted
PASS:sys_mounted
PASS:dev_null
PASS:dpkg_arch
PASS:dpkg_query
PASS:dpkg_deb
PASS:apt_update
PASS:apt_cache
PASS:apt_reinstall
PASS:loader
PASS:libc
PASS:libpthread
PASS:hello_loader
PASS:stage2_log
PASS:hello_stage2
PASS:pthread_stack
PASS:zlib_stage2
PASS:ncurses_stage2
PASS:python3_exec
PASS:python_default
PASS:python312_smoke
PASS:ctypes_call
PASS:ctypes_callback
PASS:zlib_import
PASS:network_visibility
PASS:ssh_available
```

Package-management evidence:

```text
dpkg --print-architecture => k1om
apt-get update => passed
apt-get install --reinstall xpr-pci-tools => passed
```

Python evidence:

```text
Python 3.12.13
ctypes_strlen=3
ctypes_callback=42
```

## Optional Python Gaps

These optional modules remain gaps in the eglibc RC profile:

```text
OPTIONAL_GAP:bz2:ModuleNotFoundError:No module named '_bz2'
OPTIONAL_GAP:lzma:ModuleNotFoundError:No module named '_lzma'
OPTIONAL_GAP:readline:ModuleNotFoundError:No module named 'readline'
OPTIONAL_GAP:sqlite3:ModuleNotFoundError:No module named '_sqlite3'
OPTIONAL_GAP:curses:ModuleNotFoundError:No module named '_curses'
OPTIONAL_GAP:curses.panel:ModuleNotFoundError:No module named '_curses'
```

These were explicitly treated as non-blocking for RC 0.1. `_ssl` and
`_hashlib` are also not part of the RC success line.

## Rollback

Rollback verified stock MPSS recovery, stock SSH, stock PID 1, and exact
configuration-hash restoration:

```text
stock_ssh_ok
profile_absent
stage2_log_absent
dpkg_status_absent
python3_absent
apt_get_absent
init
```

The accepted final run restored configuration hash
`9578fa0392f196b08cb9c3d8b36077bf475bf412b44faaf54ffbfe9db1221f51`.

## Remaining Blockers To A Public Downloadable uOS

- Redistribution review for generated rootfs archives and K1OM binaries.
- Clear per-file classification for Ubuntu/GNU-derived binary outputs.
- Removal or replacement of remaining private Intel/MPSS payload dependencies
  where redistribution is not allowed.
- Optional Python extension packaging for `_bz2`, `_lzma`, `readline`,
  `_sqlite3`, `_curses`, and `curses.panel`.
- A downloadable release procedure that publishes only approved artifacts.

## Highest-Value Next Step

Run the redistribution review path against the generated artifact manifest and
split the RC output into:

- public metadata/source/package recipes;
- redistributable generated outputs;
- bring-your-own-MPSS local inputs.

That review is now tracked in
`docs/release/xpr-uos-0.1-license-review.md`. The current recommendation is to
publish the first usable release as a source/metadata/BYO-MPSS builder release,
not as a prebuilt rootfs. A public binary rootfs should wait until copied or
lineage-uncertain payloads are removed, rebuilt from documented public sources,
or covered by a human legal review.
