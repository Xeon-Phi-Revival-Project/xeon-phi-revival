#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-k1om-bootstrap-packages.sh --payload-rootfs DIR --out-dir DIR [--version V]

Build a small local K1OM bootstrap package set:
  base-files-k1om
  hello-knc-smoke
  python3.5-minimal-k1om
  python3.5-stdlib-k1om
  python3.5-lib-dynload-k1om
  python3.5-smoke-k1om
  xpr-shell-compat
  xpr-busybox-compat
  xpr-pci-tools
  zlib-smoke-k1om
  libtinfo5-k1om
  ncurses-smoke-k1om
  xeon-phi-revival-stage2
  xpr-os-smoke

Outputs are private if the payload rootfs contains non-redistributable runtime
files or locally built binaries.
USAGE
}

payload_rootfs=""
out_dir=""
version="0.1.0"
arch="k1om"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --version) version="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if [[ -z "$payload_rootfs" || -z "$out_dir" ]]; then
  usage
  exit 2
fi

for path in \
  "$payload_rootfs/usr/bin/hello-knc" \
  "$payload_rootfs/usr/bin/python3.5" \
  "$payload_rootfs/usr/lib/python3.5" \
  "$payload_rootfs/usr/bin/zlib-smoke" \
  "$payload_rootfs/usr/bin/ncurses-smoke" \
  "$payload_rootfs/lib64/libtinfo.so.5"; do
  [[ -e "$path" ]] || { echo "required payload path missing: $path" >&2; exit 10; }
done

build_root="$out_dir/build"
archive_dir="$out_dir/repo/pool/main"
manifest="$out_dir/bootstrap-packages.manifest.tsv"
rm -rf "$build_root"
mkdir -p "$build_root" "$archive_dir" "$(dirname "$manifest")"

make_deb() {
  local package="$1"
  local data_dir="$2"
  local depends="${3:-}"
  local description="$4"
  local section="${5:-base}"
  local pkg_dir="$build_root/${package}_${version}_${arch}/pkg"
  local control_dir="$build_root/${package}_${version}_${arch}/control"
  local pool_dir="$archive_dir/${package:0:1}/$package"
  local deb_path="$pool_dir/${package}_${version}_${arch}.deb"
  mkdir -p "$pkg_dir" "$control_dir" "$pool_dir"
  local installed_size
  installed_size="$(du -sk "$data_dir" | awk '{print $1}')"
  cat > "$control_dir/control" <<EOF
Package: $package
Source: xeon-phi-revival-bootstrap
Version: $version
Architecture: $arch
Maintainer: Xeon Phi Revival Project
Installed-Size: $installed_size
Section: $section
Priority: optional
EOF
  if [[ -n "$depends" ]]; then
    printf 'Depends: %s\n' "$depends" >> "$control_dir/control"
  fi
  cat >> "$control_dir/control" <<EOF
Description: $description
 Bootstrap package for local K1OM Ubuntu-port experiments.
EOF
  (cd "$data_dir" && find . -type f ! -path './etc/*' -print0 | LC_ALL=C sort -z | xargs -0 -r md5sum | sed 's#  \./#  #' > "$control_dir/md5sums")
  if [[ -d "$data_dir/etc" ]]; then
    (cd "$data_dir" && find ./etc -type f -print | LC_ALL=C sort | sed 's#^\./#/#' > "$control_dir/conffiles")
    [[ -s "$control_dir/conffiles" ]] || rm -f "$control_dir/conffiles"
  fi
  (cd "$control_dir" && find . -print0 | LC_ALL=C sort -z | tar --null --no-recursion --numeric-owner --owner=0 --group=0 --mtime="@$source_date_epoch" -T - -cf - | gzip -n > "$pkg_dir/control.tar.gz")
  (cd "$data_dir" && find . -print0 | LC_ALL=C sort -z | tar --null --no-recursion --numeric-owner --owner=0 --group=0 --mtime="@$source_date_epoch" -T - -cf - | gzip -n > "$pkg_dir/data.tar.gz")
  printf '2.0\n' > "$pkg_dir/debian-binary"
  (cd "$pkg_dir" && ar rcsD "$deb_path" debian-binary control.tar.gz data.tar.gz)
  sha256sum "$deb_path"
}

new_data_dir() {
  local package="$1"
  local dir="$build_root/${package}_${version}_${arch}/data"
  rm -rf "$dir"
  mkdir -p "$dir"
  printf '%s\n' "$dir"
}

base_data="$(new_data_dir base-files-k1om)"
mkdir -p "$base_data/opt/xeon-phi-revival/bin" "$base_data/opt/xeon-phi-revival/lib" "$base_data/opt/xeon-phi-revival/python" "$base_data/opt/xeon-phi-revival/share" "$base_data/var/log/xeon-phi-revival" "$base_data/etc"
cat > "$base_data/opt/xeon-phi-revival/profile.env" <<EOF
XPR_PROFILE_VERSION=$version
XPR_PROFILE_KIND=stock-init-handoff-second-stage
XPR_PHASE=bootstrap
XPR_ROOT=/opt/xeon-phi-revival
EOF
cat > "$base_data/etc/xeon-phi-revival-release" <<EOF
NAME="Xeon Phi Revival Project uOS Profile"
VERSION="$version"
ARCH="$arch"
BASE="stock MPSS uOS"
EOF

hello_data="$(new_data_dir hello-knc-smoke)"
mkdir -p "$hello_data/opt/xeon-phi-revival/bin"
cp -a "$payload_rootfs/usr/bin/hello-knc" "$hello_data/opt/xeon-phi-revival/bin/hello-knc"

python_minimal_data="$(new_data_dir python3.5-minimal-k1om)"
mkdir -p "$python_minimal_data/opt/xeon-phi-revival/bin"
cp -a "$payload_rootfs/usr/bin/python3.5" "$python_minimal_data/opt/xeon-phi-revival/bin/python3.5"

python_stdlib_data="$(new_data_dir python3.5-stdlib-k1om)"
mkdir -p "$python_stdlib_data/opt/xeon-phi-revival/lib"
cp -a "$payload_rootfs/usr/lib/python3.5" "$python_stdlib_data/opt/xeon-phi-revival/lib/python3.5"
rm -rf "$python_stdlib_data/opt/xeon-phi-revival/lib/python3.5/lib-dynload"

python_dynload_data="$(new_data_dir python3.5-lib-dynload-k1om)"
mkdir -p "$python_dynload_data/opt/xeon-phi-revival/lib/python3.5"
if [[ -d "$payload_rootfs/usr/lib/python3.5/lib-dynload" ]]; then
  cp -a "$payload_rootfs/usr/lib/python3.5/lib-dynload" "$python_dynload_data/opt/xeon-phi-revival/lib/python3.5/lib-dynload"
fi

python_smoke_data="$(new_data_dir python3.5-smoke-k1om)"
mkdir -p "$python_smoke_data/opt/xeon-phi-revival/share"
cat > "$python_smoke_data/opt/xeon-phi-revival/share/python-core-stage2.py" <<'PY'
import os
import sys

print("python stage2 demo ok")
print("platform=%s" % sys.platform)
print("cwd=%s" % os.getcwd())
print("prefix=%s" % sys.prefix)
print("calc=%d" % sum(range(10)))
PY

shell_compat_data="$(new_data_dir xpr-shell-compat)"
mkdir -p "$shell_compat_data/etc/profile.d" "$shell_compat_data/usr/bin" "$shell_compat_data/opt/xeon-phi-revival/bin"
cat > "$shell_compat_data/etc/profile.d/xeon-phi-revival.sh" <<'PROFILE'
XPR_ROOT=/opt/xeon-phi-revival
PATH="$XPR_ROOT/bin:$PATH"
LD_LIBRARY_PATH="$XPR_ROOT/lib64:${LD_LIBRARY_PATH:-}"
PYTHONHOME="$XPR_ROOT"
PYTHONPATH="$XPR_ROOT/lib/python3.5:$XPR_ROOT/lib/python3.5/lib-dynload"
export XPR_ROOT PATH LD_LIBRARY_PATH PYTHONHOME PYTHONPATH
PROFILE
cat > "$shell_compat_data/usr/bin/python3" <<'PYWRAP'
#!/bin/sh
XPR_ROOT=/opt/xeon-phi-revival
export PYTHONHOME="$XPR_ROOT"
export PYTHONPATH="$XPR_ROOT/lib/python3.5:$XPR_ROOT/lib/python3.5/lib-dynload"
export LD_LIBRARY_PATH="$XPR_ROOT/lib64:${LD_LIBRARY_PATH:-}"
if [ "${XPR_PYTHON_ENABLE_SITE:-0}" = "1" ]; then
  exec "$XPR_ROOT/bin/python3.5" "$@"
fi
exec "$XPR_ROOT/bin/python3.5" -S "$@"
PYWRAP
chmod 0755 "$shell_compat_data/usr/bin/python3"
ln -s python3 "$shell_compat_data/usr/bin/python"
ln -s ../../../usr/bin/python3 "$shell_compat_data/opt/xeon-phi-revival/bin/python3"
ln -s ../../../usr/bin/python3 "$shell_compat_data/opt/xeon-phi-revival/bin/python"

busybox_compat_data="$(new_data_dir xpr-busybox-compat)"
mkdir -p "$busybox_compat_data/opt/xeon-phi-revival/bin"
for applet in \
  awk basename cat chmod chown cp cut date df dirname dmesg du echo env \
  false find grep head hostname id kill ln ls mkdir mount mv printf ps pwd \
  readlink rm sed sh sleep sort stat tail tar test touch true uname wc; do
  ln -s /bin/busybox "$busybox_compat_data/opt/xeon-phi-revival/bin/$applet"
done

pci_tools_data="$(new_data_dir xpr-pci-tools)"
mkdir -p "$pci_tools_data/opt/xeon-phi-revival/bin" "$pci_tools_data/usr/bin"
cat > "$pci_tools_data/usr/bin/pcietool" <<'PCI'
#!/bin/sh
set -u
mode="${1:-list}"
case "$mode" in
  list|"")
    for dev in /sys/bus/pci/devices/*; do
      [ -d "$dev" ] || continue
      bdf="${dev##*/}"
      vendor="$(cat "$dev/vendor" 2>/dev/null || echo unknown)"
      device="$(cat "$dev/device" 2>/dev/null || echo unknown)"
      class="$(cat "$dev/class" 2>/dev/null || echo unknown)"
      subsystem_vendor="$(cat "$dev/subsystem_vendor" 2>/dev/null || echo unknown)"
      subsystem_device="$(cat "$dev/subsystem_device" 2>/dev/null || echo unknown)"
      printf '%s vendor=%s device=%s class=%s subsystem=%s:%s\n' \
        "$bdf" "$vendor" "$device" "$class" "$subsystem_vendor" "$subsystem_device"
    done
    ;;
  tree)
    find /sys/bus/pci/devices -maxdepth 1 -type l -print | sort
    ;;
  help|-h|--help)
    echo "usage: pcietool [list|tree|help]"
    ;;
  *)
    echo "pcietool: unknown command: $mode" >&2
    echo "usage: pcietool [list|tree|help]" >&2
    exit 2
    ;;
esac
PCI
chmod 0755 "$pci_tools_data/usr/bin/pcietool"
ln -s ../../../usr/bin/pcietool "$pci_tools_data/opt/xeon-phi-revival/bin/pcietool"

os_data="$(new_data_dir xpr-os-smoke)"
mkdir -p "$os_data/opt/xeon-phi-revival/bin"
cat > "$os_data/opt/xeon-phi-revival/bin/os-smoke.sh" <<'OS'
#!/bin/sh
set -u
LOG_DIR=/var/log/xeon-phi-revival
OUT="$LOG_DIR/os-smoke.out"
TMPDIR=/tmp/xeon-phi-revival-os-smoke
mkdir -p "$LOG_DIR" "$TMPDIR"
{
  echo "os_smoke_started=1"
  uname -a
  echo "pid1=$(cat /proc/1/comm 2>/dev/null || true)"
  echo "cwd=$(pwd)"
  echo "root_listing:"
  ls -la /
  echo "proc_mount=$(awk '$2 == "/proc" { print; exit }' /proc/mounts)"
  echo "sys_mount=$(awk '$2 == "/sys" { print; exit }' /proc/mounts)"
  echo "dev_mount=$(awk '$2 == "/dev" { print; exit }' /proc/mounts)"
  echo "tmp_write_test" > "$TMPDIR/write-test.txt"
  cat "$TMPDIR/write-test.txt"
  ln -s write-test.txt "$TMPDIR/write-test.link"
  readlink "$TMPDIR/write-test.link"
  mkdir -p "$TMPDIR/nested/a"
  echo "nested_ok" > "$TMPDIR/nested/a/file.txt"
  find "$TMPDIR" -maxdepth 3 \( -type f -o -type l \) | sort
  echo "df:"
  df -h / /tmp 2>/dev/null || true
  echo "network:"
  ip addr show mic0 2>/dev/null || ifconfig mic0 2>/dev/null || true
  echo "env:"
  env | sort
  echo "os_smoke_done=1"
} > "$OUT" 2>&1
exit 0
OS
chmod 0755 "$os_data/opt/xeon-phi-revival/bin/os-smoke.sh"

zlib_data="$(new_data_dir zlib-smoke-k1om)"
mkdir -p "$zlib_data/opt/xeon-phi-revival/bin"
cp -a "$payload_rootfs/usr/bin/zlib-smoke" "$zlib_data/opt/xeon-phi-revival/bin/zlib-smoke"

ncurses_data="$(new_data_dir ncurses-smoke-k1om)"
mkdir -p "$ncurses_data/opt/xeon-phi-revival/bin"
cp -a "$payload_rootfs/usr/bin/ncurses-smoke" "$ncurses_data/opt/xeon-phi-revival/bin/ncurses-smoke"

libtinfo_data="$(new_data_dir libtinfo5-k1om)"
mkdir -p "$libtinfo_data/opt/xeon-phi-revival/lib64"
cp -a "$payload_rootfs/lib64/libtinfo.so.5" "$libtinfo_data/opt/xeon-phi-revival/lib64/libtinfo.so.5"
if [[ -e "$payload_rootfs/lib64/libtinfo.so.5.9" ]]; then
  cp -a "$payload_rootfs/lib64/libtinfo.so.5.9" "$libtinfo_data/opt/xeon-phi-revival/lib64/libtinfo.so.5.9"
fi

stage2_data="$(new_data_dir xeon-phi-revival-stage2)"
mkdir -p "$stage2_data/etc/init.d" "$stage2_data/etc/rc5.d"
cat > "$stage2_data/etc/init.d/xeon-phi-revival-stage2" <<'INIT'
#!/bin/sh
PATH=/opt/xeon-phi-revival/bin:/sbin:/bin:/usr/sbin:/usr/bin
XPR_ROOT=/opt/xeon-phi-revival
LOG_DIR=/var/log/xeon-phi-revival
LOG="$LOG_DIR/stage2.log"
mkdir -p "$LOG_DIR"
case "$1" in
  start)
    PHASE=bootstrap
    [ -f "$XPR_ROOT/profile.env" ] && . "$XPR_ROOT/profile.env"
    {
      echo "[stage2] start"
      echo "phase=${XPR_PHASE:-$PHASE}"
      echo "pid=$$"
      date -u 2>/dev/null || true
      uname -a 2>/dev/null || true
      echo "pid1=$(cat /proc/1/comm 2>/dev/null || true)"
    } >> "$LOG" 2>&1
    if [ -x "$XPR_ROOT/bin/hello-knc" ]; then
      "$XPR_ROOT/bin/hello-knc" > "$LOG_DIR/hello-knc.out" 2>&1
      echo "hello_rc=$?" >> "$LOG"
    fi
    if [ -x "$XPR_ROOT/bin/python3.5" ]; then
      PYTHONHOME="$XPR_ROOT" PYTHONPATH="$XPR_ROOT/lib/python3.5:$XPR_ROOT/lib/python3.5/lib-dynload" "$XPR_ROOT/bin/python3.5" -S "$XPR_ROOT/share/python-core-stage2.py" > "$LOG_DIR/python-core.out" 2>&1
      echo "python_rc=$?" >> "$LOG"
    fi
    if [ -x "$XPR_ROOT/bin/zlib-smoke" ]; then
      LD_LIBRARY_PATH="$XPR_ROOT/lib64:${LD_LIBRARY_PATH:-}" "$XPR_ROOT/bin/zlib-smoke" > "$LOG_DIR/zlib-smoke.out" 2>&1
      echo "zlib_rc=$?" >> "$LOG"
    fi
    if [ -x "$XPR_ROOT/bin/ncurses-smoke" ]; then
      LD_LIBRARY_PATH="$XPR_ROOT/lib64:${LD_LIBRARY_PATH:-}" "$XPR_ROOT/bin/ncurses-smoke" > "$LOG_DIR/ncurses-smoke.out" 2>&1
      echo "ncurses_rc=$?" >> "$LOG"
    fi
    if [ -x "$XPR_ROOT/bin/os-smoke.sh" ]; then
      "$XPR_ROOT/bin/os-smoke.sh"
      echo "os_smoke_rc=$?" >> "$LOG"
    fi
    echo "[stage2] done" >> "$LOG"
    ;;
  stop) echo "[stage2] stop" >> "$LOG" 2>/dev/null || true ;;
esac
exit 0
INIT
chmod 0755 "$stage2_data/etc/init.d/xeon-phi-revival-stage2"
ln -s ../init.d/xeon-phi-revival-stage2 "$stage2_data/etc/rc5.d/S78xeon-phi-revival-stage2"

make_deb base-files-k1om "$base_data" "" "Base profile files for K1OM" "base"
make_deb hello-knc-smoke "$hello_data" "base-files-k1om" "K1OM hello smoke binary" "devel"
make_deb python3.5-minimal-k1om "$python_minimal_data" "base-files-k1om" "K1OM Python 3.5 interpreter payload" "python"
make_deb python3.5-stdlib-k1om "$python_stdlib_data" "base-files-k1om, python3.5-minimal-k1om" "K1OM Python 3.5 pure standard library payload" "python"
make_deb python3.5-lib-dynload-k1om "$python_dynload_data" "base-files-k1om, python3.5-minimal-k1om, python3.5-stdlib-k1om" "K1OM Python 3.5 dynamic extension payload" "python"
make_deb python3.5-smoke-k1om "$python_smoke_data" "base-files-k1om, python3.5-minimal-k1om, python3.5-stdlib-k1om" "K1OM Python 3.5 smoke script payload" "python"
make_deb xpr-shell-compat "$shell_compat_data" "base-files-k1om, python3.5-minimal-k1om, python3.5-stdlib-k1om, python3.5-lib-dynload-k1om" "Shell compatibility entrypoints for the K1OM profile" "shells"
make_deb xpr-busybox-compat "$busybox_compat_data" "base-files-k1om" "BusyBox-backed shell command entrypoints for the K1OM profile" "shells"
make_deb xpr-pci-tools "$pci_tools_data" "base-files-k1om, xpr-busybox-compat" "Small sysfs PCI inspection tools for the K1OM profile" "utils"
make_deb zlib-smoke-k1om "$zlib_data" "base-files-k1om" "K1OM zlib smoke payload" "libs"
make_deb libtinfo5-k1om "$libtinfo_data" "base-files-k1om" "K1OM terminfo runtime library" "libs"
make_deb ncurses-smoke-k1om "$ncurses_data" "base-files-k1om, libtinfo5-k1om" "K1OM ncurses smoke payload" "utils"
make_deb xpr-os-smoke "$os_data" "base-files-k1om" "Basic filesystem and OS smoke checks" "utils"
make_deb xeon-phi-revival-stage2 "$stage2_data" "base-files-k1om, hello-knc-smoke, python3.5-minimal-k1om, python3.5-stdlib-k1om, python3.5-lib-dynload-k1om, python3.5-smoke-k1om, xpr-shell-compat, xpr-busybox-compat, xpr-pci-tools, zlib-smoke-k1om, libtinfo5-k1om, ncurses-smoke-k1om, xpr-os-smoke" "Second-stage service for K1OM profile" "admin"

{
  printf 'package\tversion\tarchitecture\tpath\tsha256\n'
  while IFS= read -r -d '' deb; do
    printf '%s\t%s\t%s\t%s\t%s\n' "$(basename "$deb" | cut -d_ -f1)" "$version" "$arch" "$deb" "$(sha256sum "$deb" | awk '{print $1}')"
  done < <(find "$out_dir/repo/pool" -type f -name '*.deb' -print0 | sort -z)
} > "$manifest"
echo "manifest=$manifest"
