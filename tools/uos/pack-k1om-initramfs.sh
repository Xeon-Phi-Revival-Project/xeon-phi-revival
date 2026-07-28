#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  pack-k1om-initramfs.sh --rootfs DIR [--out-dir DIR] [--name NAME]

Pack a validated K1OM rootfs as a gzip-compressed SVR4/newc cpio image. The
default output directory is a timestamped private build directory outside this
repository. Existing output files are never overwritten.
USAGE
}

rootfs=""
out_dir=""
name="k1om-project-pid1"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --rootfs)
      rootfs="${2:-}"
      shift 2
      ;;
    --out-dir)
      out_dir="${2:-}"
      shift 2
      ;;
    --name)
      name="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

if [[ -z "$rootfs" || ! -d "$rootfs" ]]; then
  usage
  exit 2
fi

timestamp="$(date -u +%Y%m%d-%H%M%S)"
out_dir="${out_dir:-${HOME}/xeon-phi-revival-local/uos-boot-builds/${name}-${timestamp}}"
image="${out_dir}/${name}.cpio.gz"
manifest="${out_dir}/${name}.manifest.tsv"
hashes="${out_dir}/${name}.sha256.txt"

if [[ -e "$image" || -e "$manifest" || -e "$hashes" ]]; then
  echo "refusing to overwrite existing output in $out_dir" >&2
  exit 3
fi

if [[ ! -x "$rootfs/init" ]]; then
  echo "$rootfs/init is missing or not executable" >&2
  exit 4
fi

mkdir -p "$out_dir"

(
  cd "$rootfs"
  find . -print0 | sort -z | cpio --null -o -H newc 2>"${out_dir}/cpio.stderr" | gzip -9n > "$image"
)

{
  printf 'path\ttype\tmode\tsize\tsha256\tlink_target\n'
  while IFS= read -r -d '' path; do
    rel="/${path#"$rootfs"/}"
    if [[ -L "$path" ]]; then
      printf '%s\tsymlink\t%s\t0\t\t%s\n' "$rel" "$(stat -c '%a' "$path")" "$(readlink "$path")"
    elif [[ -d "$path" ]]; then
      printf '%s\tdirectory\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path")"
    elif [[ -f "$path" ]]; then
      printf '%s\tfile\t%s\t%s\t%s\t\n' "$rel" "$(stat -c '%a' "$path")" "$(stat -c '%s' "$path")" "$(sha256sum "$path" | awk '{print $1}')"
    else
      printf '%s\tspecial\t%s\t0\t\t\n' "$rel" "$(stat -c '%a' "$path" 2>/dev/null || true)"
    fi
  done < <(find "$rootfs" -mindepth 1 -print0 | sort -z)
} > "$manifest"

sha256sum "$image" "$manifest" > "$hashes"

echo "image=$image"
echo "manifest=$manifest"
echo "hashes=$hashes"
file "$image" || true
gzip -l "$image" || true
