#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage: build-xpr-clean-rootfs.sh --busybox FILE [--out-root DIR] [--name NAME]

Build a minimal project-owned K1OM root filesystem and cpio archive. BusyBox
must be a locally built static K1OM ELF; it is not downloaded or copied from
stock MPSS files by this script.
USAGE
}

busybox=""
out_root="${HOME}/xeon-phi-revival-local/clean-root-builds"
name="xpr-clean-root"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --busybox) busybox="${2:-}"; shift 2 ;;
    --out-root) out_root="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done

[[ -f "$busybox" ]] || { usage; exit 2; }
for command in cpio date file find gzip mkdir readelf sha256sum sort stat; do
  command -v "$command" >/dev/null 2>&1 || { echo "missing host tool: $command" >&2; exit 10; }
done
readelf -h "$busybox" | grep -q 'Machine:.*Intel K1OM' || { echo "BusyBox is not K1OM" >&2; exit 11; }
readelf -d "$busybox" 2>/dev/null | grep -q NEEDED && { echo "BusyBox is not static" >&2; exit 12; } || true

if ! command -v k1om-mpss-linux-gcc >/dev/null 2>&1 && [[ -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
fi
command -v k1om-mpss-linux-gcc >/dev/null 2>&1 || { echo "K1OM compiler unavailable" >&2; exit 13; }

run_dir="$out_root/${name}-$(date -u +%Y%m%d-%H%M%S)"
rootfs="$run_dir/rootfs"
image="$run_dir/${name}.cpio.gz"
manifest="$run_dir/${name}.manifest.tsv"
mkdir -p "$rootfs"/{bin,sbin,usr/bin,etc,proc,sys,dev,run,tmp}
chmod 1777 "$rootfs/tmp"
cp -a "$busybox" "$rootfs/bin/busybox"
for applet in sh cat cp mv rm mkdir mount uname ps env sleep hostname ifconfig modprobe switch_root gzip cpio; do
  ln -s busybox "$rootfs/bin/$applet"
done
cp "$repo_root/src/uos/xpr_clean_root_init.sh" "$rootfs/sbin/init"
chmod 0755 "$rootfs/sbin/init"
cat > "$rootfs/etc/os-release" <<'EOF'
NAME="Xeon Phi Revival uOS"
PRETTY_NAME="Xeon Phi Revival Ubuntu-derived K1OM uOS"
ID=xpr-uos
ID_LIKE=ubuntu
VERSION_ID="0.1"
ARCHITECTURE="k1om"
EOF
k1om-mpss-linux-gcc -Os -static -s "$repo_root/src/uos/xpr_hello.c" -o "$rootfs/usr/bin/xpr-hello"
k1om-mpss-linux-gcc -Os -static -s -pthread "$repo_root/src/uos/xpr_pthread_smoke.c" -o "$rootfs/usr/bin/xpr-pthread-smoke"
chmod 0755 "$rootfs/usr/bin/xpr-hello" "$rootfs/usr/bin/xpr-pthread-smoke"
for elf in "$rootfs/bin/busybox" "$rootfs/usr/bin/xpr-hello" "$rootfs/usr/bin/xpr-pthread-smoke"; do
  readelf -h "$elf" | grep -q 'Machine:.*Intel K1OM' || { echo "non-K1OM ELF: $elf" >&2; exit 14; }
  readelf -d "$elf" 2>/dev/null | grep -q NEEDED && { echo "dynamic ELF: $elf" >&2; exit 15; } || true
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
sha256sum "$image" "$manifest" "$rootfs/bin/busybox" "$rootfs/usr/bin/xpr-hello" "$rootfs/usr/bin/xpr-pthread-smoke" > "$run_dir/SHA256SUMS"
printf 'rootfs=%s\nimage=%s\nmanifest=%s\n' "$rootfs" "$image" "$manifest"
