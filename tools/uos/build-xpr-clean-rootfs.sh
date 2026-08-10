#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: build-xpr-clean-rootfs.sh --busybox FILE --dropbear FILE --authorized-keys FILE [--runtime-libdir DIR] [--out-root DIR] [--name NAME]

Build a minimal project-owned K1OM root filesystem and cpio archive. BusyBox
must be a locally built static K1OM ELF; it is not downloaded or copied from
stock MPSS files by this script.
USAGE
}

busybox=""
dropbear=""
authorized_keys=""
runtime_libdir=""
out_root="${HOME}/xeon-phi-revival-local/clean-root-builds"
name="xpr-clean-root"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --busybox) busybox="${2:-}"; shift 2 ;;
    --dropbear) dropbear="${2:-}"; shift 2 ;;
    --authorized-keys) authorized_keys="${2:-}"; shift 2 ;;
    --runtime-libdir) runtime_libdir="${2:-}"; shift 2 ;;
    --out-root) out_root="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

[[ -f "$busybox" && -f "$dropbear" && -f "$authorized_keys" ]] || { usage; exit 2; }
for command in cpio date file find gzip mkdir readelf sha256sum sort stat; do
  command -v "$command" >/dev/null 2>&1 || { echo "missing host tool: $command" >&2; exit 10; }
done
readelf -h "$busybox" | grep -q 'Machine:.*Intel K1OM' || { echo "BusyBox is not K1OM" >&2; exit 11; }
readelf -d "$busybox" 2>/dev/null | grep -q NEEDED && { echo "BusyBox is not static" >&2; exit 12; } || true
readelf -h "$dropbear" | grep -q 'Machine:.*Intel K1OM' || { echo "Dropbear is not K1OM" >&2; exit 13; }
dropbear_dynamic=0
readelf -d "$dropbear" 2>/dev/null | grep -q NEEDED && dropbear_dynamic=1
if [[ "$dropbear_dynamic" == 1 ]]; then
  [[ -d "$runtime_libdir" ]] || { echo "dynamic Dropbear requires --runtime-libdir" >&2; exit 14; }
  for library in ld-2.19.so ld-linux-k1om.so.2 libc-2.19.so libc.so.6 libcrypt-2.19.so libcrypt.so.1 libutil-2.19.so libutil.so.1 libnss_files-2.19.so libnss_files.so.2; do
    [[ -e "$runtime_libdir/$library" || -L "$runtime_libdir/$library" ]] || { echo "missing project runtime library: $library" >&2; exit 15; }
  done
fi

if ! command -v k1om-mpss-linux-gcc >/dev/null 2>&1 && [[ -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
fi
command -v k1om-mpss-linux-gcc >/dev/null 2>&1 || { echo "K1OM compiler unavailable" >&2; exit 16; }

run_dir="$out_root/${name}-$(date -u +%Y%m%d-%H%M%S)"
rootfs="$run_dir/rootfs"
image="$run_dir/${name}.cpio.gz"
manifest="$run_dir/${name}.manifest.tsv"
mkdir -p "$rootfs"/{bin,sbin,usr/bin,usr/sbin,etc,proc,sys,dev,run,tmp,root/.ssh}
chmod 1777 "$rootfs/tmp"
cp -a "$busybox" "$rootfs/bin/busybox"
cp -a "$dropbear" "$rootfs/usr/sbin/dropbear"
cp "$authorized_keys" "$rootfs/root/.ssh/authorized_keys"
chmod 0700 "$rootfs/root/.ssh"
chmod 0600 "$rootfs/root/.ssh/authorized_keys"
for applet in sh cat cp mv rm mkdir mknod mount uname ps env sleep hostname ifconfig modprobe switch_root gzip cpio sha256sum awk sed chmod grep; do
  ln -s busybox "$rootfs/bin/$applet"
done
cp "$repo_root/src/uos/xpr_clean_root_init.sh" "$rootfs/sbin/init"
mkdir -p "$rootfs/opt/xeon-phi-revival/bin"
cp "$repo_root/src/uos/xpr_stage_root.sh" "$rootfs/opt/xeon-phi-revival/bin/xpr-stage-root"
chmod 0755 "$rootfs/sbin/init"
chmod 0755 "$rootfs/opt/xeon-phi-revival/bin/xpr-stage-root"
cat > "$rootfs/etc/os-release" <<'EOF'
NAME="Xeon Phi Revival uOS"
PRETTY_NAME="Xeon Phi Revival K1OM uOS"
ID=xpr-uos
ID_LIKE=ubuntu
VERSION_ID="0.1"
ARCHITECTURE="k1om"
EOF
cp "$repo_root/src/uos/xpr-banner.txt" "$rootfs/etc/motd"
cp "$repo_root/src/uos/xpr-banner.txt" "$rootfs/etc/issue"
cat > "$rootfs/etc/passwd" <<'EOF'
root:x:0:0:root:/root:/bin/sh
EOF
cat > "$rootfs/etc/group" <<'EOF'
root:x:0:
EOF
if [[ "$dropbear_dynamic" == 1 ]]; then
  mkdir -p "$rootfs/lib64"
  cp -a "$runtime_libdir"/ld-2.19.so "$runtime_libdir"/ld-linux-k1om.so.2 \
    "$runtime_libdir"/libc-2.19.so "$runtime_libdir"/libc.so.6 \
    "$runtime_libdir"/libcrypt-2.19.so "$runtime_libdir"/libcrypt.so.1 \
    "$runtime_libdir"/libutil-2.19.so "$runtime_libdir"/libutil.so.1 \
    "$runtime_libdir"/libnss_files-2.19.so "$runtime_libdir"/libnss_files.so.2 "$rootfs/lib64/"
  cat > "$rootfs/etc/nsswitch.conf" <<'EOF'
passwd: files
group: files
shadow: files
hosts: files dns
EOF
fi
k1om-mpss-linux-gcc -Os -static -s "$repo_root/src/uos/xpr_hello.c" -o "$rootfs/usr/bin/xpr-hello"
k1om-mpss-linux-gcc -Os -static -s -pthread "$repo_root/src/uos/xpr_pthread_smoke.c" -o "$rootfs/usr/bin/xpr-pthread-smoke"
k1om-mpss-linux-gcc -Os -static -s "$repo_root/src/uos/xpr_statusd.c" -o "$rootfs/usr/bin/xpr-statusd"
chmod 0755 "$rootfs/usr/bin/xpr-hello" "$rootfs/usr/bin/xpr-pthread-smoke" "$rootfs/usr/bin/xpr-statusd"
for elf in "$rootfs/bin/busybox" "$rootfs/usr/sbin/dropbear" "$rootfs/usr/bin/xpr-hello" "$rootfs/usr/bin/xpr-pthread-smoke" "$rootfs/usr/bin/xpr-statusd"; do
  readelf -h "$elf" | grep -q 'Machine:.*Intel K1OM' || { echo "non-K1OM ELF: $elf" >&2; exit 14; }
  if [[ "$elf" != "$rootfs/usr/sbin/dropbear" || "$dropbear_dynamic" == 0 ]]; then
    readelf -d "$elf" 2>/dev/null | grep -q NEEDED && { echo "dynamic ELF: $elf" >&2; exit 15; } || true
  fi
done
(
  cd "$rootfs"
  find . -print0 | sort -z | cpio --null -o -H newc 2>"$run_dir/cpio.stderr" | gzip -9n > "$image"
)
gzip -t "$image"
{
  printf 'path\ttype\tmode\tsize\tsha256\tlink_target\n'
  while IFS= read -r -d '' path; do
    rel="/${path#"$rootfs"/}"
    if [[ -L "$path" ]]; then
      printf '%s\tsymlink\t%s\t0\t\t%s\n' "$rel" "$(stat -c '%a' "$path")" "$(readlink "$path")"
    elif [[ -d "$path" ]]; then
      printf '%s\tdirectory\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path")"
    else
      printf '%s\tfile\t%s\t%s\t%s\t\n' "$rel" "$(stat -c '%a' "$path")" "$(stat -c '%s' "$path")" "$(sha256sum "$path" | awk '{print $1}')"
    fi
  done < <(find "$rootfs" -mindepth 1 -print0 | sort -z)
} > "$manifest"
sha256sum "$image" "$manifest" "$rootfs/bin/busybox" "$rootfs/usr/sbin/dropbear" "$rootfs/usr/bin/xpr-hello" "$rootfs/usr/bin/xpr-pthread-smoke" "$rootfs/usr/bin/xpr-statusd" > "$run_dir/SHA256SUMS"
printf 'rootfs=%s\nimage=%s\nmanifest=%s\n' "$rootfs" "$image" "$manifest"
