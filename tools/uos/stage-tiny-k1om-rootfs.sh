#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  stage-tiny-k1om-rootfs.sh --stock-rootfs DIR --out DIR [--hello-knc FILE] [--manifest OUT]

Build a local-only tiny K1OM rootfs staging tree from a user-supplied stock MPSS
uOS extraction. The staged tree may contain proprietary runtime files and must
stay out of the public repository. The manifest contains metadata only.
USAGE
}

stock_rootfs=""
out_dir=""
hello_knc=""
manifest=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stock-rootfs)
      stock_rootfs="${2:-}"
      shift 2
      ;;
    --out)
      out_dir="${2:-}"
      shift 2
      ;;
    --hello-knc)
      hello_knc="${2:-}"
      shift 2
      ;;
    --manifest)
      manifest="${2:-}"
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

if [[ -z "$stock_rootfs" || -z "$out_dir" ]]; then
  usage
  exit 2
fi

if [[ ! -d "$stock_rootfs" ]]; then
  echo "stock rootfs does not exist: $stock_rootfs" >&2
  exit 3
fi

if [[ -e "$out_dir" && -n "$(find "$out_dir" -mindepth 1 -maxdepth 1 -print -quit)" ]]; then
  echo "output directory is not empty: $out_dir" >&2
  exit 4
fi

manifest="${manifest:-${out_dir%/}.public-manifest.tsv}"

required_paths=(
  /sbin/init
  /bin/sh
  /bin/bash
  /bin/busybox
  /lib64/ld-linux-k1om.so.2
  /lib64/libc.so.6
  /lib64/libgcc_s.so.1
  /etc/inittab
  /etc/fstab
  /etc/passwd
)

optional_paths=(
  /etc/group
  /etc/hosts
  /etc/resolv.conf
  /lib64/libdl.so.2
  /lib64/libm.so.6
  /lib64/libpthread.so.0
  /sbin/init.sysvinit
)

mkdir -p "$out_dir"
for d in dev proc sys tmp run root home usr/bin bin sbin etc lib64; do
  mkdir -p "$out_dir/$d"
done
chmod 1777 "$out_dir/tmp"

queued=()

queue_path() {
  local path="$1"
  local normalized="/${path#/}"
  queued+=("$normalized")
}

copy_one() {
  local path="$1"
  local src="$stock_rootfs/${path#/}"
  local dst="$out_dir/${path#/}"

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    return 1
  fi

  mkdir -p "$(dirname "$dst")"
  if [[ -L "$src" ]]; then
    local target
    target="$(readlink "$src")"
    ln -s "$target" "$dst"
    if [[ "$target" = /* ]]; then
      queue_path "$target"
    else
      queue_path "$(dirname "$path")/$target"
    fi
  elif [[ -d "$src" ]]; then
    mkdir -p "$dst"
  else
    cp -a "$src" "$dst"
  fi
}

queue_elf_deps() {
  local path="$1"
  local dst="$out_dir/${path#/}"

  if [[ ! -f "$dst" ]]; then
    return 0
  fi

  if ! head -c 4 "$dst" | grep -q $'^\x7fELF'; then
    return 0
  fi

  if ! command -v readelf >/dev/null 2>&1; then
    return 0
  fi

  while IFS= read -r lib; do
    [[ -z "$lib" ]] && continue
    for base in /lib64 /usr/lib64 /lib /usr/lib; do
      if [[ -e "$stock_rootfs$base/$lib" || -L "$stock_rootfs$base/$lib" ]]; then
        queue_path "$base/$lib"
        break
      fi
    done
  done < <(readelf -d "$dst" 2>/dev/null | sed -n 's/.*Shared library: \[\(.*\)\].*/\1/p')
}

process_queue() {
  local index=0
  local path

  while [[ "$index" -lt "${#queued[@]}" ]]; do
    path="${queued[$index]}"
    index=$((index + 1))
    if [[ ! -e "$out_dir/${path#/}" && ! -L "$out_dir/${path#/}" ]]; then
      copy_one "$path" || true
    fi
    queue_elf_deps "$path"
  done
}

missing=()
for path in "${required_paths[@]}"; do
  if ! copy_one "$path"; then
    missing+=("$path")
  fi
done

for path in "${optional_paths[@]}"; do
  copy_one "$path" || true
done

process_queue

while IFS= read -r -d '' path; do
  rel="/${path#"$out_dir"/}"
  queue_elf_deps "$rel"
done < <(find "$out_dir" -type f -print0)

process_queue

if [[ -n "$hello_knc" ]]; then
  if [[ ! -f "$hello_knc" ]]; then
    echo "hello-knc binary does not exist: $hello_knc" >&2
    exit 5
  fi
  cp -a "$hello_knc" "$out_dir/usr/bin/hello-knc"
  queue_elf_deps /usr/bin/hello-knc
  process_queue
fi

if [[ "${#missing[@]}" -gt 0 ]]; then
  echo "missing required paths:" >&2
  printf '  %s\n' "${missing[@]}" >&2
  exit 6
fi

broken_links=()
while IFS= read -r -d '' link; do
  target="$(readlink "$link")"
  if [[ "$target" = /* ]]; then
    resolved="$out_dir/${target#/}"
  else
    resolved="$(dirname "$link")/$target"
  fi
  if [[ ! -e "$resolved" && ! -L "$resolved" ]]; then
    broken_links+=("/${link#"$out_dir"/} -> $target")
  fi
done < <(find "$out_dir" -type l -print0)

if [[ "${#broken_links[@]}" -gt 0 ]]; then
  echo "broken symlinks:" >&2
  printf '  %s\n' "${broken_links[@]}" >&2
  exit 7
fi

mkdir -p "$(dirname "$manifest")"
{
  printf 'path\ttype\tmode\tsize\tsha256\tlink_target\n'
  while IFS= read -r -d '' path; do
    rel="/${path#"$out_dir"/}"
    if [[ -L "$path" ]]; then
      type="symlink"
      mode="$(stat -c '%a' "$path")"
      size="0"
      sha=""
      link_target="$(readlink "$path")"
    elif [[ -d "$path" ]]; then
      type="directory"
      mode="$(stat -c '%a' "$path")"
      size="0"
      sha=""
      link_target=""
    elif [[ -f "$path" ]]; then
      type="file"
      mode="$(stat -c '%a' "$path")"
      size="$(stat -c '%s' "$path")"
      sha="$(sha256sum "$path" | awk '{print $1}')"
      link_target=""
    else
      type="other"
      mode="$(stat -c '%a' "$path" 2>/dev/null || true)"
      size=""
      sha=""
      link_target=""
    fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$rel" "$type" "$mode" "$size" "$sha" "$link_target"
  done < <(find "$out_dir" -mindepth 1 -print0 | sort -z)
} > "$manifest"

echo "rootfs=$out_dir"
echo "manifest=$manifest"
