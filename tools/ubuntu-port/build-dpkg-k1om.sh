#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-dpkg-k1om.sh \
    --dpkg-source-dir DIR \
    --libmd-source-dir DIR \
    --k1om-patch FILE \
    --host-compat-patch FILE \
    --autopoint-root DIR \
    --out-dir DIR

Build Ubuntu Noble dpkg 1.22.6 and libmd 1.1.0 for K1OM. Sources and the
privately extracted gettext/autopoint host tools must be supplied separately.
The script does not download, install, deploy, or execute target binaries.
USAGE
}

dpkg_source=""
libmd_source=""
k1om_patch=""
host_compat_patch=""
autopoint_root=""
out_dir=""
toolchain_root="${K1OM_TOOLCHAIN_ROOT:-/opt/mpss/3.4.10}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dpkg-source-dir) dpkg_source="${2:-}"; shift 2 ;;
    --libmd-source-dir) libmd_source="${2:-}"; shift 2 ;;
    --k1om-patch) k1om_patch="${2:-}"; shift 2 ;;
    --host-compat-patch) host_compat_patch="${2:-}"; shift 2 ;;
    --autopoint-root) autopoint_root="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -d "$dpkg_source" && -f "$dpkg_source/configure.ac" ]] || { usage; exit 2; }
[[ -d "$libmd_source" && -x "$libmd_source/configure" ]] || { usage; exit 2; }
[[ -f "$k1om_patch" && -f "$host_compat_patch" ]] || { usage; exit 2; }
[[ -x "$autopoint_root/usr/bin/autopoint" ]] || { usage; exit 2; }
[[ -f "$autopoint_root/usr/share/gettext/archive.dir.tar.xz" ]] || { usage; exit 2; }
[[ -n "$out_dir" ]] || { usage; exit 2; }

tool_bin="$toolchain_root/sysroots/x86_64-mpsssdk-linux/usr/bin/k1om-mpss-linux"
sysroot="$toolchain_root/sysroots/k1om-mpss-linux"
cc="$tool_bin/k1om-mpss-linux-gcc"
readelf="$tool_bin/k1om-mpss-linux-readelf"
[[ -x "$cc" && -x "$readelf" && -d "$sysroot" ]] || {
  echo "MPSS K1OM toolchain not found under $toolchain_root" >&2
  exit 3
}

rm -rf "$out_dir"
mkdir -p "$out_dir/source" "$out_dir/build" "$out_dir/prefix" "$out_dir/stage"
dpkg_work="$out_dir/source/dpkg"
libmd_work="$out_dir/source/libmd"
(cd "$dpkg_source" && tar -cf - .) | (mkdir -p "$dpkg_work" && cd "$dpkg_work" && tar -xf -)
(cd "$libmd_source" && tar -cf - .) | (mkdir -p "$libmd_work" && cd "$libmd_work" && tar -xf -)

(cd "$dpkg_work" && patch -p1 < "$k1om_patch")
(cd "$dpkg_work" && patch -p1 < "$host_compat_patch")

export PATH="$autopoint_root/usr/bin:$tool_bin:$PATH"
export gettext_datadir="$autopoint_root/usr/share/gettext"
(cd "$dpkg_work" && ./autogen)

# Automake 1.13 installs a 2013 config.sub that predates K1OM.
config_sub="$dpkg_work/build-aux/config.sub"
perl -0pi -e \
  's/(\t\| ip2k-\* \| iq2000-\* \\\n)/$1\t| k1om-* \\\n/' \
  "$config_sub"
"$config_sub" k1om-mpss-linux | grep -q '^k1om-mpss-linux-gnu$'

libmd_prefix="$out_dir/prefix/libmd"
mkdir -p "$out_dir/build/libmd"
(
  cd "$out_dir/build/libmd"
  "$libmd_work/configure" \
    --build=x86_64-redhat-linux-gnu \
    --host=k1om-mpss-linux \
    --prefix="$libmd_prefix" \
    --disable-shared \
    --enable-static \
    CC=k1om-mpss-linux-gcc \
    AR=k1om-mpss-linux-ar \
    RANLIB=k1om-mpss-linux-ranlib
  make -j"${JOBS:-2}"
  make install
)

dpkg_prefix="/opt/xeon-phi-revival/dpkg-real"
mkdir -p "$out_dir/build/dpkg"
(
  cd "$out_dir/build/dpkg"
  export PKG_CONFIG_PATH="$libmd_prefix/lib/pkgconfig"
  ac_cv_path_PERL=/usr/bin/perl TAR=tar "$dpkg_work/configure" \
    --build=x86_64-redhat-linux-gnu \
    --host=k1om-mpss-linux \
    --prefix="$dpkg_prefix" \
    --with-sysroot="$sysroot" \
    --with-admindir=/var/lib/dpkg \
    --with-logdir=/var/log \
    --disable-nls \
    --disable-dselect \
    --disable-start-stop-daemon \
    --disable-unicode \
    --disable-shared \
    --enable-static \
    --without-libz \
    --without-libz-ng \
    --without-libbz2 \
    --without-liblzma \
    --without-libzstd \
    --without-libselinux \
    CC=k1om-mpss-linux-gcc \
    CXX=k1om-mpss-linux-g++ \
    AR=k1om-mpss-linux-ar \
    RANLIB=k1om-mpss-linux-ranlib \
    STRIP=k1om-mpss-linux-strip \
    CPPFLAGS="-I$libmd_prefix/include" \
    LDFLAGS="-L$libmd_prefix/lib" \
    LIBS=-lmd
  make -j"${JOBS:-2}"
  make install DESTDIR="$out_dir/stage"
)

libexec="$out_dir/stage$dpkg_prefix/libexec"
mkdir -p "$libexec"
cat > "$libexec/tar" <<'TAR_WRAPPER'
#!/bin/sh
# dpkg passes GNU tar metadata flags that BusyBox 1.19 does not implement.
filtered=
for arg in "$@"; do
  case "$arg" in
    -m|--warning=no-timestamp) ;;
    *) filtered="$filtered '$(printf %s "$arg" | sed "s/'/'\\\\''/g")'" ;;
  esac
done
eval "set -- $filtered"
exec /bin/tar "$@"
TAR_WRAPPER
chmod 0755 "$libexec/tar"

bindir="$out_dir/stage$dpkg_prefix/bin"
: > "$out_dir/elf-audit.tsv"
for name in dpkg dpkg-deb dpkg-query dpkg-divert dpkg-split dpkg-statoverride dpkg-trigger; do
  file="$bindir/$name"
  "$readelf" -h "$file" | grep -q 'Machine:.*Intel K1OM'
  printf '%s\t%s\n' "$name" "Intel K1OM" >> "$out_dir/elf-audit.tsv"
done

find "$out_dir/stage$dpkg_prefix" -type f -print0 |
  sort -z |
  xargs -0 sha256sum > "$out_dir/sha256sums.txt"

cat > "$out_dir/build-summary.txt" <<EOF
status=passed
architecture=k1om
dpkg_version=1.22.6
libmd_version=1.1.0
prefix=$dpkg_prefix
admindir=/var/lib/dpkg
logdir=/var/log
stage=$out_dir/stage
tar_runtime=busybox-compat-wrapper
compression_libraries=disabled
EOF
cat "$out_dir/build-summary.txt"
