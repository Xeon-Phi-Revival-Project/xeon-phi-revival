#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-minimal-k1om-initramfs.sh --source FILE [--out-root DIR] [--name NAME]

Build the smallest K1OM control initramfs for testing whether the MPSS kernel
can reach a project /init at all. The builder tries a static K1OM ELF first. If
static linking fails, it falls back to a loader-minimal dynamic image and
records the reason.
USAGE
}

source_file=""
out_root="${HOME}/xeon-phi-revival-local/uos-min-init-builds"
name="xpr-min-init"
source_date_epoch="${SOURCE_DATE_EPOCH:-1704067200}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_file="${2:-}"; shift 2 ;;
    --out-root) out_root="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$source_file" && -f "$source_file" ]] || { usage; exit 2; }

for cmd in awk chmod cpio date file find gzip mkdir mknod readelf readlink rm sed sha256sum sort stat; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required host tool missing: $cmd" >&2; exit 10; }
done

if ! command -v k1om-mpss-linux-gcc >/dev/null 2>&1 && [[ -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
fi
command -v k1om-mpss-linux-gcc >/dev/null 2>&1 || { echo "k1om-mpss-linux-gcc not found" >&2; exit 11; }

timestamp="$(date -u +%Y%m%d-%H%M%S)"
run_dir="$out_root/${name}-${timestamp}"
rootfs="$run_dir/rootfs"
image="$run_dir/${name}.cpio.gz"
manifest="$run_dir/${name}.manifest.tsv"
hashes="$run_dir/SHA256SUMS"
summary="$run_dir/build-summary.txt"

mkdir -p "$rootfs"
exec > >(tee "$run_dir/build.log") 2>&1

echo "== xpr minimal K1OM initramfs build =="
date -u
echo "source_file=$source_file"
echo "run_dir=$run_dir"

mkdir -p "$rootfs"/{dev,sbin,proc,sys,run,tmp}
chmod 0755 "$rootfs"/{dev,sbin,proc,sys,run,tmp}

static_log="$run_dir/static-link.log"
dynamic_log="$run_dir/dynamic-link.log"
link_mode="static"

if k1om-mpss-linux-gcc -Os -static -s "$source_file" -o "$rootfs/init" >"$static_log" 2>&1; then
  echo "static_link=passed"
else
  echo "static_link=failed"
  link_mode="dynamic"
  k1om-mpss-linux-gcc -Os "$source_file" -o "$rootfs/init" >"$dynamic_log" 2>&1
fi

chmod 0755 "$rootfs/init"
cp -a "$rootfs/init" "$rootfs/sbin/init"
chmod 0755 "$rootfs/sbin/init"

if [[ "$link_mode" == "dynamic" ]]; then
  interp="$(readelf -l "$rootfs/init" | awk '/Requesting program interpreter/ {gsub(/[][]/,"",$NF); print $NF; exit}')"
  [[ -n "$interp" ]] || { echo "dynamic init missing ELF interpreter" >&2; exit 12; }
  interp_rel="${interp#/}"
  interp_src=""
  for base in \
    /opt/mpss/3.4.10/sysroots/k1om-mpss-linux \
    "${K1OM_SYSROOT:-}" \
    /root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/rootfs/rootfs/opt/xeon-phi-revival; do
    [[ -n "$base" ]] || continue
    if [[ -e "$base/$interp_rel" || -L "$base/$interp_rel" ]]; then
      interp_src="$base/$interp_rel"
      break
    fi
  done
  [[ -n "$interp_src" ]] || { echo "could not locate interpreter $interp" >&2; exit 13; }
  mkdir -p "$rootfs/$(dirname "$interp_rel")"
  cp -aL "$interp_src" "$rootfs/$interp_rel"

  needed="$(readelf -d "$rootfs/init" | awk -F'[][]' '/NEEDED/ {print $2}')"
  for lib in $needed; do
    found=""
    while IFS= read -r candidate; do
      found="$candidate"
      break
    done < <(find /opt/mpss/3.4.10/sysroots/k1om-mpss-linux /root/xeon-phi-revival-local/uos-rc-builds/xpr-uos-rc-20260730-053125/rootfs/rootfs/opt/xeon-phi-revival -name "$lib" -print 2>/dev/null)
    [[ -n "$found" ]] || { echo "could not locate needed library $lib" >&2; exit 14; }
    case "$found" in
      */lib64/*) dest_dir="$rootfs/lib64" ;;
      */lib/*) dest_dir="$rootfs/lib" ;;
      *) dest_dir="$rootfs/lib64" ;;
    esac
    mkdir -p "$dest_dir"
    cp -aL "$found" "$dest_dir/$lib"
  done
fi

if [[ "$(id -u)" -eq 0 ]]; then
  mknod -m 600 "$rootfs/dev/console" c 5 1 2>/dev/null || true
  mknod -m 666 "$rootfs/dev/null" c 1 3 2>/dev/null || true
fi

echo "== init ELF =="
file "$rootfs/init"
readelf -h "$rootfs/init" > "$run_dir/init.readelf-h.txt"
readelf -l "$rootfs/init" > "$run_dir/init.readelf-l.txt"
readelf -d "$rootfs/init" > "$run_dir/init.readelf-d.txt" 2>&1 || true
readelf -h "$rootfs/init" | grep -E 'Class:|Machine:|Entry point'
readelf -l "$rootfs/init" | grep -E 'Requesting program interpreter' || true
readelf -d "$rootfs/init" | grep 'NEEDED' || true

machine="$(readelf -h "$rootfs/init" | awk -F: '/Machine:/ {sub(/^[ \t]+/,"",$2); print $2}')"
[[ "$machine" == "Intel K1OM" ]] || { echo "init ELF machine is not Intel K1OM: $machine" >&2; exit 15; }

(
  cd "$rootfs"
  test -x ./init
  test -x ./sbin/init
  find . -print0 | sort -z | cpio --null -o -H newc 2>"$run_dir/cpio.stderr" | gzip -9n > "$image"
)

gzip -t "$image"
gzip -l "$image" > "$run_dir/image.gzip.txt" 2>&1 || true
zcat "$image" | cpio -itv > "$run_dir/image.cpio-listing.txt" 2>&1
grep -Eq '(^| )init$' "$run_dir/image.cpio-listing.txt"
grep -Eq 'sbin/init$' "$run_dir/image.cpio-listing.txt"

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

sha256sum "$image" "$manifest" "$rootfs/init" > "$hashes"

cat > "$summary" <<EOF
status=built
run_dir=$run_dir
rootfs=$rootfs
image=$image
image_sha256=$(awk -v img="$image" '$2 == img {print $1}' "$hashes")
manifest=$manifest
manifest_sha256=$(awk -v mf="$manifest" '$2 == mf {print $1}' "$hashes")
init=$rootfs/init
init_sha256=$(awk -v init="$rootfs/init" '$2 == init {print $1}' "$hashes")
link_mode=$link_mode
elf_machine=$machine
elf_interpreter=$(awk '/Requesting program interpreter/ {gsub(/[][]/,"",$NF); print $NF; exit}' "$run_dir/init.readelf-l.txt")
image_size=$(du -h "$image" | awk '{print $1}')
gzip_info=$run_dir/image.gzip.txt
cpio_listing=$run_dir/image.cpio-listing.txt
EOF

cat "$summary"
cat "$run_dir/image.gzip.txt"
