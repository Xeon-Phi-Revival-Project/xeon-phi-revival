#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --source FILE --out-dir DIR" >&2
}

source_file=""; out_dir=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_file="$2"; shift 2 ;;
    --out-dir) out_dir="$2"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$source_file" && -n "$out_dir" ]] || { usage; exit 2; }
for command in cpio gzip sha256sum wc; do command -v "$command" >/dev/null || exit 10; done

mkdir -p "$out_dir"
payload="$out_dir/xpr-rootfs.cpio.gz"
manifest="$out_dir/xpr-rootfs.manifest"
cp "$source_file" "$payload"
gzip -t "$payload"
members=$(gzip -dc "$payload" | cpio -it 2>/dev/null | tee "$out_dir/.members" | wc -l)
for path in sbin/init bin/busybox usr/sbin/dropbear usr/bin/xpr-hello usr/bin/xpr-pthread-smoke etc; do
  grep -qx "$path" "$out_dir/.members" || { rm -f "$out_dir/.members"; echo "missing payload path: $path" >&2; exit 11; }
done
rm -f "$out_dir/.members"
{
  printf 'sha256=%s\n' "$(sha256sum "$payload" | awk '{print $1}')"
  printf 'compressed_bytes=%s\n' "$(wc -c < "$payload")"
  printf 'unpacked_bytes=%s\n' "$(gzip -dc "$payload" | wc -c)"
  printf 'member_count=%s\n' "$members"
  printf '%s\n' 'required_paths=sbin/init,bin/busybox,usr/sbin/dropbear,usr/bin/xpr-hello,usr/bin/xpr-pthread-smoke,etc'
} > "$manifest"
printf 'payload=%s\nmanifest=%s\n' "$payload" "$manifest"
