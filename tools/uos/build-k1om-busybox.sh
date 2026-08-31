#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: build-k1om-busybox.sh --source-dir DIR --config FILE --out FILE [--patch FILE] [--cross-compile PREFIX] [--source-archive FILE] [--work-root DIR] [--jobs N]

Build a static K1OM BusyBox from a separately obtained, hash-verified upstream
source tree. No MPSS or stock BusyBox files are copied into the output.
EOF
}

source_dir=""; config=""; out=""; source_archive=""; patch_file=""; cross_compile="k1om-mpss-linux-"; work_root="${HOME}/xeon-phi-revival-local/busybox-builds"; jobs=2
while [[ $# -gt 0 ]]; do
  case "$1" in
    --source-dir) source_dir="${2:-}"; shift 2 ;;
    --config) config="${2:-}"; shift 2 ;;
    --out) out="${2:-}"; shift 2 ;;
    --cross-compile) cross_compile="${2:-}"; shift 2 ;;
    --source-archive) source_archive="${2:-}"; shift 2 ;;
    --patch) patch_file="${2:-}"; shift 2 ;;
    --work-root) work_root="${2:-}"; shift 2 ;;
    --jobs) jobs="${2:-}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 2 ;;
  esac
done
[[ -f "$source_dir/Makefile" && -f "$config" && -n "$out" ]] || { usage; exit 2; }
[[ -z "$source_archive" || -f "$source_archive" ]] || { echo "missing source archive: $source_archive" >&2; exit 3; }
[[ -z "$patch_file" || -f "$patch_file" ]] || { echo "missing BusyBox patch: $patch_file" >&2; exit 3; }
if ! command -v "${cross_compile}gcc" >/dev/null 2>&1 && [[ "$cross_compile" == "k1om-mpss-linux-" && -f /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux ]]; then
  # shellcheck disable=SC1091
  source /opt/mpss/3.4.10/environment-setup-k1om-mpss-linux
fi
command -v "${cross_compile}gcc" >/dev/null 2>&1 || { echo 'K1OM compiler unavailable' >&2; exit 10; }

run_dir="$work_root/busybox-$(date -u +%Y%m%d-%H%M%S)"
build_dir="$run_dir/source"
mkdir -p "$run_dir" "$(dirname "$out")"
cp -a "$source_dir" "$build_dir"
if [[ -n "$patch_file" ]]; then
  patch -d "$build_dir" -p1 --batch < "$patch_file"
fi
cp "$config" "$build_dir/.config"
(
  cd "$build_dir"
  make ARCH=k1om CROSS_COMPILE="$cross_compile" oldconfig > "$run_dir/oldconfig.log" 2>&1
  make -j"$jobs" ARCH=k1om CROSS_COMPILE="$cross_compile" > "$run_dir/build.log" 2>&1
)
"${cross_compile}readelf" -h "$build_dir/busybox" | grep -q 'Machine:.*Intel K1OM' || { echo 'BusyBox is not K1OM' >&2; exit 11; }
"${cross_compile}readelf" -d "$build_dir/busybox" 2>/dev/null | grep -q NEEDED && { echo 'BusyBox is not static' >&2; exit 12; } || true
cp -a "$build_dir/busybox" "$out"
{
  printf 'source_dir=%s\n' "$(readlink -f "$source_dir")"
  [[ -z "$source_archive" ]] || printf 'source_archive_sha256=%s\n' "$(sha256sum "$source_archive" | awk '{print $1}')"
  [[ -z "$patch_file" ]] || printf 'patch_sha256=%s\n' "$(sha256sum "$patch_file" | awk '{print $1}')"
  printf 'config_sha256=%s\n' "$(sha256sum "$config" | awk '{print $1}')"
  printf 'binary_sha256=%s\n' "$(sha256sum "$out" | awk '{print $1}')"
  printf 'compiler=%s\n' "$("${cross_compile}gcc" --version | head -n1)"
} > "$run_dir/provenance.txt"
cat "$run_dir/provenance.txt"
