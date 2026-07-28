#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-k1om-profile-deb.sh --payload-rootfs DIR --out-dir DIR [--version V]

Build a local, private K1OM .deb-style bootstrap package for the project uOS
profile. The output may contain locally supplied K1OM binaries and Python
payloads, so keep it out of the public repository.

The package is intentionally small in policy surface: it installs files under
/opt/xeon-phi-revival plus a SysV rc5 hook. It does not include MPSS firmware,
stock uOS images, or Intel packages.
USAGE
}

payload_rootfs=""
out_dir=""
version="0.1.0"
package="xeon-phi-revival-profile"
arch="k1om"

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
  "$payload_rootfs/usr/lib/python3.5"; do
  if [[ ! -e "$path" ]]; then
    echo "required payload path missing: $path" >&2
    exit 10
  fi
done

build_dir="$out_dir/build/${package}_${version}_${arch}"
pkg_dir="$build_dir/pkg"
control_dir="$build_dir/control"
data_dir="$build_dir/data"
archive_dir="$out_dir/repo/pool/main/x/$package"
deb_path="$archive_dir/${package}_${version}_${arch}.deb"
manifest="$out_dir/${package}_${version}_${arch}.manifest.tsv"

rm -rf "$build_dir"
mkdir -p "$pkg_dir" "$control_dir" "$data_dir/opt/xeon-phi-revival/bin" \
  "$data_dir/opt/xeon-phi-revival/lib" \
  "$data_dir/opt/xeon-phi-revival/python" \
  "$data_dir/opt/xeon-phi-revival/share" \
  "$data_dir/etc/init.d" "$data_dir/etc/rc5.d" "$archive_dir"

cp -a "$payload_rootfs/usr/bin/hello-knc" "$data_dir/opt/xeon-phi-revival/bin/hello-knc"
cp -a "$payload_rootfs/usr/bin/python3.5" "$data_dir/opt/xeon-phi-revival/bin/python3.5"
cp -a "$payload_rootfs/usr/lib/python3.5" "$data_dir/opt/xeon-phi-revival/python/python3.5"

cat > "$data_dir/opt/xeon-phi-revival/share/python-core-stage2.py" <<'PY'
import os
import sys

print("python stage2 demo ok")
print("platform=%s" % sys.platform)
print("cwd=%s" % os.getcwd())
print("prefix=%s" % sys.prefix)
print("calc=%d" % sum(range(10)))
PY

cat > "$data_dir/opt/xeon-phi-revival/profile.env" <<EOF
XPR_PROFILE_VERSION=$version
XPR_PROFILE_KIND=stock-init-handoff-second-stage
XPR_PHASE=profile
XPR_ROOT=/opt/xeon-phi-revival
EOF

cat > "$data_dir/etc/init.d/xeon-phi-revival-stage2" <<'INIT'
#!/bin/sh
PATH=/opt/xeon-phi-revival/bin:/sbin:/bin:/usr/sbin:/usr/bin
XPR_ROOT=/opt/xeon-phi-revival
LOG_DIR=/var/log/xeon-phi-revival
LOG="$LOG_DIR/stage2.log"
mkdir -p "$LOG_DIR"

case "$1" in
  start)
    PHASE="${XPR_PHASE:-unknown}"
    if [ -f "$XPR_ROOT/profile.env" ]; then
      . "$XPR_ROOT/profile.env"
      PHASE="${XPR_PHASE:-$PHASE}"
    fi
    {
      echo "[stage2] start"
      echo "phase=$PHASE"
      echo "pid=$$"
      date -u 2>/dev/null || true
      uname -a 2>/dev/null || true
      echo "pid1=$(cat /proc/1/comm 2>/dev/null || true)"
      echo "network:"
      ip addr show mic0 2>/dev/null || ifconfig mic0 2>/dev/null || true
    } >> "$LOG" 2>&1

    if [ -x "$XPR_ROOT/bin/hello-knc" ]; then
      "$XPR_ROOT/bin/hello-knc" > "$LOG_DIR/hello-knc.out" 2>&1
      echo "hello_rc=$?" >> "$LOG"
    else
      echo "hello_rc=127" >> "$LOG"
    fi

    if [ -x "$XPR_ROOT/bin/python3.5" ]; then
      PYTHONHOME="$XPR_ROOT" PYTHONPATH="$XPR_ROOT/python/python3.5" \
        "$XPR_ROOT/bin/python3.5" -S "$XPR_ROOT/share/python-core-stage2.py" \
        > "$LOG_DIR/python-core.out" 2>&1
      echo "python_rc=$?" >> "$LOG"
    else
      echo "python_rc=127" >> "$LOG"
    fi
    echo "[stage2] done" >> "$LOG"
    ;;
  stop)
    echo "[stage2] stop" >> "$LOG" 2>/dev/null || true
    ;;
esac
exit 0
INIT
chmod 0755 "$data_dir/etc/init.d/xeon-phi-revival-stage2"
ln -s ../init.d/xeon-phi-revival-stage2 "$data_dir/etc/rc5.d/S78xeon-phi-revival-stage2"

installed_size="$(du -sk "$data_dir" | awk '{print $1}')"
cat > "$control_dir/control" <<EOF
Package: $package
Version: $version
Architecture: $arch
Maintainer: Xeon Phi Revival Project
Installed-Size: $installed_size
Section: base
Priority: optional
Depends:
Description: Project uOS profile for Intel Xeon Phi K1OM
 Installs the reversible Xeon Phi Revival Project second-stage profile layout
 under /opt/xeon-phi-revival, with a SysV rc5 service hook. This package is a
 bootstrap artifact for local K1OM port experiments and must be built from
 locally supplied K1OM payloads.
EOF

(cd "$control_dir" && tar --numeric-owner --owner=0 --group=0 -czf "$pkg_dir/control.tar.gz" .)
(cd "$data_dir" && tar --numeric-owner --owner=0 --group=0 -czf "$pkg_dir/data.tar.gz" .)
printf '2.0\n' > "$pkg_dir/debian-binary"

if command -v ar >/dev/null 2>&1; then
  rm -f "$deb_path"
  (cd "$pkg_dir" && ar rcs "$deb_path" debian-binary control.tar.gz data.tar.gz)
else
  echo "ar not found; cannot create .deb archive" >&2
  exit 11
fi

{
  printf 'path\ttype\tmode\tsize\tsha256\tlink_target\n'
  while IFS= read -r -d '' path; do
    rel="/${path#"$data_dir"/}"
    if [[ -L "$path" ]]; then
      printf '%s\tsymlink\t%s\t0\t\t%s\n' "$rel" "$(stat -c '%a' "$path")" "$(readlink "$path")"
    elif [[ -d "$path" ]]; then
      printf '%s\tdirectory\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path")"
    elif [[ -f "$path" ]]; then
      printf '%s\tfile\t%s\t%s\t%s\t\n' "$rel" "$(stat -c '%a' "$path")" "$(stat -c '%s' "$path")" "$(sha256sum "$path" | awk '{print $1}')"
    fi
  done < <(find "$data_dir" -mindepth 1 -print0 | sort -z)
} > "$manifest"

echo "deb=$deb_path"
echo "manifest=$manifest"
sha256sum "$deb_path"
