#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-stockderived-min-k1om-initramfs.sh --source FILE [--stock-cpio FILE] [--out-root DIR] [--name NAME]

Build a private stock-derived MPSS Base CPIO diagnostic image by replacing only
/init and /sbin/init with the minimal K1OM init program. This is a narrow
handoff test and the output is not redistributable because it contains stock
MPSS card-side userspace.
USAGE
}

source_file=""
stock_cpio="/usr/share/mpss/boot/initramfs-knightscorner.cpio.gz"
out_root="${HOME}/xeon-phi-revival-local/uos-min-init-builds"
name="xpr-min-init-stockderived"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_file="${2:-}"; shift 2 ;;
    --stock-cpio) stock_cpio="${2:-}"; shift 2 ;;
    --out-root) out_root="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -n "$source_file" && -f "$source_file" ]] || { usage; exit 2; }
[[ -f "$stock_cpio" ]] || { echo "stock cpio missing: $stock_cpio" >&2; exit 3; }

for cmd in awk chmod cpio date file find gzip mkdir readelf rm sha256sum sort stat zcat; do
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
min_init="$run_dir/xpr_min_init"

mkdir -p "$rootfs"
exec > >(tee "$run_dir/build.log") 2>&1

echo "== stock-derived minimal K1OM initramfs build =="
date -u
echo "source_file=$source_file"
echo "stock_cpio=$stock_cpio"
echo "run_dir=$run_dir"
echo "warning=generated image contains stock MPSS userspace and must stay private"

k1om-mpss-linux-gcc -Os -static -s "$source_file" -o "$min_init" >"$run_dir/static-link.log" 2>&1
chmod 0755 "$min_init"

echo "== unpack stock Base CPIO =="
(
  cd "$rootfs"
  zcat "$stock_cpio" | cpio -idm --quiet --no-absolute-filenames
)

mkdir -p "$run_dir/replaced"
cp -a "$rootfs/init" "$run_dir/replaced/init.stock"
cp -a "$rootfs/sbin/init" "$run_dir/replaced/sbin-init.stock"
ls -l "$rootfs/init" "$rootfs/sbin/init" > "$run_dir/replaced/original-init-ls.txt"

rm -f "$rootfs/init" "$rootfs/sbin/init"
cp -a "$min_init" "$rootfs/init"
cp -a "$min_init" "$rootfs/sbin/init"
chmod 0755 "$rootfs/init" "$rootfs/sbin/init"

echo "== init ELF =="
file "$rootfs/init"
readelf -h "$rootfs/init" > "$run_dir/init.readelf-h.txt"
readelf -l "$rootfs/init" > "$run_dir/init.readelf-l.txt"
readelf -d "$rootfs/init" > "$run_dir/init.readelf-d.txt" 2>&1 || true
readelf -h "$rootfs/init" | grep -E 'Class:|Machine:|Entry point'
readelf -l "$rootfs/init" | grep -E 'Requesting program interpreter' || true
readelf -d "$rootfs/init" | grep 'NEEDED' || true

machine="$(readelf -h "$rootfs/init" | awk -F: '/Machine:/ {sub(/^[ \t]+/,"",$2); print $2}')"
[[ "$machine" == "Intel K1OM" ]] || { echo "init ELF machine is not Intel K1OM: $machine" >&2; exit 12; }

echo "== replaced path hashes =="
sha256sum "$rootfs/init" "$rootfs/sbin/init" "$run_dir/replaced/init.stock"
if [[ -f "$run_dir/replaced/sbin-init.stock" ]]; then
  sha256sum "$run_dir/replaced/sbin-init.stock"
else
  printf 'sbin-init.stock_link_target=%s\n' "$(readlink "$run_dir/replaced/sbin-init.stock" 2>/dev/null || echo '<not-a-symlink>')"
fi

(
  cd "$rootfs"
  test -x ./init
  test -x ./sbin/init
  test -e ./sbin/init.sysvinit
  find . -print0 | sort -z | cpio --null -o -H newc 2>"$run_dir/cpio.stderr" | gzip -9n > "$image"
)

gzip -t "$image"
gzip -l "$image" > "$run_dir/image.gzip.txt" 2>&1 || true
zcat "$image" | cpio -itv > "$run_dir/image.cpio-listing.txt" 2>&1
grep -Eq '(^| )init$' "$run_dir/image.cpio-listing.txt"
grep -Eq 'sbin/init$' "$run_dir/image.cpio-listing.txt"
grep -Eq 'sbin/init.sysvinit$' "$run_dir/image.cpio-listing.txt"
grep -Eq 'etc/inittab$' "$run_dir/image.cpio-listing.txt"

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

sha256sum "$image" "$manifest" "$rootfs/init" "$stock_cpio" > "$hashes"

cat > "$run_dir/replaced-paths.txt" <<EOF
replaced_only:
- /init
- /sbin/init
left_stock_present:
- /sbin/init.sysvinit
- /etc/inittab
private_reason=contains stock MPSS Base CPIO userspace
EOF

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
link_mode=static
elf_machine=$machine
elf_interpreter=$(awk '/Requesting program interpreter/ {gsub(/[][]/,"",$NF); print $NF; exit}' "$run_dir/init.readelf-l.txt")
stock_cpio=$stock_cpio
stock_cpio_sha256=$(awk -v stock="$stock_cpio" '$2 == stock {print $1}' "$hashes")
image_size=$(du -h "$image" | awk '{print $1}')
gzip_info=$run_dir/image.gzip.txt
cpio_listing=$run_dir/image.cpio-listing.txt
replaced_paths=$run_dir/replaced-paths.txt
redistribution=private-stock-derived-do-not-publish
EOF

cat "$summary"
cat "$run_dir/image.gzip.txt"
