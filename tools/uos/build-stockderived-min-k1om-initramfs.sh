#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'USAGE'
usage:
  build-stockderived-min-k1om-initramfs.sh [--source FILE] [--replace MODE] [--stock-cpio FILE] [--out-root DIR] [--name NAME]

Build a private stock-derived MPSS Base CPIO diagnostic image by replacing one
small init boundary with the minimal K1OM init program. This is a narrow
handoff test and the output is not redistributable because it contains stock
MPSS card-side userspace.

replace modes:
  init-and-sbin-init      replace /init and /sbin/init
  sbin-init              preserve /init, replace only /sbin/init
  sbin-init-sysvinit     preserve /init and /sbin/init, replace only
                          /sbin/init.sysvinit
  instrument-stock-init  insert a marker block after stock /init shebang and
                          preserve the rest of stock /init behavior
  instrument-stock-handoff
                         insert a marker block immediately before stock /init
                          execs switch_root, preserving the original exec
  instrument-new-root-inventory
                         write a bounded inventory of the prepared /new_root
                          immediately before switch_root, preserving the exec
  instrument-new-root-init-wrapper
                         install a temporary wrapper at /new_root/sbin/init
                          that records PID 1 and execs stock init.sysvinit
USAGE
}

source_file=""
stock_cpio="/usr/share/mpss/boot/initramfs-knightscorner.cpio.gz"
out_root="${HOME}/xeon-phi-revival-local/uos-min-init-builds"
name="xpr-min-init-stockderived"
replace_mode="init-and-sbin-init"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source) source_file="${2:-}"; shift 2 ;;
    --replace) replace_mode="${2:-}"; shift 2 ;;
    --stock-cpio) stock_cpio="${2:-}"; shift 2 ;;
    --out-root) out_root="${2:-}"; shift 2 ;;
    --name) name="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

[[ -f "$stock_cpio" ]] || { echo "stock cpio missing: $stock_cpio" >&2; exit 3; }
case "$replace_mode" in
  init-and-sbin-init|sbin-init|sbin-init-sysvinit|instrument-stock-init|instrument-stock-handoff|instrument-new-root-inventory|instrument-new-root-init-wrapper) ;;
  *) echo "invalid --replace mode: $replace_mode" >&2; usage; exit 2 ;;
esac
if [[ "$replace_mode" != "instrument-stock-init" && "$replace_mode" != "instrument-stock-handoff" && "$replace_mode" != "instrument-new-root-inventory" && "$replace_mode" != "instrument-new-root-init-wrapper" ]]; then
  [[ -n "$source_file" && -f "$source_file" ]] || { usage; exit 2; }
fi

for cmd in awk chmod cpio date file find gzip mkdir readelf rm sha256sum sort stat zcat; do
  command -v "$cmd" >/dev/null 2>&1 || { echo "required host tool missing: $cmd" >&2; exit 10; }
done

if [[ "$replace_mode" != "instrument-stock-init" && "$replace_mode" != "instrument-stock-handoff" && "$replace_mode" != "instrument-new-root-inventory" && "$replace_mode" != "instrument-new-root-init-wrapper" ]] && ! command -v k1om-mpss-linux-gcc >/dev/null 2>&1 && [[ -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
fi
if [[ "$replace_mode" != "instrument-stock-init" && "$replace_mode" != "instrument-stock-handoff" && "$replace_mode" != "instrument-new-root-inventory" && "$replace_mode" != "instrument-new-root-init-wrapper" ]]; then
  command -v k1om-mpss-linux-gcc >/dev/null 2>&1 || { echo "k1om-mpss-linux-gcc not found" >&2; exit 11; }
fi

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
echo "replace_mode=$replace_mode"
echo "warning=generated image contains stock MPSS userspace and must stay private"

if [[ "$replace_mode" != "instrument-stock-init" && "$replace_mode" != "instrument-stock-handoff" && "$replace_mode" != "instrument-new-root-inventory" && "$replace_mode" != "instrument-new-root-init-wrapper" ]]; then
  k1om-mpss-linux-gcc -Os -static -s "$source_file" -o "$min_init" >"$run_dir/static-link.log" 2>&1
  chmod 0755 "$min_init"
fi

echo "== unpack stock Base CPIO =="
(
  cd "$rootfs"
  zcat "$stock_cpio" | cpio -idm --quiet --no-absolute-filenames
)

mkdir -p "$run_dir/replaced"
for path in init sbin/init sbin/init.sysvinit; do
  cp -a "$rootfs/$path" "$run_dir/replaced/${path//\//-}.stock"
done
ls -l "$rootfs/init" "$rootfs/sbin/init" "$rootfs/sbin/init.sysvinit" > "$run_dir/replaced/original-init-ls.txt"

case "$replace_mode" in
  init-and-sbin-init)
    rm -f "$rootfs/init" "$rootfs/sbin/init"
    cp -a "$min_init" "$rootfs/init"
    cp -a "$min_init" "$rootfs/sbin/init"
    chmod 0755 "$rootfs/init" "$rootfs/sbin/init"
    inspect_path="$rootfs/init"
    ;;
  sbin-init)
    rm -f "$rootfs/sbin/init"
    cp -a "$min_init" "$rootfs/sbin/init"
    chmod 0755 "$rootfs/sbin/init"
    inspect_path="$rootfs/sbin/init"
    ;;
  sbin-init-sysvinit)
    rm -f "$rootfs/sbin/init.sysvinit"
    cp -a "$min_init" "$rootfs/sbin/init.sysvinit"
    chmod 0755 "$rootfs/sbin/init.sysvinit"
    inspect_path="$rootfs/sbin/init.sysvinit"
    ;;
  instrument-stock-init)
    stock_init="$run_dir/replaced/init.stock"
    tmp_init="$run_dir/init.instrumented"
    {
      IFS= read -r shebang < "$stock_init"
      printf '%s\n' "$shebang"
      cat <<'EOF'
# XPR minimal stock-init instrumentation. Keep this block side-effect-light:
# emit evidence, then continue into the original stock init wrapper.
xpr_emit_init_marker() {
  {
    echo XPR_MIN_INIT_ENTERED
    echo PID=$$
    echo XPR_MIN_INIT_IDLE
  } > /xpr-stock-init-marker.txt 2>/dev/null || true
  mkdir -p /tmp 2>/dev/null || true
  {
    echo XPR_MIN_INIT_ENTERED
    echo PID=$$
    echo XPR_MIN_INIT_IDLE
  } > /tmp/xpr-stock-init-marker.txt 2>/dev/null || true
  for xpr_console in /dev/console /dev/hvc0 /dev/ttyMIC0; do
    if [ -e "$xpr_console" ]; then
      {
        echo XPR_MIN_INIT_ENTERED
        echo PID=$$
        echo XPR_MIN_INIT_IDLE
      } > "$xpr_console" 2>&1 || true
    fi
  done
  {
    echo XPR_MIN_INIT_ENTERED
    echo PID=$$
    echo XPR_MIN_INIT_IDLE
  } || true
}
xpr_emit_init_marker
unset -f xpr_emit_init_marker 2>/dev/null || true
unset xpr_console 2>/dev/null || true
EOF
      tail -n +2 "$stock_init"
    } > "$tmp_init"
    cp -a "$tmp_init" "$rootfs/init"
    chmod --reference="$stock_init" "$rootfs/init"
    inspect_path="$rootfs/init"
    ;;
  instrument-stock-handoff)
    stock_init="$run_dir/replaced/init.stock"
    tmp_init="$run_dir/init.instrumented"
    awk '
      /^exec[ \t]+\/sbin\/switch_root[ \t]+\/new_root[ \t]+\/sbin\/init([ \t]|$)/ && !inserted {
        print "# XPR stock-init handoff instrumentation. Preserve the following exec line."
        print "xpr_emit_handoff_marker() {"
        print "  xpr_handoff_cmd=\"/sbin/switch_root /new_root /sbin/init\""
        print "  for xpr_marker in /xpr-stock-init-handoff.txt /tmp/xpr-stock-init-handoff.txt /new_root/xpr-stock-init-handoff.txt; do"
        print "    {"
        print "      echo XPR_MIN_INIT_ENTERED"
        print "      echo XPR_STOCK_INIT_HANDOFF"
        print "      echo PID=$$"
        print "      echo CMD=\"$xpr_handoff_cmd\""
        print "      echo XPR_MIN_INIT_IDLE"
        print "    } > \"$xpr_marker\" 2>/dev/null || true"
        print "  done"
        print "  for xpr_console in /dev/console /dev/hvc0 /dev/ttyMIC0 /dev/kmsg; do"
        print "    if [ -e \"$xpr_console\" ]; then"
        print "      {"
        print "        echo XPR_MIN_INIT_ENTERED"
        print "        echo XPR_STOCK_INIT_HANDOFF"
        print "        echo PID=$$"
        print "        echo CMD=\"$xpr_handoff_cmd\""
        print "        echo XPR_MIN_INIT_IDLE"
        print "      } > \"$xpr_console\" 2>&1 || true"
        print "    fi"
        print "  done"
        print "}"
        print "xpr_emit_handoff_marker"
        print "unset -f xpr_emit_handoff_marker 2>/dev/null || true"
        print "unset xpr_console xpr_handoff_cmd xpr_marker 2>/dev/null || true"
        inserted=1
      }
      { print }
      END {
        if (!inserted) {
          print "xpr_error=no-switch-root-exec-found" > "/dev/stderr"
          exit 23
        }
      }
    ' "$stock_init" > "$tmp_init"
    cp -a "$tmp_init" "$rootfs/init"
    chmod --reference="$stock_init" "$rootfs/init"
    inspect_path="$rootfs/init"
    ;;
  instrument-new-root-inventory)
    stock_init="$run_dir/replaced/init.stock"
    tmp_init="$run_dir/init.instrumented"
    awk '
      /^exec[ \t]+\/sbin\/switch_root[ \t]+\/new_root[ \t]+\/sbin\/init([ \t]|$)/ && !inserted {
        print "# XPR /new_root inventory. Preserve the following switch_root exec."
        print "xpr_inventory_new_root() {"
        print "  xpr_inventory=/new_root/xpr-new-root-inventory.txt"
        print "  {"
        print "    echo XPR_MIN_INIT_ENTERED"
        print "    echo XPR_NEW_ROOT_INVENTORY"
        print "    echo PID=$$"
        print "    echo PWD=\"$(pwd)\""
        print "    echo NEW_ROOT_LS_BEGIN"
        print "    ls -ld /new_root /new_root/sbin /new_root/sbin/init /new_root/sbin/init.sysvinit 2>&1"
        print "    echo NEW_ROOT_INIT_LINK_BEGIN"
        print "    readlink /new_root/sbin/init 2>&1 || true"
        print "    echo NEW_ROOT_TOP_LEVEL_BEGIN"
        print "    ls -1 /new_root 2>&1"
        print "    echo NEW_ROOT_MOUNTS_BEGIN"
        print "    mount 2>&1 || cat /proc/mounts 2>&1 || true"
        print "    echo NEW_ROOT_INIT_STAT_BEGIN"
        print "    stat /new_root/sbin/init /new_root/sbin/init.sysvinit 2>&1 || true"
        print "    echo XPR_MIN_INIT_IDLE"
        print "  } > \"$xpr_inventory\" 2>&1 || true"
        print "  cp \"$xpr_inventory\" /tmp/xpr-new-root-inventory.txt 2>/dev/null || true"
        print "}"
        print "xpr_inventory_new_root"
        print "unset -f xpr_inventory_new_root 2>/dev/null || true"
        print "unset xpr_inventory 2>/dev/null || true"
        inserted=1
      }
      { print }
      END {
        if (!inserted) {
          print "xpr_error=no-switch-root-exec-found" > "/dev/stderr"
          exit 23
        }
      }
    ' "$stock_init" > "$tmp_init"
    cp -a "$tmp_init" "$rootfs/init"
    chmod --reference="$stock_init" "$rootfs/init"
    inspect_path="$rootfs/init"
    ;;
  instrument-new-root-init-wrapper)
    stock_init="$run_dir/replaced/init.stock"
    tmp_init="$run_dir/init.instrumented"
    awk '
      /^exec[ \t]+\/sbin\/switch_root[ \t]+\/new_root[ \t]+\/sbin\/init([ \t]|$)/ && !inserted {
        print "# XPR temporary /new_root init wrapper. Preserve the following switch_root exec."
        print "xpr_install_new_root_init_wrapper() {"
        print "  xpr_root=/new_root"
        print "  xpr_stock_init=$xpr_root/sbin/init.sysvinit"
        print "  xpr_saved_init=$xpr_root/sbin/init.sysvinit.xpr-stock"
        print "  test -x \"$xpr_stock_init\" || return 0"
        print "  mv \"$xpr_stock_init\" \"$xpr_saved_init\" || return 0"
        print "  cat > \"$xpr_stock_init\" <<'\''XPR_NEW_ROOT_INIT_WRAPPER'\''"
        print "#!/bin/sh"
        print "{"
        print "  echo XPR_MIN_INIT_ENTERED"
        print "  echo XPR_NEW_ROOT_INIT_WRAPPER"
        print "  echo PID=$$"
        print "  echo STOCK_INIT=/sbin/init.sysvinit.xpr-stock"
        print "  echo XPR_MIN_INIT_IDLE"
        print "} > /xpr-new-root-init-wrapper.txt 2>&1 || true"
        print "exec /sbin/init.sysvinit.xpr-stock \"$@\""
        print "XPR_NEW_ROOT_INIT_WRAPPER"
        print "  chmod 0755 \"$xpr_stock_init\" || return 0"
        print "}"
        print "xpr_install_new_root_init_wrapper"
        print "unset -f xpr_install_new_root_init_wrapper 2>/dev/null || true"
        print "unset xpr_root xpr_stock_init xpr_saved_init 2>/dev/null || true"
        inserted=1
      }
      { print }
      END {
        if (!inserted) {
          print "xpr_error=no-switch-root-exec-found" > "/dev/stderr"
          exit 23
        }
      }
    ' "$stock_init" > "$tmp_init"
    cp -a "$tmp_init" "$rootfs/init"
    chmod --reference="$stock_init" "$rootfs/init"
    inspect_path="$rootfs/init"
    ;;
esac

if [[ "$replace_mode" == "instrument-stock-init" || "$replace_mode" == "instrument-stock-handoff" || "$replace_mode" == "instrument-new-root-inventory" || "$replace_mode" == "instrument-new-root-init-wrapper" ]]; then
  echo "== instrumented init script =="
  file "$inspect_path"
  head -40 "$inspect_path" > "$run_dir/init.instrumented-head.txt"
  machine="script"
else
  echo "== init ELF =="
  file "$inspect_path"
  readelf -h "$inspect_path" > "$run_dir/init.readelf-h.txt"
  readelf -l "$inspect_path" > "$run_dir/init.readelf-l.txt"
  readelf -d "$inspect_path" > "$run_dir/init.readelf-d.txt" 2>&1 || true
  readelf -h "$inspect_path" | grep -E 'Class:|Machine:|Entry point'
  readelf -l "$inspect_path" | grep -E 'Requesting program interpreter' || true
  readelf -d "$inspect_path" | grep 'NEEDED' || true

  machine="$(readelf -h "$inspect_path" | awk -F: '/Machine:/ {sub(/^[ \t]+/,"",$2); print $2}')"
  [[ "$machine" == "Intel K1OM" ]] || { echo "init ELF machine is not Intel K1OM: $machine" >&2; exit 12; }
fi

echo "== replaced path hashes =="
sha256sum "$inspect_path"
if [[ -f "$min_init" ]]; then
  sha256sum "$min_init"
fi
find "$run_dir/replaced" -maxdepth 1 -type f -print0 | sort -z | xargs -0 sha256sum
find "$run_dir/replaced" -maxdepth 1 -type l -printf '%f_link_target=%l\n' | sort

(
  cd "$rootfs"
  test -x ./init
  if [[ -L ./sbin/init ]]; then
    target="$(readlink ./sbin/init)"
    test -x ".${target}"
  else
    test -x ./sbin/init
  fi
  test -e ./sbin/init.sysvinit
  find . -print0 | sort -z | cpio --null -o -H newc 2>"$run_dir/cpio.stderr" | gzip -9n > "$image"
)

gzip -t "$image"
gzip -l "$image" > "$run_dir/image.gzip.txt" 2>&1 || true
zcat "$image" | cpio -itv > "$run_dir/image.cpio-listing.txt" 2>&1
grep -Eq '(^| )init$' "$run_dir/image.cpio-listing.txt"
grep -Eq '(^| )sbin/init( ->|$)' "$run_dir/image.cpio-listing.txt"
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
replace_mode=$replace_mode
replaced_only:
$(case "$replace_mode" in
  init-and-sbin-init) printf '%s\n%s\n' '- /init' '- /sbin/init' ;;
  sbin-init) printf '%s\n' '- /sbin/init' ;;
  sbin-init-sysvinit) printf '%s\n' '- /sbin/init.sysvinit' ;;
  instrument-stock-init) printf '%s\n' '- /init (entry instrumented only)' ;;
  instrument-stock-handoff) printf '%s\n' '- /init (handoff instrumented only)' ;;
esac)
left_stock_present:
$(case "$replace_mode" in
  init-and-sbin-init) printf '%s\n%s\n' '- /sbin/init.sysvinit' '- /etc/inittab' ;;
  sbin-init) printf '%s\n%s\n%s\n' '- /init' '- /sbin/init.sysvinit' '- /etc/inittab' ;;
  sbin-init-sysvinit) printf '%s\n%s\n%s\n' '- /init' '- /sbin/init' '- /etc/inittab' ;;
  instrument-stock-init) printf '%s\n%s\n%s\n' '- /sbin/init' '- /sbin/init.sysvinit' '- /etc/inittab' ;;
  instrument-stock-handoff) printf '%s\n%s\n%s\n' '- /sbin/init' '- /sbin/init.sysvinit' '- /etc/inittab' ;;
esac)
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
replace_mode=$replace_mode
init=$inspect_path
init_sha256=$(sha256sum "$inspect_path" | awk '{print $1}')
link_mode=$(if [[ "$replace_mode" == "instrument-stock-init" || "$replace_mode" == "instrument-stock-handoff" ]]; then echo stock-shell-script; else echo static; fi)
elf_machine=$machine
elf_interpreter=$(if [[ -f "$run_dir/init.readelf-l.txt" ]]; then awk '/Requesting program interpreter/ {gsub(/[][]/,"",$NF); print $NF; exit}' "$run_dir/init.readelf-l.txt"; fi)
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
