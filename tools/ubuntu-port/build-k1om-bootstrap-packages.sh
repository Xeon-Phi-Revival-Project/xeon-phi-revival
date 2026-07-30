#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-k1om-bootstrap-packages.sh --payload-rootfs DIR --out-dir DIR [--sysroot DIR] [--libc-root DIR] [--runtime-root DIR] [--python312-root DIR] [--libffi-root DIR] [--version V]

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
  dpkg-k1om
  apt-k1om
  libc6-k1om
  libgcc1-k1om
  libm6-k1om
  libpthread0-k1om
  libdl2-k1om
  librt1-k1om
  libutil1-k1om
  libc-stack-smoke-k1om
  zlib1g-k1om
  libncurses5-k1om
  libreadline6-k1om
  libssl1.0.0-k1om
  libcrypto1.0.0-k1om
  libffi8-k1om
  xpr-runtime-libs-smoke
  ncurses-base-k1om
  python3.12-minimal-k1om
  python3.12-stdlib-k1om
  python3.12-sysconfig-k1om
  python3.12-smoke-k1om
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
sysroot="${K1OM_SYSROOT:-/opt/mpss/3.4.10/sysroots/k1om-mpss-linux}"
libc_root="${K1OM_LIBC_ROOT:-$sysroot}"
runtime_root="${K1OM_RUNTIME_ROOT:-}"
python312_root="${K1OM_PYTHON312_ROOT:-}"
libffi_root="${K1OM_LIBFFI_ROOT:-}"
version="0.1.0"
arch="k1om"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --payload-rootfs) payload_rootfs="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --sysroot) sysroot="${2:-}"; shift 2 ;;
    --libc-root) libc_root="${2:-}"; shift 2 ;;
    --runtime-root) runtime_root="${2:-}"; shift 2 ;;
    --python312-root) python312_root="${2:-}"; shift 2 ;;
    --libffi-root) libffi_root="${2:-}"; shift 2 ;;
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

for path in \
  "$sysroot/lib64/libgcc_s.so.1"; do
  [[ -e "$path" || -L "$path" ]] || { echo "required sysroot path missing: $path" >&2; exit 11; }
done

if [[ -e "$libc_root/lib64/ld-linux-k1om.so.2" || -L "$libc_root/lib64/ld-linux-k1om.so.2" ]]; then
  libc_libdir="$libc_root/lib64"
elif [[ -e "$libc_root/lib/ld-linux-k1om.so.2" || -L "$libc_root/lib/ld-linux-k1om.so.2" ]]; then
  libc_libdir="$libc_root/lib"
else
  echo "libc root does not contain ld-linux-k1om.so.2 under lib64 or lib: $libc_root" >&2
  exit 21
fi

for path in \
  "$libc_libdir/ld-linux-k1om.so.2" \
  "$libc_libdir/libc.so.6" \
  "$sysroot/lib64/libm.so.6" \
  "$sysroot/lib64/libpthread.so.0" \
  "$sysroot/lib64/libdl.so.2" \
  "$sysroot/lib64/librt.so.1" \
  "$sysroot/lib64/libutil.so.1"; do
  [[ -e "$path" || -L "$path" ]] || { echo "required sysroot path missing: $path" >&2; exit 11; }
done

for path in \
  "$libc_libdir/libm.so.6" \
  "$libc_libdir/libpthread.so.0" \
  "$libc_libdir/libdl.so.2" \
  "$libc_libdir/librt.so.1" \
  "$libc_libdir/libutil.so.1" \
  "$libc_libdir/libanl.so.1" \
  "$libc_libdir/libnsl.so.1" \
  "$libc_libdir/libnss_files.so.2" \
  "$libc_libdir/libnss_dns.so.2" \
  "$libc_libdir/libresolv.so.2"; do
  [[ -e "$path" || -L "$path" ]] || { echo "required libc-root path missing: $path" >&2; exit 21; }
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

find_terminfo_linux() {
  local candidate
  for candidate in \
    "$payload_rootfs/usr/share/terminfo/l/linux" \
    "$payload_rootfs/etc/terminfo/l/linux" \
    "${runtime_root:+$runtime_root/usr/share/terminfo/l/linux}" \
    "${runtime_root:+$runtime_root/etc/terminfo/l/linux}" \
    "$sysroot/usr/share/terminfo/l/linux" \
    "$sysroot/etc/terminfo/l/linux"; do
    [[ -n "$candidate" && -e "$candidate" ]] && { printf '%s\n' "$candidate"; return 0; }
  done
  return 1
}

copy_lib64() {
  local data_dir="$1"
  shift
  mkdir -p "$data_dir/opt/xeon-phi-revival/lib64"
  for rel in "$@"; do
    cp -a "$sysroot/lib64/$rel" "$data_dir/opt/xeon-phi-revival/lib64/$rel"
  done
}

libc_impl() {
  local stem="$1"
  local match
  match="$(find "$libc_libdir" -maxdepth 1 -type f -name "${stem}-*.so" | LC_ALL=C sort | tail -1)"
  [[ -n "$match" ]] || { echo "required libc-root implementation missing: $libc_libdir/${stem}-*.so" >&2; exit 22; }
  basename "$match"
}

copy_libc64() {
  local data_dir="$1"
  shift
  mkdir -p "$data_dir/opt/xeon-phi-revival/lib64"
  for rel in "$@"; do
    cp -a "$libc_libdir/$rel" "$data_dir/opt/xeon-phi-revival/lib64/$rel"
  done
}

copy_runtime_lib64() {
  local data_dir="$1"
  shift
  mkdir -p "$data_dir/opt/xeon-phi-revival/lib64"
  for rel in "$@"; do
    cp -a "$runtime_root/$rel" "$data_dir/opt/xeon-phi-revival/lib64/$(basename "$rel")"
  done
}

runtime_has() {
  local rel="$1"
  [[ -n "$runtime_root" && ( -e "$runtime_root/$rel" || -L "$runtime_root/$rel" ) ]]
}

runtime_required=0
if [[ -n "$runtime_root" ]]; then
  [[ -d "$runtime_root" ]] || { echo "runtime root is not a directory: $runtime_root" >&2; exit 12; }
  for path in \
    usr/lib64/libz.so.1 \
    usr/lib64/libz.so.1.2.6 \
    lib64/libncurses.so.5 \
    lib64/libncurses.so.5.9 \
    usr/lib64/libreadline.so.6 \
    usr/lib64/libreadline.so.6.2 \
    usr/lib64/libssl.so.1.0.0 \
    lib64/libcrypto.so.1.0.0; do
    runtime_has "$path" || { echo "required runtime-root path missing: $runtime_root/$path" >&2; exit 13; }
  done
  runtime_required=1
fi

python312_required=0
if [[ -n "$python312_root" ]]; then
  [[ -d "$python312_root" ]] || { echo "python312 root is not a directory: $python312_root" >&2; exit 14; }
  for path in \
    python \
    Lib/encodings \
    Lib/importlib \
    Lib/json \
    Lib/asyncio \
    Lib/xml \
    Lib/zoneinfo \
    Lib/sysconfig.py; do
    [[ -e "$python312_root/$path" || -L "$python312_root/$path" ]] || { echo "required python312-root path missing: $python312_root/$path" >&2; exit 15; }
  done
  if ! readelf -h "$python312_root/python" 2>/dev/null | grep -q 'Machine:.*Intel K1OM'; then
    echo "python312-root/python is not an Intel K1OM ELF" >&2
    exit 16
  fi
  python312_required=1
fi

libffi_required=0
libffi_shared=""
if [[ -n "$libffi_root" ]]; then
  [[ -d "$libffi_root" ]] || { echo "libffi root is not a directory: $libffi_root" >&2; exit 18; }
  libffi_shared="$(find "$libffi_root" -maxdepth 1 -type f -name 'libffi.so.8.*' | LC_ALL=C sort | head -1)"
  [[ -n "$libffi_shared" ]] || { echo "libffi.so.8 implementation missing under: $libffi_root" >&2; exit 19; }
  if ! readelf -h "$libffi_shared" 2>/dev/null | grep -q 'Machine:.*Intel K1OM'; then
    echo "libffi shared library is not an Intel K1OM ELF: $libffi_shared" >&2
    exit 20
  fi
  libffi_required=1
fi

base_data="$(new_data_dir base-files-k1om)"
mkdir -p \
  "$base_data/opt/xeon-phi-revival/bin" \
  "$base_data/opt/xeon-phi-revival/lib" \
  "$base_data/opt/xeon-phi-revival/python" \
  "$base_data/opt/xeon-phi-revival/share" \
  "$base_data/var/log/xeon-phi-revival" \
  "$base_data/etc" \
  "$base_data/usr/bin"
cat > "$base_data/opt/xeon-phi-revival/profile.env" <<EOF
XPR_PROFILE_VERSION=$version
XPR_PROFILE_KIND=xpr-uos-0.1-k1om-rc
XPR_PHASE=release-candidate
XPR_ROOT=/opt/xeon-phi-revival
EOF
cat > "$base_data/etc/xeon-phi-revival-release" <<EOF
NAME="Xeon Phi Revival uOS"
VERSION="$version"
ARCH="$arch"
BASE="stock MPSS uOS"
UBUNTU_SUITE="noble"
UBUNTU_VERSION="24.04"
PORT_STATUS="unofficial Ubuntu-derived release candidate"
EOF
cat > "$base_data/etc/os-release" <<'EOF'
NAME="Xeon Phi Revival uOS"
PRETTY_NAME="Xeon Phi Revival Ubuntu-derived K1OM uOS"
ID=xpr-uos
ID_LIKE=ubuntu
VERSION_ID="0.1"
VERSION="0.1 release candidate"
VERSION_CODENAME=noble
ARCHITECTURE="k1om"
HOME_URL="https://github.com/Xeon-Phi-Revival-Project"
SUPPORT_URL="https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival"
BUG_REPORT_URL="https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/issues"
XPR_ARCH=k1om
XPR_DERIVED_FROM="Ubuntu 24.04 Noble source/package metadata"
XPR_PORT_STATUS="unofficial release candidate; not endorsed by Intel, Canonical, or Ubuntu"
EOF
cat > "$base_data/etc/lsb-release" <<'EOF'
DISTRIB_ID=Xeon Phi Revival uOS
DISTRIB_RELEASE=0.1
DISTRIB_CODENAME=noble
DISTRIB_DESCRIPTION="Xeon Phi Revival Ubuntu-derived K1OM uOS"
EOF
cat > "$base_data/etc/debian_version" <<'EOF'
xpr-uos 0.1 noble-derived
EOF
cat > "$base_data/etc/issue" <<'EOF'
Xeon Phi Revival Ubuntu-derived K1OM uOS 0.1 \n \l
EOF
cat > "$base_data/etc/motd" <<'EOF'
Xeon Phi Revival Project
Unofficial Ubuntu-derived K1OM uOS release candidate for Knights Corner.
EOF
cat > "$base_data/usr/bin/lsb_release" <<'LSBRELEASE'
#!/bin/sh
short=0
field=all
while [ "$#" -gt 0 ]; do
  case "$1" in
    -s|--short) short=1 ;;
    -i|--id) field=id ;;
    -r|--release) field=release ;;
    -c|--codename) field=codename ;;
    -d|--description) field=description ;;
    -a|--all) field=all ;;
    -h|--help)
      echo "Usage: lsb_release [-a] [-s] [-i|-d|-r|-c]"
      exit 0
      ;;
    *) echo "lsb_release: unsupported option: $1" >&2; exit 2 ;;
  esac
  shift
done

emit() {
  label="$1"
  value="$2"
  if [ "$short" -eq 1 ]; then
    printf '%s\n' "$value"
  else
    printf '%s:\t%s\n' "$label" "$value"
  fi
}

case "$field" in
  id) emit "Distributor ID" "Xeon Phi Revival uOS" ;;
  release) emit "Release" "0.1" ;;
  codename) emit "Codename" "noble" ;;
  description) emit "Description" "Xeon Phi Revival Ubuntu-derived K1OM uOS" ;;
  all)
    emit "Distributor ID" "Xeon Phi Revival uOS"
    emit "Description" "Xeon Phi Revival Ubuntu-derived K1OM uOS"
    emit "Release" "0.1"
    emit "Codename" "noble"
    ;;
esac
LSBRELEASE
chmod 0755 "$base_data/usr/bin/lsb_release"

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
export LD_LIBRARY_PATH="$XPR_ROOT/lib64:${LD_LIBRARY_PATH:-}"
if [ -x "$XPR_ROOT/bin/python3.12" ]; then
  export PYTHONPATH="$XPR_ROOT/lib/python3.12"
  if [ "${XPR_PYTHON_ENABLE_SITE:-0}" = "1" ]; then
    exec "$XPR_ROOT/bin/python3.12" "$@"
  fi
  exec "$XPR_ROOT/bin/python3.12" -S "$@"
fi
export PYTHONPATH="$XPR_ROOT/lib/python3.5:$XPR_ROOT/lib/python3.5/lib-dynload"
if [ "${XPR_PYTHON_ENABLE_SITE:-0}" = "1" ]; then
  exec "$XPR_ROOT/bin/python3.5" "$@"
fi
exec "$XPR_ROOT/bin/python3.5" -S "$@"
PYWRAP
chmod 0755 "$shell_compat_data/usr/bin/python3"
ln -s python3 "$shell_compat_data/usr/bin/python"
ln -s ../../../usr/bin/python3 "$shell_compat_data/opt/xeon-phi-revival/bin/python3"
ln -s ../../../usr/bin/python3 "$shell_compat_data/opt/xeon-phi-revival/bin/python"

python312_minimal_data=""
python312_stdlib_data=""
python312_sysconfig_data=""
python312_smoke_data=""
if [[ "$python312_required" -eq 1 ]]; then
  python312_minimal_data="$(new_data_dir python3.12-minimal-k1om)"
  mkdir -p "$python312_minimal_data/opt/xeon-phi-revival/bin" "$python312_minimal_data/usr/bin"
  cp -a "$python312_root/python" "$python312_minimal_data/opt/xeon-phi-revival/bin/python3.12"
  cat > "$python312_minimal_data/usr/bin/python3.12" <<'PY312WRAP'
#!/bin/sh
XPR_ROOT=/opt/xeon-phi-revival
export LD_LIBRARY_PATH="$XPR_ROOT/lib64:${LD_LIBRARY_PATH:-}"
export PYTHONHOME="$XPR_ROOT"
export PYTHONPATH="$XPR_ROOT/lib/python3.12"
exec "$XPR_ROOT/bin/python3.12" -S "$@"
PY312WRAP
  chmod 0755 "$python312_minimal_data/usr/bin/python3.12"
  python312_stdlib_data="$(new_data_dir python3.12-stdlib-k1om)"
  mkdir -p "$python312_stdlib_data/opt/xeon-phi-revival/lib/python3.12"
  tar -C "$python312_root/Lib" \
    --exclude='test' \
    --exclude='idlelib' \
    --exclude='tkinter' \
    --exclude='turtledemo' \
    --exclude='ensurepip/_bundled' \
    --exclude='__pycache__' \
    -cf - . | tar -C "$python312_stdlib_data/opt/xeon-phi-revival/lib/python3.12" -xf -

  python312_sysconfig_data="$(new_data_dir python3.12-sysconfig-k1om)"
  mkdir -p "$python312_sysconfig_data/opt/xeon-phi-revival/lib/python3.12"
  cat > "$python312_sysconfig_data/opt/xeon-phi-revival/lib/python3.12/_sysconfigdata__linux_x86_64-linux-gnu.py" <<'PY312CFG'
build_time_vars = {
    'TZPATH': '/usr/share/zoneinfo:/usr/lib/zoneinfo:/usr/share/lib/zoneinfo:/etc/zoneinfo',
    'MULTIARCH': 'k1om-linux-gnu',
    'SOABI': 'cpython-312-k1om-linux-gnu',
    'EXT_SUFFIX': '.cpython-312-k1om-linux-gnu.so',
    'CC': 'k1om-mpss-linux-gcc',
    'HOST_GNU_TYPE': 'k1om-mpss-linux-gnu',
    'BUILD_GNU_TYPE': 'x86_64-pc-linux-gnu',
}
PY312CFG

  python312_smoke_data="$(new_data_dir python3.12-smoke-k1om)"
  mkdir -p "$python312_smoke_data/opt/xeon-phi-revival/share" "$python312_smoke_data/opt/xeon-phi-revival/bin"
  cat > "$python312_smoke_data/opt/xeon-phi-revival/share/python312-smoke.py" <<'PY312SMOKE'
import sys, os, math, json, pathlib, hashlib, threading, decimal, socket, struct, datetime, array, binascii, unicodedata, xml.parsers.expat, zlib
import csv, pickle, random, queue, statistics, xml.etree.ElementTree as ET, zoneinfo, asyncio, contextvars, sysconfig
print("python312_package_smoke_ok")
print(sys.version.split()[0])
print(sys.platform)
print(os.uname().machine)
print(math.factorial(6))
print(decimal.Decimal("1.5") + decimal.Decimal("2.25"))
print(json.dumps({"k1om": True}, sort_keys=True))
print(hashlib.sha256(b"xeon-phi").hexdigest()[:16])
print(zlib.decompress(zlib.compress(b"knc-zlib")).decode())
print(pickle.loads(pickle.dumps({"a": [1, 2, 3]}))["a"][2])
print(next(csv.reader(["a,b"]))[1])
print(random.Random(7).randint(1, 9))
q = queue.Queue(); q.put("qok"); print(q.get())
print(statistics.mean([1, 2, 6]))
print(ET.fromstring("<r><x>ok</x></r>").find("x").text)
print(zoneinfo.ZoneInfo is not None)
print(sysconfig.get_config_var("SOABI"))
print(asyncio.new_event_loop is not None)
print(contextvars.ContextVar("x").name)
print(socket.AF_INET)
print(struct.pack(">H", 513).hex())
print(datetime.date(2026, 7, 29).isoformat())
print(array.array("i", [1, 2, 3]).tolist())
print(binascii.hexlify("Phi".encode()).decode())
print(unicodedata.name("A"))
print(xml.parsers.expat.ParserCreate is not None)
t = threading.Thread(target=lambda: None)
t.start(); t.join()
print(pathlib.PurePosixPath("/opt/xeon-phi-revival").name)
optional_results = []
try:
    import bz2
    optional_results.append("bz2=" + bz2.decompress(bz2.compress(b"bz-ok")).decode())
except Exception as exc:
    optional_results.append("bz2=fail:%s:%s" % (exc.__class__.__name__, exc))
try:
    import lzma
    optional_results.append("lzma=" + lzma.decompress(lzma.compress(b"lzma-ok")).decode())
except Exception as exc:
    optional_results.append("lzma=fail:%s:%s" % (exc.__class__.__name__, exc))
try:
    import readline
    optional_results.append("readline=%s" % (readline.__doc__ is not None))
except Exception as exc:
    optional_results.append("readline=fail:%s:%s" % (exc.__class__.__name__, exc))
try:
    import sqlite3
    con = sqlite3.connect(":memory:")
    con.execute("create table t(x)")
    con.execute("insert into t values (?)", (42,))
    optional_results.append("sqlite3=%s:%s" % (con.execute("select x from t").fetchone()[0], sqlite3.sqlite_version))
except Exception as exc:
    optional_results.append("sqlite3=fail:%s:%s" % (exc.__class__.__name__, exc))
try:
    import curses
    import curses.panel
    os.environ.setdefault("TERM", "linux")
    curses.setupterm(term=os.environ["TERM"])
    optional_results.append("curses=%s" % getattr(curses, "version", b"unknown").decode("ascii", "replace"))
    optional_results.append("curses_panel=%s" % (curses.panel.__name__ == "curses.panel"))
    optional_results.append("curses_cols=%s" % curses.tigetnum("cols"))
    optional_results.append("curses_lines=%s" % curses.tigetnum("lines"))
except Exception as exc:
    optional_results.append("curses=fail:%s:%s" % (exc.__class__.__name__, exc))
try:
    import ssl
    optional_results.append("ssl=%s" % ssl.OPENSSL_VERSION)
except Exception as exc:
    optional_results.append("ssl=fail:%s:%s" % (exc.__class__.__name__, exc))
try:
    import _hashlib
    optional_results.append("hashlib_openssl=%s" % _hashlib.openssl_sha256(b"x").hexdigest()[:8])
except Exception as exc:
    optional_results.append("hashlib_openssl=fail:%s:%s" % (exc.__class__.__name__, exc))
try:
    import ctypes
    optional_results.append("ctypes_ptr=%s" % ctypes.sizeof(ctypes.c_void_p))
    libc = ctypes.CDLL(None)
    strlen = libc.strlen
    strlen.argtypes = [ctypes.c_char_p]
    strlen.restype = ctypes.c_size_t
    optional_results.append("ctypes_strlen=%s" % strlen(b"phi"))
    callback_type = ctypes.CFUNCTYPE(ctypes.c_int, ctypes.c_int, ctypes.c_int)
    callback = callback_type(lambda left, right: left + right)
    optional_results.append("ctypes_callback=%s" % callback(19, 23))
except Exception as exc:
    optional_results.append("ctypes=fail:%s:%s" % (exc.__class__.__name__, exc))
for result in optional_results:
    print(result)
required_optional_prefixes = ("ctypes=",)
if any(result.startswith(prefix) and "=fail:" in result
       for prefix in required_optional_prefixes
       for result in optional_results):
    raise SystemExit(70)
PY312SMOKE
  cat > "$python312_smoke_data/opt/xeon-phi-revival/bin/python312-smoke.sh" <<'PY312RUN'
#!/bin/sh
set -u
XPR_ROOT=${XPR_ROOT:-/opt/xeon-phi-revival}
LOG_DIR=/var/log/xeon-phi-revival
OUT="$LOG_DIR/python312-smoke.out"
mkdir -p "$LOG_DIR"
PYTHONHOME="$XPR_ROOT" PYTHONPATH="$XPR_ROOT/lib/python3.12" \
  "$XPR_ROOT/bin/python3.12" -S "$XPR_ROOT/share/python312-smoke.py" > "$OUT" 2>&1
PY312RUN
  chmod 0755 "$python312_smoke_data/opt/xeon-phi-revival/bin/python312-smoke.sh"
fi

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

dpkg_data="$(new_data_dir dpkg-k1om)"
mkdir -p "$dpkg_data/usr/bin" "$dpkg_data/opt/xeon-phi-revival/bin" "$dpkg_data/var/lib/dpkg/info" "$dpkg_data/etc/dpkg"
cat > "$dpkg_data/etc/dpkg/dpkg.cfg" <<'DPKGCFG'
# Bootstrap dpkg-k1om configuration.
# This project implementation is intentionally limited to local K1OM package
# query and install operations used by the Xeon Phi Revival profile.
DPKGCFG
cat > "$dpkg_data/usr/bin/dpkg" <<'DPKG'
#!/bin/sh
set -u
STATUS=${DPKG_STATUS:-/var/lib/dpkg/status}
INFO=${DPKG_INFO:-/var/lib/dpkg/info}

usage() {
  echo "usage: dpkg [--version|--print-architecture|--audit|--get-selections|-l|-s PKG|-L PKG|-S PATH|-W [PKG...]|-I DEB|-c DEB|-i DEB...]" >&2
}

status_has_package() {
  local pkg="$1"
  awk -v p="$pkg" '
    $1 == "Package:" && $2 == p { found=1 }
    END { exit found ? 0 : 1 }
  ' "$STATUS" 2>/dev/null
}

dep_name() {
  local dep_text="$1"
  printf '%s\n' "$dep_text" | tr -d '\r' | sed 's/^ *//; s/ *$//; s/|.*//; s/ *(.*//; s/ *$//'
}

check_dependencies() {
  local pkg="$1"
  local control="$2"
  local depends old_ifs dep_part dep
  depends="$(printf '%s\n' "$control" | tr -d '\r' | awk -F': ' '$1 == "Depends" { print $2; exit }')"
  [ -n "$depends" ] || return 0
  old_ifs="$IFS"
  IFS=','
  for dep_part in $depends; do
    dep="$(dep_name "$dep_part")"
    [ -n "$dep" ] || continue
    [ "$dep" = "$pkg" ] && continue
    if ! status_has_package "$dep"; then
      IFS="$old_ifs"
      echo "dpkg: dependency problem prevents configuration of $pkg: $dep is not installed" >&2
      return 1
    fi
  done
  IFS="$old_ifs"
}

check_file_conflicts() {
  local conflict_pkg="$1"
  local data_tar="$2"
  local pkg_owner same_package_list
  pkg_owner="$(printf '%s\n' "$conflict_pkg" | tr -d '\r' | sed 's/^ *//; s/ *$//')"
  same_package_list="$INFO/$pkg_owner.list"
  tar -tzf "$data_tar" | sed 's#^\./#/#' | grep -v '/$' | while IFS= read -r path; do
    [ -n "$path" ] || continue
    if [ -f "$same_package_list" ] && awk -v p="$path" '$0 == p { found=1; exit } END { exit found ? 0 : 1 }' "$same_package_list"; then
      continue
    fi
    for list in "$INFO"/*.list; do
      [ -f "$list" ] || continue
      [ "$list" = "$same_package_list" ] && continue
      owner="${list##*/}"
      owner="${owner%.list}"
      owner="$(printf '%s\n' "$owner" | tr -d '\r' | sed 's/^ *//; s/ *$//')"
      [ "$owner" = "$pkg_owner" ] && continue
      if awk -v p="$path" '$0 == p { found=1; exit } END { exit found ? 0 : 1 }' "$list"; then
        echo "dpkg: file ownership conflict: $path is already owned by $owner" >&2
        exit 1
      fi
    done
  done
}

print_package_paragraph() {
  local pkg="$1"
  awk -v p="$pkg" '
    BEGIN { keep=0; matched=0; buf="" }
    function flush() {
      if (keep) {
        print buf
        print ""
        matched=1
      }
      keep=0
      buf=""
    }
    $0 == "" { flush(); next }
    $1 == "Package:" && $2 == p { keep=1 }
    { buf = (buf == "" ? $0 : buf "\n" $0) }
    END { flush(); exit matched ? 0 : 1 }
  ' "$STATUS"
}

remove_package_paragraph() {
  local pkg="$1"
  local src="$2"
  local dst="$3"
  awk -v p="$pkg" '
    BEGIN { drop=0; buf="" }
    function flush() {
      if (!drop && buf != "") {
        print buf
        print ""
      }
      drop=0
      buf=""
    }
    $0 == "" { flush(); next }
    $1 == "Package:" && $2 == p { drop=1 }
    { buf = (buf == "" ? $0 : buf "\n" $0) }
    END { flush() }
  ' "$src" > "$dst"
}

list_packages() {
  printf 'Desired=Unknown/Install/Remove/Purge/Hold\n'
  printf '| Status=Not/Installed/Config-files/Unpacked\n'
  printf '||/ Name                           Version              Architecture\n'
  awk '
    $1 == "Package:" { pkg=$2 }
    $1 == "Version:" { ver=$2 }
    $1 == "Architecture:" { arch=$2 }
    $0 == "" && pkg != "" {
      printf "ii  %-30s %-20s %s\n", pkg, ver, arch
      pkg=ver=arch=""
    }
    END {
      if (pkg != "") printf "ii  %-30s %-20s %s\n", pkg, ver, arch
    }
  ' "$STATUS" 2>/dev/null
}

show_packages() {
  if [ $# -eq 0 ]; then
    awk '
      $1 == "Package:" { pkg=$2 }
      $1 == "Version:" { ver=$2 }
      $0 == "" && pkg != "" {
        printf "%s\t%s\n", pkg, ver
        pkg=ver=""
      }
      END {
        if (pkg != "") printf "%s\t%s\n", pkg, ver
      }
    ' "$STATUS" 2>/dev/null
    return 0
  fi
  for query_pkg in "$@"; do
    print_package_paragraph "$query_pkg" | awk -v p="$query_pkg" '
      $1 == "Package:" { pkg=$2 }
      $1 == "Version:" { ver=$2 }
      END {
        if (pkg != "") printf "%s\t%s\n", pkg, ver
        else {
          printf "dpkg-query: no packages found matching %s\n", p > "/dev/stderr"
          exit 1
        }
      }
    ' || return 1
  done
}

deb_tempdir() {
  local deb="$1"
  local tmp="/tmp/xpr-dpkg-info.$$.$(basename "$deb" | sed 's/[^A-Za-z0-9_.-]/_/g')"
  rm -rf "$tmp"
  mkdir -p "$tmp"
  if ! extract_deb_members "$deb" "$tmp"; then
    rm -rf "$tmp"
    return 2
  fi
  printf '%s\n' "$tmp"
}

print_deb_info() {
  local deb="$1"
  local tmp
  [ -f "$deb" ] || { echo "dpkg: package file not found: $deb" >&2; return 2; }
  tmp="$(deb_tempdir "$deb")" || return $?
  echo " new Debian package, version 2.0."
  echo " size $(wc -c < "$deb") bytes: control archive=$(wc -c < "$tmp/control.tar.gz") bytes."
  tar -xOzf "$tmp/control.tar.gz" ./control
  rm -rf "$tmp"
}

list_deb_contents() {
  local deb="$1"
  local tmp
  [ -f "$deb" ] || { echo "dpkg: package file not found: $deb" >&2; return 2; }
  tmp="$(deb_tempdir "$deb")" || return $?
  tar -tzvf "$tmp/data.tar.gz"
  rm -rf "$tmp"
}

extract_deb_payload() {
  local deb="$1"
  local dest="$2"
  local tmp
  [ -f "$deb" ] || { echo "dpkg-deb: package file not found: $deb" >&2; return 2; }
  mkdir -p "$dest"
  tmp="$(deb_tempdir "$deb")" || return $?
  tar -xzf "$tmp/data.tar.gz" -C "$dest"
  rm -rf "$tmp"
}

extract_deb_control() {
  local deb="$1"
  local dest="$2"
  local tmp
  [ -f "$deb" ] || { echo "dpkg-deb: package file not found: $deb" >&2; return 2; }
  mkdir -p "$dest"
  tmp="$(deb_tempdir "$deb")" || return $?
  tar -xzf "$tmp/control.tar.gz" -C "$dest"
  rm -rf "$tmp"
}

print_deb_field() {
  local deb="$1"
  local field="${2:-}"
  local tmp rc
  [ -f "$deb" ] || { echo "dpkg-deb: package file not found: $deb" >&2; return 2; }
  tmp="$(deb_tempdir "$deb")" || return $?
  if [ -n "$field" ]; then
    tar -xOzf "$tmp/control.tar.gz" ./control | awk -F': ' -v f="$field" '$1 == f { print $2; found=1 } END { exit found ? 0 : 1 }'
  else
    tar -xOzf "$tmp/control.tar.gz" ./control
  fi
  rc=$?
  rm -rf "$tmp"
  return "$rc"
}

install_deb() {
  local deb="$1"
  local tmp control pkg already_installed tmp_status
  [ -f "$deb" ] || { echo "dpkg: package file not found: $deb" >&2; return 2; }
  tmp="/tmp/xpr-dpkg.$$.$(basename "$deb" | sed 's/[^A-Za-z0-9_.-]/_/g')"
  rm -rf "$tmp"
  mkdir -p "$tmp"
  if ! extract_deb_members "$deb" "$tmp"; then
    rm -rf "$tmp"
    return 2
  fi
  control="$(tar -xOzf "$tmp/control.tar.gz" ./control)" || { rm -rf "$tmp"; return 2; }
  pkg="$(printf '%s\n' "$control" | tr -d '\r' | awk -F': ' '$1 == "Package" { print $2; exit }')"
  [ -n "$pkg" ] || { echo "dpkg: missing Package field in $deb" >&2; rm -rf "$tmp"; return 2; }
  already_installed=0
  status_has_package "$pkg" && already_installed=1
  if ! check_dependencies "$pkg" "$control"; then
    rm -rf "$tmp"
    return 1
  fi
  if [ "$already_installed" -eq 0 ] && ! check_file_conflicts "$pkg" "$tmp/data.tar.gz"; then
    rm -rf "$tmp"
    return 1
  fi
  mkdir -p "$INFO" "$(dirname "$STATUS")"
  [ -f "$STATUS" ] || : > "$STATUS"
  tmp_status="$STATUS.tmp.$$"
  remove_package_paragraph "$pkg" "$STATUS" "$tmp_status"
  {
    printf '%s\n' "$control" | awk '{ print } /^Package:/ && !done { print "Status: install ok installed"; done=1 }'
    printf '\n'
  } >> "$tmp_status"
  mv "$tmp_status" "$STATUS"
  tar -tzf "$tmp/data.tar.gz" | sed 's#^\./#/#' | sort > "$INFO/$pkg.list"
  if tar -tzf "$tmp/control.tar.gz" | grep -q './md5sums'; then
    tar -xOzf "$tmp/control.tar.gz" ./md5sums > "$INFO/$pkg.md5sums"
  fi
  if tar -tzf "$tmp/control.tar.gz" | grep -q './conffiles'; then
    tar -xOzf "$tmp/control.tar.gz" ./conffiles > "$INFO/$pkg.conffiles"
  fi
  tar -xzf "$tmp/data.tar.gz" -C /
  rm -rf "$tmp"
  echo "Setting up $pkg (bootstrap dpkg-k1om)"
}

extract_deb_members() {
  deb="$1"
  out="$2"
  magic="$(dd if="$deb" bs=8 count=1 2>/dev/null)"
  [ "$magic" = "!<arch>" ] || { echo "dpkg: unsupported deb archive: $deb" >&2; return 2; }
  offset=8
  found_control=0
  found_data=0
  size_total="$(wc -c < "$deb")"
  while [ "$offset" -lt "$size_total" ]; do
    header="$out/ar-header.$$"
    dd if="$deb" of="$header" bs=1 skip="$offset" count=60 2>/dev/null
    name="$(dd if="$header" bs=1 count=16 2>/dev/null | sed 's/[ /]*$//')"
    size="$(dd if="$header" bs=1 skip=48 count=10 2>/dev/null | sed 's/ //g')"
    [ -n "$name" ] || break
    [ -n "$size" ] || break
    data_offset=$((offset + 60))
    case "$name" in
      control.tar.gz)
        dd if="$deb" of="$out/control.tar.gz" bs=1 skip="$data_offset" count="$size" 2>/dev/null
        found_control=1
        ;;
      data.tar.gz)
        dd if="$deb" of="$out/data.tar.gz" bs=1 skip="$data_offset" count="$size" 2>/dev/null
        found_data=1
        ;;
    esac
    pad=$((size % 2))
    offset=$((data_offset + size + pad))
  done
  rm -f "$out/ar-header.$$"
  [ "$found_control" -eq 1 ] && [ "$found_data" -eq 1 ] || {
    echo "dpkg: missing control.tar.gz or data.tar.gz in $deb" >&2
    return 2
  }
}

cmd="${1:---help}"
app="${0##*/}"
if [ "$app" = "dpkg-deb" ]; then
  case "$cmd" in
    --version)
      echo "Debian dpkg-deb bootstrap-compatible project implementation for k1om 0.1.0"
      ;;
    -I|--info)
      [ $# -ge 2 ] || { usage; exit 2; }
      print_deb_info "$2"
      ;;
    -c|--contents)
      [ $# -ge 2 ] || { usage; exit 2; }
      list_deb_contents "$2"
      ;;
    -f|--field)
      [ $# -ge 2 ] || { usage; exit 2; }
      print_deb_field "$2" "${3:-}"
      ;;
    -x|--extract)
      [ $# -ge 3 ] || { usage; exit 2; }
      extract_deb_payload "$2" "$3"
      ;;
    -e|--control)
      [ $# -ge 3 ] || { usage; exit 2; }
      extract_deb_control "$2" "$3"
      ;;
    --help|-h)
      usage
      ;;
    *)
      echo "dpkg-deb-k1om: unsupported option: $cmd" >&2
      usage
      exit 2
      ;;
  esac
  exit 0
fi
case "$cmd" in
  --version)
    echo "Debian dpkg bootstrap-compatible project implementation for k1om 0.1.0"
    ;;
  --print-architecture)
    echo "k1om"
    ;;
  --audit|-C)
    if [ ! -s "$STATUS" ]; then
      echo "dpkg: status database is empty or missing" >&2
      exit 1
    fi
    if awk '$1 == "Package:" { pkg=$2 } $1 == "Status:" && $2 " " $3 " " $4 != "install ok installed" { print pkg ": " $0; bad=1 } END { exit bad ? 1 : 0 }' "$STATUS"; then
      :
    else
      exit 1
    fi
    ;;
  --get-selections)
    awk '$1 == "Package:" { print $2 "\tinstall" }' "$STATUS" 2>/dev/null
    ;;
  -l|--list)
    list_packages
    ;;
  -W|--show)
    shift
    show_packages "$@"
    ;;
  -s|--status)
    [ $# -ge 2 ] || { usage; exit 2; }
    print_package_paragraph "$2"
    ;;
  -L|--listfiles)
    [ $# -ge 2 ] || { usage; exit 2; }
    [ -f "$INFO/$2.list" ] || { echo "dpkg-query: package '$2' is not installed" >&2; exit 1; }
    cat "$INFO/$2.list"
    ;;
  -S|--search)
    [ $# -ge 2 ] || { usage; exit 2; }
    found=1
    for list in "$INFO"/*.list; do
      [ -f "$list" ] || continue
      if grep -q "$2" "$list"; then
        pkg="${list##*/}"
        pkg="${pkg%.list}"
        echo "$pkg: $2"
        found=0
      fi
    done
    exit "$found"
    ;;
  -I|--info)
    [ $# -ge 2 ] || { usage; exit 2; }
    print_deb_info "$2"
    ;;
  -c|--contents)
    [ $# -ge 2 ] || { usage; exit 2; }
    list_deb_contents "$2"
    ;;
  -i|--install)
    shift
    [ $# -ge 1 ] || { usage; exit 2; }
    for deb in "$@"; do
      install_deb "$deb"
    done
    ;;
  --help|-h)
    usage
    ;;
  *)
    echo "dpkg-k1om: unsupported option: $cmd" >&2
    usage
    exit 2
    ;;
esac
DPKG
chmod 0755 "$dpkg_data/usr/bin/dpkg"
ln -s dpkg "$dpkg_data/usr/bin/dpkg-query"
ln -s dpkg "$dpkg_data/usr/bin/dpkg-deb"
ln -s ../../../usr/bin/dpkg "$dpkg_data/opt/xeon-phi-revival/bin/dpkg"
ln -s ../../../usr/bin/dpkg-query "$dpkg_data/opt/xeon-phi-revival/bin/dpkg-query"
ln -s ../../../usr/bin/dpkg-deb "$dpkg_data/opt/xeon-phi-revival/bin/dpkg-deb"

apt_data="$(new_data_dir apt-k1om)"
mkdir -p "$apt_data/usr/bin" "$apt_data/opt/xeon-phi-revival/bin" "$apt_data/etc/apt" "$apt_data/var/lib/apt/lists/partial" "$apt_data/var/cache/apt/archives/partial"
cat > "$apt_data/etc/apt/sources.list" <<'SOURCES'
deb [trusted=yes arch=k1om] file:/opt/xeon-phi-revival/repo noble main
SOURCES
cat > "$apt_data/usr/bin/apt-cache" <<'APTCACHE'
#!/bin/sh
set -u
LIST_DIR=${APT_LIST_DIR:-/var/lib/apt/lists}
REPO=${XPR_APT_REPO:-/opt/xeon-phi-revival/repo}

usage() {
  echo "usage: apt-cache [--version|show PKG|policy PKG|depends PKG|pkgnames [PREFIX]|search TERM]" >&2
}

packages_files() {
  for f in "$LIST_DIR"/*Packages "$REPO/dists/noble/main/binary-k1om/Packages"; do
    [ -f "$f" ] && echo "$f"
  done
}

show_package() {
  pkg="$1"
  found=1
  for f in $(packages_files); do
    awk -v p="$pkg" '
      BEGIN { keep=0; matched=0; buf="" }
      function flush() {
        if (keep) {
          print buf
          print ""
          matched=1
        }
        keep=0
        buf=""
      }
      $0 == "" { flush(); next }
      $1 == "Package:" && $2 == p { keep=1 }
      { buf = (buf == "" ? $0 : buf "\n" $0) }
      END { flush(); exit matched ? 0 : 1 }
    ' "$f" && found=0
  done
  return "$found"
}

package_names() {
  prefix="${1:-}"
  for f in $(packages_files); do
    awk -F': ' '$1 == "Package" { print $2 }' "$f"
  done | sort -u | awk -v p="$prefix" 'p == "" || index($0, p) == 1'
}

depends_package() {
  pkg="$1"
  if ! show_package "$pkg" >/tmp/xpr-apt-cache-show.$$ 2>/dev/null; then
    rm -f /tmp/xpr-apt-cache-show.$$
    return 1
  fi
  echo "$pkg"
  awk -F': ' '$1 == "Depends" { print $2 }' /tmp/xpr-apt-cache-show.$$ | tr ',' '\n' | sed 's/^ */  Depends: /; s/ *(.*//'
  rm -f /tmp/xpr-apt-cache-show.$$
}

search_packages() {
  term="$1"
  for f in $(packages_files); do
    awk -v t="$term" '
      BEGIN { pkg=""; desc="" }
      $1 == "Package:" { pkg=$2 }
      $1 == "Description:" { sub(/^Description: /, ""); desc=$0 }
      $0 == "" {
        if (pkg != "" && (index(pkg, t) || index(desc, t))) print pkg " - " desc
        pkg=desc=""
      }
      END {
        if (pkg != "" && (index(pkg, t) || index(desc, t))) print pkg " - " desc
      }
    ' "$f"
  done | sort -u
}

case "${1:---help}" in
  --version)
    echo "apt-cache bootstrap-compatible project implementation for k1om 0.1.0"
    ;;
  show)
    [ $# -ge 2 ] || { usage; exit 2; }
    show_package "$2"
    ;;
  policy)
    [ $# -ge 2 ] || { usage; exit 2; }
    echo "$2:"
    echo "  Installed: $(dpkg -s "$2" 2>/dev/null | awk -F': ' '$1 == "Version" { print $2; exit }')"
    echo "  Candidate: $(apt-cache show "$2" 2>/dev/null | awk -F': ' '$1 == "Version" { print $2; exit }')"
    ;;
  depends)
    [ $# -ge 2 ] || { usage; exit 2; }
    depends_package "$2"
    ;;
  pkgnames)
    package_names "${2:-}"
    ;;
  search)
    [ $# -ge 2 ] || { usage; exit 2; }
    search_packages "$2"
    ;;
  --help|-h)
    usage
    ;;
  *)
    echo "apt-cache-k1om: unsupported command: $1" >&2
    usage
    exit 2
    ;;
esac
APTCACHE
chmod 0755 "$apt_data/usr/bin/apt-cache"
cat > "$apt_data/usr/bin/apt-get" <<'APTGET'
#!/bin/sh
set -u
REPO=${XPR_APT_REPO:-/opt/xeon-phi-revival/repo}
LIST_DIR=${APT_LIST_DIR:-/var/lib/apt/lists}

usage() {
  echo "usage: apt-get [--version|update|download PKG|install [--reinstall] PKG...]" >&2
}

packages_file="$REPO/dists/noble/main/binary-k1om/Packages"
list_file="$LIST_DIR/xpr_noble_main_binary-k1om_Packages"

find_filename() {
  local pkg="$1"
  awk -v p="$pkg" '
    BEGIN { keep=0 }
    $0 == "" { keep=0 }
    $1 == "Package:" && $2 == p { keep=1 }
    keep && $1 == "Filename:" { print $2; exit }
  ' "$packages_file"
}

depends_for() {
  local pkg="$1"
  awk -v p="$pkg" '
    BEGIN { keep=0 }
    $0 == "" { keep=0 }
    $1 == "Package:" && $2 == p { keep=1 }
    keep && $1 == "Depends:" {
      sub(/^Depends: /, "")
      print
      exit
    }
  ' "$packages_file"
}

dep_name() {
  local dep_text="$1"
  printf '%s\n' "$dep_text" | tr -d '\r' | sed 's/^ *//; s/ *$//; s/|.*//; s/ *(.*//; s/ *$//'
}

is_installed() {
  local pkg="$1"
  dpkg -s "$1" >/dev/null 2>&1
}

install_one() {
  local pkg="$1"
  local mark="/tmp/xpr-apt-installing-$pkg"
  local depends old_ifs dep_part dep filename deb rc
  if is_installed "$pkg" && [ "$reinstall" -eq 0 ]; then
    echo "$pkg is already the newest version."
    return 0
  fi
  if [ -e "$mark" ]; then
    echo "E: Dependency cycle while installing $pkg" >&2
    return 1
  fi
  : > "$mark"
  depends="$(depends_for "$pkg")"
  old_ifs="$IFS"
  IFS=','
  for dep_part in $depends; do
    dep="$(dep_name "$dep_part")"
    [ -n "$dep" ] || continue
    if ! is_installed "$dep"; then
      install_one "$dep" || { IFS="$old_ifs"; rm -f "$mark"; return 1; }
    fi
  done
  IFS="$old_ifs"
  filename="$(find_filename "$pkg")"
  [ -n "$filename" ] || { echo "E: Unable to locate package $pkg" >&2; rm -f "$mark"; return 1; }
  deb="$REPO/$filename"
  [ -f "$deb" ] || { echo "E: Package file missing: $deb" >&2; rm -f "$mark"; return 1; }
  echo "Installing $pkg from local k1om archive"
  dpkg -i "$deb" || { rc=$?; rm -f "$mark"; return "$rc"; }
  rm -f "$mark"
}

case "${1:---help}" in
  --version)
    echo "apt-get bootstrap-compatible project implementation for k1om 0.1.0"
    ;;
  update)
    [ -f "$packages_file" ] || { echo "apt-get: missing local Packages file: $packages_file" >&2; exit 1; }
    mkdir -p "$LIST_DIR/partial"
    cp "$packages_file" "$list_file"
    echo "Reading package lists... Done"
    ;;
  download)
    shift
    [ $# -ge 1 ] || { usage; exit 2; }
    [ -f "$packages_file" ] || { echo "apt-get: missing local Packages file: $packages_file" >&2; exit 1; }
    for pkg in "$@"; do
      filename="$(find_filename "$pkg")"
      [ -n "$filename" ] || { echo "E: Unable to locate package $pkg" >&2; exit 1; }
      deb="$REPO/$filename"
      [ -f "$deb" ] || { echo "E: Package file missing: $deb" >&2; exit 1; }
      cp "$deb" "./${deb##*/}"
      echo "Downloaded ${deb##*/}"
    done
    ;;
  install)
    shift
    reinstall=0
    assume_yes=0
    pkgs=""
    while [ $# -gt 0 ]; do
      case "$1" in
        --reinstall) reinstall=1 ;;
        -y|--yes|--assume-yes) assume_yes=1 ;;
        -*) echo "apt-get-k1om: unsupported install option: $1" >&2; exit 2 ;;
        *) pkgs="$pkgs $1" ;;
      esac
      shift
    done
    [ -n "$pkgs" ] || { usage; exit 2; }
    [ -f "$packages_file" ] || { echo "apt-get: missing local Packages file: $packages_file" >&2; exit 1; }
    rm -f /tmp/xpr-apt-installing-*
    for pkg in $pkgs; do
      install_one "$pkg" || exit $?
    done
    rm -f /tmp/xpr-apt-installing-*
    echo "install complete"
    ;;
  --help|-h)
    usage
    ;;
  *)
    echo "apt-get-k1om: unsupported command: $1" >&2
    usage
    exit 2
    ;;
esac
APTGET
chmod 0755 "$apt_data/usr/bin/apt-get"
ln -s ../../../usr/bin/apt-get "$apt_data/opt/xeon-phi-revival/bin/apt-get"
ln -s ../../../usr/bin/apt-cache "$apt_data/opt/xeon-phi-revival/bin/apt-cache"

libc_data="$(new_data_dir libc6-k1om)"
copy_libc64 "$libc_data" \
  ld-linux-k1om.so.2 "$(libc_impl ld)" \
  libc.so.6 "$(libc_impl libc)" \
  libanl.so.1 "$(libc_impl libanl)" \
  libnsl.so.1 "$(libc_impl libnsl)" \
  libnss_files.so.2 "$(libc_impl libnss_files)" \
  libnss_dns.so.2 "$(libc_impl libnss_dns)" \
  libresolv.so.2 "$(libc_impl libresolv)"

libgcc_data="$(new_data_dir libgcc1-k1om)"
copy_lib64 "$libgcc_data" libgcc_s.so.1
if [[ -e "$sysroot/lib64/libgcc_s.so" || -L "$sysroot/lib64/libgcc_s.so" ]]; then
  copy_lib64 "$libgcc_data" libgcc_s.so
fi

libm_data="$(new_data_dir libm6-k1om)"
copy_libc64 "$libm_data" libm.so.6 "$(libc_impl libm)"

libpthread_data="$(new_data_dir libpthread0-k1om)"
copy_libc64 "$libpthread_data" libpthread.so.0 "$(libc_impl libpthread)"

libdl_data="$(new_data_dir libdl2-k1om)"
copy_libc64 "$libdl_data" libdl.so.2 "$(libc_impl libdl)"

librt_data="$(new_data_dir librt1-k1om)"
copy_libc64 "$librt_data" librt.so.1 "$(libc_impl librt)"

libutil_data="$(new_data_dir libutil1-k1om)"
copy_libc64 "$libutil_data" libutil.so.1 "$(libc_impl libutil)"

libc_stack_smoke_data="$(new_data_dir libc-stack-smoke-k1om)"
mkdir -p "$libc_stack_smoke_data/opt/xeon-phi-revival/bin"
cat > "$libc_stack_smoke_data/opt/xeon-phi-revival/bin/libc-stack-smoke.sh" <<'LIBCSMOKE'
#!/bin/sh
set -u
XPR_ROOT=${XPR_ROOT:-/opt/xeon-phi-revival}
LOG_DIR=/var/log/xeon-phi-revival
OUT="$LOG_DIR/libc-stack-smoke.out"
LOADER="$XPR_ROOT/lib64/ld-linux-k1om.so.2"
LIBPATH="$XPR_ROOT/lib64"
mkdir -p "$LOG_DIR"
{
  echo "libc_stack_started=1"
  test -x "$LOADER"
  echo "loader=$LOADER"
  "$LOADER" --library-path "$LIBPATH" "$XPR_ROOT/bin/hello-knc"
  echo "hello_loader_rc=$?"
  "$LOADER" --library-path "$LIBPATH" "$XPR_ROOT/bin/python3.5" -S -c 'import math, threading; print("python_libc_stack_ok"); print(int(math.sqrt(144))); t=threading.Thread(target=lambda: None); t.start(); t.join()'
  echo "python_loader_rc=$?"
  echo "libc_stack_done=1"
} > "$OUT" 2>&1
LIBCSMOKE
chmod 0755 "$libc_stack_smoke_data/opt/xeon-phi-revival/bin/libc-stack-smoke.sh"

zlib1g_data=""
libncurses5_data=""
libreadline6_data=""
libssl100_data=""
libcrypto100_data=""
libffi8_data=""
runtime_libs_smoke_data=""
ncurses_base_data="$(new_data_dir ncurses-base-k1om)"
terminfo_linux="$(find_terminfo_linux)" || { echo "required terminfo entry missing: linux" >&2; exit 17; }
mkdir -p "$ncurses_base_data/usr/share/terminfo/l" "$ncurses_base_data/etc/terminfo/l"
cp -a "$terminfo_linux" "$ncurses_base_data/usr/share/terminfo/l/linux"
cp -a "$terminfo_linux" "$ncurses_base_data/etc/terminfo/l/linux"

if [[ "$runtime_required" -eq 1 ]]; then
  zlib1g_data="$(new_data_dir zlib1g-k1om)"
  copy_runtime_lib64 "$zlib1g_data" usr/lib64/libz.so.1 usr/lib64/libz.so.1.2.6

  libncurses5_data="$(new_data_dir libncurses5-k1om)"
  copy_runtime_lib64 "$libncurses5_data" lib64/libncurses.so.5 lib64/libncurses.so.5.9

  libreadline6_data="$(new_data_dir libreadline6-k1om)"
  copy_runtime_lib64 "$libreadline6_data" usr/lib64/libreadline.so.6 usr/lib64/libreadline.so.6.2

  libssl100_data="$(new_data_dir libssl1.0.0-k1om)"
  copy_runtime_lib64 "$libssl100_data" usr/lib64/libssl.so.1.0.0

  libcrypto100_data="$(new_data_dir libcrypto1.0.0-k1om)"
  copy_runtime_lib64 "$libcrypto100_data" lib64/libcrypto.so.1.0.0

  runtime_libs_smoke_data="$(new_data_dir xpr-runtime-libs-smoke)"
  mkdir -p "$runtime_libs_smoke_data/opt/xeon-phi-revival/bin"
  cat > "$runtime_libs_smoke_data/opt/xeon-phi-revival/bin/runtime-libs-smoke.sh" <<'RTLIBSMOKE'
#!/bin/sh
set -u
XPR_ROOT=${XPR_ROOT:-/opt/xeon-phi-revival}
LOG_DIR=/var/log/xeon-phi-revival
OUT="$LOG_DIR/runtime-libs-smoke.out"
mkdir -p "$LOG_DIR"
{
  echo "runtime_libs_started=1"
  for lib in \
    libz.so.1 libz.so.1.2.6 \
    libncurses.so.5 libncurses.so.5.9 \
    libtinfo.so.5 \
    libreadline.so.6 libreadline.so.6.2 \
    libssl.so.1.0.0 \
    libcrypto.so.1.0.0; do
    if [ -e "$XPR_ROOT/lib64/$lib" ]; then
      echo "present=$lib"
    else
      echo "missing=$lib"
      exit 1
    fi
  done
  echo "runtime_libs_done=1"
} > "$OUT" 2>&1
RTLIBSMOKE
  chmod 0755 "$runtime_libs_smoke_data/opt/xeon-phi-revival/bin/runtime-libs-smoke.sh"
fi

if [[ "$libffi_required" -eq 1 ]]; then
  libffi8_data="$(new_data_dir libffi8-k1om)"
  mkdir -p "$libffi8_data/opt/xeon-phi-revival/lib64"
  libffi_impl="$(basename "$libffi_shared")"
  cp -a "$libffi_shared" "$libffi8_data/opt/xeon-phi-revival/lib64/$libffi_impl"
  ln -s "$libffi_impl" "$libffi8_data/opt/xeon-phi-revival/lib64/libffi.so.8"
  ln -s libffi.so.8 "$libffi8_data/opt/xeon-phi-revival/lib64/libffi.so"
fi

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
    if [ -x "$XPR_ROOT/bin/libc-stack-smoke.sh" ]; then
      "$XPR_ROOT/bin/libc-stack-smoke.sh"
      echo "libc_stack_rc=$?" >> "$LOG"
    fi
    if [ -x "$XPR_ROOT/bin/runtime-libs-smoke.sh" ]; then
      "$XPR_ROOT/bin/runtime-libs-smoke.sh"
      echo "runtime_libs_rc=$?" >> "$LOG"
    fi
    if [ -x "$XPR_ROOT/bin/python312-smoke.sh" ]; then
      "$XPR_ROOT/bin/python312-smoke.sh"
      echo "python312_rc=$?" >> "$LOG"
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
make_deb dpkg-k1om "$dpkg_data" "base-files-k1om, xpr-busybox-compat" "Bootstrap dpkg-compatible package query and install tool for K1OM" "admin"
make_deb apt-k1om "$apt_data" "base-files-k1om, xpr-busybox-compat, dpkg-k1om" "Bootstrap apt-compatible local archive tool for K1OM" "admin"
make_deb libc6-k1om "$libc_data" "base-files-k1om" "K1OM glibc runtime loader and core libc payload" "libs"
make_deb libgcc1-k1om "$libgcc_data" "base-files-k1om" "K1OM GCC runtime support library" "libs"
make_deb libm6-k1om "$libm_data" "base-files-k1om, libc6-k1om" "K1OM glibc math runtime library" "libs"
make_deb libpthread0-k1om "$libpthread_data" "base-files-k1om, libc6-k1om" "K1OM glibc pthread runtime library" "libs"
make_deb libdl2-k1om "$libdl_data" "base-files-k1om, libc6-k1om" "K1OM glibc dynamic loading runtime library" "libs"
make_deb librt1-k1om "$librt_data" "base-files-k1om, libc6-k1om, libpthread0-k1om" "K1OM glibc realtime runtime library" "libs"
make_deb libutil1-k1om "$libutil_data" "base-files-k1om, libc6-k1om" "K1OM glibc util runtime library" "libs"
make_deb libc-stack-smoke-k1om "$libc_stack_smoke_data" "base-files-k1om, hello-knc-smoke, python3.5-minimal-k1om, python3.5-stdlib-k1om, python3.5-lib-dynload-k1om, libc6-k1om, libgcc1-k1om, libm6-k1om, libpthread0-k1om, libdl2-k1om, librt1-k1om, libutil1-k1om" "K1OM packaged libc stack smoke test" "utils"
make_deb ncurses-base-k1om "$ncurses_base_data" "base-files-k1om" "K1OM ncurses linux terminfo entry" "misc"
runtime_stage2_deps=""
python312_stage2_deps=""
libffi_python_dep=""
zlib_smoke_deps="base-files-k1om"
ncurses_smoke_deps="base-files-k1om, libtinfo5-k1om, ncurses-base-k1om"
if [[ "$libffi_required" -eq 1 ]]; then
  make_deb libffi8-k1om "$libffi8_data" "base-files-k1om, libc6-k1om" "K1OM libffi runtime with call and closure support" "libs"
  libffi_python_dep=", libffi8-k1om"
fi
if [[ "$python312_required" -eq 1 ]]; then
  make_deb python3.12-minimal-k1om "$python312_minimal_data" "base-files-k1om, libc6-k1om, libm6-k1om, libpthread0-k1om, libdl2-k1om, librt1-k1om, libutil1-k1om${libffi_python_dep}" "K1OM Python 3.12 interpreter payload" "python"
  make_deb python3.12-stdlib-k1om "$python312_stdlib_data" "base-files-k1om, python3.12-minimal-k1om" "K1OM Python 3.12 standard library payload" "python"
  make_deb python3.12-sysconfig-k1om "$python312_sysconfig_data" "base-files-k1om, python3.12-minimal-k1om, python3.12-stdlib-k1om" "K1OM Python 3.12 sysconfig metadata shim" "python"
  make_deb python3.12-smoke-k1om "$python312_smoke_data" "base-files-k1om, python3.12-minimal-k1om, python3.12-stdlib-k1om, python3.12-sysconfig-k1om, ncurses-base-k1om" "K1OM Python 3.12 expanded runtime smoke" "python"
  python312_stage2_deps=", python3.12-minimal-k1om, python3.12-stdlib-k1om, python3.12-sysconfig-k1om, python3.12-smoke-k1om"
fi
if [[ "$runtime_required" -eq 1 ]]; then
  make_deb zlib1g-k1om "$zlib1g_data" "base-files-k1om, libc6-k1om" "K1OM zlib runtime library" "libs"
  make_deb libncurses5-k1om "$libncurses5_data" "base-files-k1om, libc6-k1om, libtinfo5-k1om, ncurses-base-k1om" "K1OM ncurses runtime library" "libs"
  make_deb libreadline6-k1om "$libreadline6_data" "base-files-k1om, libc6-k1om, libncurses5-k1om, libtinfo5-k1om" "K1OM readline runtime library" "libs"
  make_deb libcrypto1.0.0-k1om "$libcrypto100_data" "base-files-k1om, libc6-k1om, libdl2-k1om" "K1OM OpenSSL crypto runtime library" "libs"
  make_deb libssl1.0.0-k1om "$libssl100_data" "base-files-k1om, libc6-k1om, libcrypto1.0.0-k1om" "K1OM OpenSSL SSL runtime library" "libs"
  make_deb xpr-runtime-libs-smoke "$runtime_libs_smoke_data" "base-files-k1om, zlib1g-k1om, libncurses5-k1om, libtinfo5-k1om, libreadline6-k1om, libssl1.0.0-k1om, libcrypto1.0.0-k1om" "K1OM split runtime-library smoke checks" "utils"
  runtime_stage2_deps=", zlib1g-k1om, libncurses5-k1om, libreadline6-k1om, libssl1.0.0-k1om, libcrypto1.0.0-k1om, xpr-runtime-libs-smoke"
  zlib_smoke_deps="$zlib_smoke_deps, zlib1g-k1om"
  ncurses_smoke_deps="$ncurses_smoke_deps, libncurses5-k1om"
fi
make_deb zlib-smoke-k1om "$zlib_data" "$zlib_smoke_deps" "K1OM zlib smoke payload" "libs"
make_deb libtinfo5-k1om "$libtinfo_data" "base-files-k1om" "K1OM terminfo runtime library" "libs"
make_deb ncurses-smoke-k1om "$ncurses_data" "$ncurses_smoke_deps" "K1OM ncurses smoke payload" "utils"
make_deb xpr-os-smoke "$os_data" "base-files-k1om" "Basic filesystem and OS smoke checks" "utils"
make_deb xeon-phi-revival-stage2 "$stage2_data" "base-files-k1om, hello-knc-smoke, python3.5-minimal-k1om, python3.5-stdlib-k1om, python3.5-lib-dynload-k1om, python3.5-smoke-k1om, xpr-shell-compat, xpr-busybox-compat, xpr-pci-tools, dpkg-k1om, apt-k1om, libc6-k1om, libgcc1-k1om, libm6-k1om, libpthread0-k1om, libdl2-k1om, librt1-k1om, libutil1-k1om, libc-stack-smoke-k1om${runtime_stage2_deps}${python312_stage2_deps}, zlib-smoke-k1om, libtinfo5-k1om, ncurses-smoke-k1om, xpr-os-smoke" "Second-stage service for K1OM profile" "admin"

{
  printf 'package\tversion\tarchitecture\tpath\tsha256\n'
  while IFS= read -r -d '' deb; do
    printf '%s\t%s\t%s\t%s\t%s\n' "$(basename "$deb" | cut -d_ -f1)" "$version" "$arch" "$deb" "$(sha256sum "$deb" | awk '{print $1}')"
  done < <(find "$out_dir/repo/pool" -type f -name '*.deb' -print0 | sort -z)
} > "$manifest"
echo "manifest=$manifest"
