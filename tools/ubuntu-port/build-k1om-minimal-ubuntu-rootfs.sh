#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-k1om-minimal-ubuntu-rootfs.sh --package-rootfs DIR --out-dir DIR [--stock-rootfs DIR] [--suite noble] [--version 24.04]

Build a private, Ubuntu-shaped K1OM root filesystem from an already simulated
Xeon Phi Revival package install. This does not download Ubuntu packages and
does not redistribute Intel MPSS or extracted uOS payloads.
USAGE
}

package_rootfs=""
stock_rootfs=""
out_dir=""
suite="noble"
version="24.04"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package-rootfs) package_rootfs="${2:-}"; shift 2 ;;
    --stock-rootfs) stock_rootfs="${2:-}"; shift 2 ;;
    --out-dir) out_dir="${2:-}"; shift 2 ;;
    --suite) suite="${2:-}"; shift 2 ;;
    --version) version="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$package_rootfs" && -d "$package_rootfs" ]] || { usage; exit 2; }
[[ -n "$out_dir" ]] || { usage; exit 2; }
if [[ -n "$stock_rootfs" && ! -d "$stock_rootfs" ]]; then
  echo "stock rootfs is not a directory: $stock_rootfs" >&2
  exit 2
fi

rootfs="$out_dir/rootfs"
manifest="$out_dir/k1om-minimal-ubuntu-rootfs-manifest.tsv"
summary="$out_dir/k1om-minimal-ubuntu-rootfs-summary.txt"
hashes="$out_dir/k1om-minimal-ubuntu-rootfs-sha256.tsv"
rm -rf "$out_dir"
mkdir -p "$rootfs"

copy_tree() {
  src="$1"
  dst="$2"
  mkdir -p "$dst"
  (cd "$src" && tar -cf - .) | (cd "$dst" && tar -xf -)
}

copy_if_present() {
  rel="$1"
  if [[ -n "$stock_rootfs" && ( -e "$stock_rootfs/$rel" || -L "$stock_rootfs/$rel" ) ]]; then
    mkdir -p "$rootfs/$(dirname "$rel")"
    cp -a "$stock_rootfs/$rel" "$rootfs/$rel"
  fi
}

copy_tree "$package_rootfs" "$rootfs"

mkdir -p \
  "$rootfs/bin" "$rootfs/sbin" "$rootfs/lib64" "$rootfs/usr/bin" \
  "$rootfs/usr/sbin" "$rootfs/usr/lib" "$rootfs/usr/lib64" \
  "$rootfs/etc/apt/sources.list.d" "$rootfs/etc/dpkg" "$rootfs/etc/profile.d" \
  "$rootfs/dev" "$rootfs/proc" "$rootfs/sys" "$rootfs/run" "$rootfs/tmp" \
  "$rootfs/var/tmp" "$rootfs/var/log" "$rootfs/root" "$rootfs/home" \
  "$rootfs/boot" "$rootfs/media" "$rootfs/mnt" "$rootfs/srv"

chmod 0755 "$rootfs"
chmod 1777 "$rootfs/tmp" "$rootfs/var/tmp"
chmod 0700 "$rootfs/root"

copy_if_present bin/busybox
for applet in sh ls cat grep sed awk find mkdir rm cp mv ln readlink touch chmod chown ps mount umount uname hostname env sort head tail wc date df du sleep true false test printf pwd; do
  if [[ ! -e "$rootfs/bin/$applet" && ! -L "$rootfs/bin/$applet" ]]; then
    ln -s busybox "$rootfs/bin/$applet"
  fi
done

for lib in "$rootfs/opt/xeon-phi-revival/lib64"/*; do
  [[ -e "$lib" || -L "$lib" ]] || continue
  name="${lib##*/}"
  [[ -e "$rootfs/lib64/$name" || -L "$rootfs/lib64/$name" ]] || ln -s "../opt/xeon-phi-revival/lib64/$name" "$rootfs/lib64/$name"
done

if [[ -e "$rootfs/usr/bin/python3.12" || -L "$rootfs/usr/bin/python3.12" ]]; then
  rm -f "$rootfs/usr/bin/python3"
  ln -s python3.12 "$rootfs/usr/bin/python3"
  rm -f "$rootfs/usr/bin/python"
  ln -s python3.12 "$rootfs/usr/bin/python"
fi

cat > "$rootfs/etc/os-release" <<EOF
NAME="Xeon Phi Revival uOS"
PRETTY_NAME="Xeon Phi Revival Ubuntu-derived K1OM uOS"
ID=xpr-uos
ID_LIKE=ubuntu
VERSION_ID="0.1"
VERSION="0.1 release candidate"
VERSION_CODENAME="${suite}"
ARCHITECTURE="k1om"
HOME_URL="https://github.com/Xeon-Phi-Revival-Project"
SUPPORT_URL="https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival"
BUG_REPORT_URL="https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/issues"
XPR_ARCH="k1om"
XPR_DERIVED_FROM="Ubuntu ${version} ${suite} source/package metadata"
XPR_NOTE="Minimal Ubuntu-derived K1OM uOS; not an official Ubuntu, Intel, or Canonical release."
EOF

cat > "$rootfs/etc/lsb-release" <<EOF
DISTRIB_ID=Xeon Phi Revival uOS
DISTRIB_RELEASE=0.1
DISTRIB_CODENAME=${suite}
DISTRIB_DESCRIPTION="Xeon Phi Revival Ubuntu-derived K1OM uOS"
EOF

cat > "$rootfs/etc/debian_version" <<'EOF'
xpr-uos 0.1 ${suite}-derived
EOF

cat > "$rootfs/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
nobody:x:65534:65534:nobody:/nonexistent:/usr/sbin/nologin
EOF

cat > "$rootfs/etc/group" <<'EOF'
root:x:0:
adm:x:4:
tty:x:5:
disk:x:6:
www-data:x:33:
nogroup:x:65534:
EOF

cat > "$rootfs/etc/hostname" <<'EOF'
xeon-phi-k1om
EOF

cat > "$rootfs/etc/hosts" <<'EOF'
127.0.0.1 localhost
127.0.1.1 xeon-phi-k1om
::1 localhost ip6-localhost ip6-loopback
EOF

cat > "$rootfs/etc/nsswitch.conf" <<'EOF'
passwd: files
group: files
shadow: files
hosts: files dns
networks: files
protocols: files
services: files
ethers: files
rpc: files
EOF

cat > "$rootfs/etc/profile" <<'EOF'
export XPR_ROOT=/opt/xeon-phi-revival
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$XPR_ROOT/bin
export LD_LIBRARY_PATH=$XPR_ROOT/lib64:${LD_LIBRARY_PATH:-}
export PYTHONHOME=$XPR_ROOT
export PYTHONPATH=$XPR_ROOT/lib/python3.12
EOF

cat > "$rootfs/etc/apt/sources.list" <<'EOF'
deb [trusted=yes arch=k1om] file:/opt/xeon-phi-revival/repo noble main
EOF

if [[ ! -e "$rootfs/dev/null" ]]; then
  mknod -m 0666 "$rootfs/dev/null" c 1 3 2>/dev/null || touch "$rootfs/dev/null"
fi
if [[ ! -e "$rootfs/dev/zero" ]]; then
  mknod -m 0666 "$rootfs/dev/zero" c 1 5 2>/dev/null || touch "$rootfs/dev/zero"
fi
if [[ ! -e "$rootfs/dev/console" ]]; then
  mknod -m 0600 "$rootfs/dev/console" c 5 1 2>/dev/null || touch "$rootfs/dev/console"
fi

{
  printf 'path\ttype\tmode\tsize\tsha256\n'
  while IFS= read -r -d '' path; do
    rel="/${path#"$rootfs"/}"
    if [[ -L "$path" ]]; then
      printf '%s\tsymlink\t%s\t0\t%s\n' "$rel" "$(stat -c '%a' "$path")" "$(readlink "$path")"
    elif [[ -f "$path" ]]; then
      printf '%s\tfile\t%s\t%s\t%s\n' "$rel" "$(stat -c '%a' "$path")" "$(stat -c '%s' "$path")" "$(sha256sum "$path" | awk '{print $1}')"
    elif [[ -d "$path" ]]; then
      printf '%s\tdir\t%s\t0\t-\n' "$rel" "$(stat -c '%a' "$path")"
    fi
  done < <(find "$rootfs" -mindepth 1 -print0 | sort -z)
} > "$manifest"

{
  while IFS= read -r -d '' path; do
    sha256sum "$path" | sed "s#  $rootfs/#\t/#"
  done < <(find "$rootfs" -type f -print0 | sort -z)
} > "$hashes"

cat > "$summary" <<EOF
status=prepared
rootfs=$rootfs
source_package_rootfs=$package_rootfs
source_stock_rootfs=${stock_rootfs:-none}
suite=$suite
version=$version
manifest=$manifest
hashes=$hashes
source_date_epoch=$source_date_epoch
note=Private rootfs output may contain non-redistributable locally supplied K1OM runtime payloads.
EOF

echo "minimal_ubuntu_rootfs=$rootfs"
echo "manifest=$manifest"
echo "summary=$summary"
