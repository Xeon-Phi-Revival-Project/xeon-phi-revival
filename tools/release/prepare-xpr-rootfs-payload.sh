#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: $0 --source FILE --out-dir DIR [--package-repo DIR] [--rc-init FILE] [--rc-init-script FILE]" >&2
}

source_file=""; out_dir=""; package_repo=""; rc_init=""; rc_init_script=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_file="$2"; shift 2 ;;
    --out-dir) out_dir="$2"; shift 2 ;;
    --package-repo) package_repo="$2"; shift 2 ;;
    --rc-init) rc_init="$2"; shift 2 ;;
    --rc-init-script) rc_init_script="$2"; shift 2 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$source_file" && -n "$out_dir" ]] || { usage; exit 2; }
[[ -z "$package_repo" || -d "$package_repo" ]] || { echo "missing package repo: $package_repo" >&2; exit 2; }
[[ -z "$rc_init" || -f "$rc_init" ]] || { echo "missing RC init: $rc_init" >&2; exit 2; }
[[ -z "$rc_init_script" || -f "$rc_init_script" ]] || { echo "missing RC init script: $rc_init_script" >&2; exit 2; }
for command in chmod cp cpio find grep gzip python sha256sum sort wc; do command -v "$command" >/dev/null || exit 10; done

mkdir -p "$out_dir"
payload="$out_dir/xpr-rootfs.cpio.gz"
manifest="$out_dir/xpr-rootfs.manifest"
report="$out_dir/xpr-rootfs.archive-report"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
archive_args=(
  --source "$source_file" --output "$payload" --report "$report"
  --set-mode sbin/init=0755
  --assert-executable sbin/init
  --assert-executable bin/busybox
  --assert-executable usr/sbin/dropbear
  --assert-executable usr/bin/xpr-hello
  --assert-executable usr/bin/xpr-pthread-smoke
  --ensure-symlink bin/basename=busybox
  --ensure-symlink bin/dd=busybox
  --ensure-symlink bin/dirname=busybox
  --ensure-symlink bin/tar=busybox
  --ensure-symlink bin/tr=busybox
)
if [[ -n "$rc_init" ]]; then
  archive_args+=(--replace-entry-file "sbin/init=$rc_init")
fi
if [[ -n "$rc_init_script" ]]; then
  staged_rc_init="$out_dir/.xpr-rc-init.sh"
  cp "$rc_init_script" "$staged_rc_init"
  chmod 0755 "$staged_rc_init"
  archive_args+=(--add-entry-from "sbin/xpr-rc-init.sh=$staged_rc_init" --assert-executable sbin/xpr-rc-init.sh)
fi
if [[ -n "$package_repo" ]]; then
  if find "$package_repo" -type l -print -quit | grep -q .; then
    echo "package repo symlinks are not supported: $package_repo" >&2
    exit 12
  fi
  while IFS= read -r directory; do
    rel="${directory#"$package_repo"/}"
    archive_args+=(--add-directory "opt/xeon-phi-revival/repo/$rel")
  done < <(find "$package_repo" -mindepth 1 -type d | LC_ALL=C sort)
  while IFS= read -r file; do
    rel="${file#"$package_repo"/}"
    archive_args+=(--add-entry-from "opt/xeon-phi-revival/repo/$rel=$file")
  done < <(find "$package_repo" -type f | LC_ALL=C sort)
fi
python "$repo_root/tools/uos/newc_archive.py" "${archive_args[@]}"
[[ -z "${staged_rc_init:-}" ]] || rm -f "$staged_rc_init"
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
  printf 'archive_report=%s\n' "$report"
  printf 'rc_init=%s\n' "${rc_init:-source-archive}"
  printf 'rc_init_script=%s\n' "${rc_init_script:-none}"
  printf 'package_repo=%s\n' "${package_repo:-none}"
  printf '%s\n' 'required_paths=sbin/init,bin/busybox,usr/sbin/dropbear,usr/bin/xpr-hello,usr/bin/xpr-pthread-smoke,etc'
} > "$manifest"
printf 'payload=%s\nmanifest=%s\n' "$payload" "$manifest"
