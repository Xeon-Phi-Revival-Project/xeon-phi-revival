#!/usr/bin/env bash
# Assemble a relocatable K1OM C toolkit only from XPR-built toolchain outputs.
set -euo pipefail
repo_root=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)

usage() {
    cat <<'EOF'
Usage: package-standalone-xpr-k1om-toolkit.sh \
  --gcc-prefix DIR --binutils-prefix DIR --eglibc-stage DIR --linux-headers DIR --libgcc-dir DIR \
  --out DIR [--examples DIR] [--version VERSION]

All inputs must be outputs of the source-accounted XPR builders.  This script
intentionally has no MPSS SDK or /opt/mpss input.
EOF
}

gcc_prefix= binutils_prefix= eglibc_stage= linux_headers= libgcc_dir= out= examples="$repo_root/examples/k1om" version=0.1.0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --gcc-prefix) gcc_prefix=$2; shift 2 ;;
        --binutils-prefix) binutils_prefix=$2; shift 2 ;;
        --eglibc-stage) eglibc_stage=$2; shift 2 ;;
        --linux-headers) linux_headers=$2; shift 2 ;;
        --libgcc-dir) libgcc_dir=$2; shift 2 ;;
        --out) out=$2; shift 2 ;;
        --examples) examples=$2; shift 2 ;;
        --version) version=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) usage >&2; exit 2 ;;
    esac
done

for required in "$gcc_prefix" "$binutils_prefix" "$eglibc_stage" "$linux_headers" "$libgcc_dir" "$out"; do
    [[ -n "$required" ]] || { usage >&2; exit 2; }
done
[[ ! -e "$out" ]] || { echo "output already exists: $out" >&2; exit 1; }

gcc=$(find "$gcc_prefix/bin" -maxdepth 1 -type f -name 'k1om-mpss-linux-gcc' -print -quit)
[[ -x "$gcc" ]] || { echo "missing source-built K1OM GCC" >&2; exit 1; }
for tool in as ld ar ranlib nm objdump objcopy readelf strip; do
    [[ -x "$binutils_prefix/bin/$tool" ]] || { echo "missing source-built binutils tool: $tool" >&2; exit 1; }
done
[[ -d "$eglibc_stage/usr/include" ]] || { echo "missing source-built eglibc headers" >&2; exit 1; }
[[ -f "$linux_headers/linux/errno.h" ]] || { echo "missing K1OM Linux UAPI headers" >&2; exit 1; }
[[ -d "$examples" ]] || { echo "missing K1OM examples: $examples" >&2; exit 1; }
eglibc_libdir="$eglibc_stage/lib"
[[ -d "$eglibc_libdir" ]] || eglibc_libdir="$eglibc_stage/usr/lib"
eglibc_dev_libdir="$eglibc_stage/usr/lib"
[[ -d "$eglibc_dev_libdir" ]] || eglibc_dev_libdir="$eglibc_libdir"
libgcc_install=$(dirname "$(dirname "$libgcc_dir")")
libgcc_support="$libgcc_install/lib/gcc/k1om-mpss-linux/5.1.1"
[[ -f "$libgcc_support/libgcc.a" && -f "$libgcc_support/crtbegin.o" ]] || {
    echo "missing source-built libgcc development support" >&2; exit 1;
}
[[ -f "$libgcc_dir/libgcc_s.so.1" ]] || { echo "missing source-built libgcc_s.so.1" >&2; exit 1; }
[[ -d "$gcc_prefix/lib/gcc/k1om-mpss-linux" ]] || { echo "missing GCC support files" >&2; exit 1; }
[[ -x "$gcc_prefix/libexec/gcc/k1om-mpss-linux/5.1.1/cc1" ]] || {
    echo "missing installed source-built GCC frontend" >&2; exit 1;
}

root="$out/xpr-k1om-toolkit-$version-linux-x86_64"
mkdir -p "$root/bin" "$root/lib" "$root/libexec" "$root/sysroot/usr" \
    "$root/examples" "$root/metadata" "$root/LICENSES"

# GCC is relocatable through GCC_EXEC_PREFIX; all target binutils are named
# explicitly so GCC never falls through to a host assembler or linker.
cp -a "$gcc" "$root/libexec/k1om-mpss-linux-gcc"
cp -a "$gcc_prefix/lib/gcc" "$root/lib/"
cp -a "$gcc_prefix/libexec/gcc" "$root/libexec/"
for tool in as ld ar ranlib nm objdump objcopy readelf strip; do
    cp -a "$binutils_prefix/bin/$tool" "$root/libexec/k1om-mpss-linux-$tool"
    ln -s "k1om-mpss-linux-$tool" "$root/libexec/$tool"
done
cp -a "$gcc_prefix/k1om-mpss-linux" "$root/" 2>/dev/null || true

cp -a "$eglibc_stage/usr/include" "$root/sysroot/usr/"
cp -a "$linux_headers/." "$root/sysroot/usr/include/"
cp -a "$eglibc_libdir" "$root/sysroot/lib64"
cp -a "$eglibc_dev_libdir/." "$root/sysroot/lib64/"
ln -s lib64 "$root/sysroot/lib"
ln -s ../lib64 "$root/sysroot/usr/lib"
ln -s ../lib64 "$root/sysroot/usr/lib64"
cp -a "$libgcc_dir/libgcc_s.so.1" "$root/sysroot/lib64/"
ln -sf libgcc_s.so.1 "$root/sysroot/lib64/libgcc_s.so"
cp -a "$libgcc_support/." "$root/lib/gcc/k1om-mpss-linux/5.1.1/"

for tool in gcc cpp as ld ar ranlib nm objdump objcopy readelf strip; do
    cat > "$root/bin/xpr-$tool" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
root=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
tool=$(basename "$0" | sed 's/^xpr-//')
case "$tool" in
  gcc) link_libgcc=yes
       for arg in "$@"; do
         case "$arg" in -nostdlib|-nodefaultlibs) link_libgcc=no ;; esac
       done
       extra=()
       [[ "$link_libgcc" == yes ]] && extra=(-lgcc_s)
       exec env GCC_EXEC_PREFIX="$root/libexec/gcc/" "$root/libexec/k1om-mpss-linux-gcc" \
      -B"$root/libexec/gcc/k1om-mpss-linux/5.1.1" -B"$root/lib/gcc/k1om-mpss-linux/5.1.1" -B"$root/libexec" --sysroot="$root/sysroot" \
      -isystem "$root/sysroot/usr/include" -L"$root/sysroot/usr/lib64" -L"$root/sysroot/lib64" \
      -Wl,--dynamic-linker=/lib64/ld-linux-k1om.so.2 -Wl,-rpath,/lib64 \
      -Wl,--no-as-needed "$@" "${extra[@]}" ;;
  cpp) exec env GCC_EXEC_PREFIX="$root/libexec/gcc/" "$root/libexec/k1om-mpss-linux-gcc" \
      -B"$root/libexec/gcc/k1om-mpss-linux/5.1.1" -B"$root/lib/gcc/k1om-mpss-linux/5.1.1" -B"$root/libexec" --sysroot="$root/sysroot" -E "$@" ;;
  *) exec "$root/libexec/k1om-mpss-linux-$tool" "$@" ;;
esac
EOF
    chmod 755 "$root/bin/xpr-$tool"
done
cat > "$root/bin/xpr-validate" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
[[ $# -eq 1 ]] || { echo "usage: xpr-validate BINARY" >&2; exit 2; }
root=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
readelf="$root/bin/xpr-readelf"
"$readelf" -h "$1" | grep -F 'Machine:                           Intel K1OM'
"$readelf" -l "$1" | grep -F 'Requesting program interpreter: /lib64/ld-linux-k1om.so.2'
"$readelf" -d "$1" | grep -F 'Shared library: [libgcc_s.so.1]'
if "$readelf" -d "$1" | grep -E '/opt/mpss|mpss-sdk|/usr/lib64|/usr/include' >/dev/null; then
    echo "host or MPSS path leaked into dynamic metadata" >&2
    exit 1
fi
echo XPR_K1OM_ELF=PASS
EOF
chmod 755 "$root/bin/xpr-validate"
cat > "$root/env.sh" <<'EOF'
root=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")" && pwd)
export PATH="$root/bin:$PATH"
EOF
cp -a "$examples/." "$root/examples/"

cat > "$root/README.md" <<EOF
# XPR K1OM Toolkit $version

This candidate contains source-built K1OM GCC/binutils, an XPR eglibc sysroot,
and libgcc. It does not consume an Intel MPSS SDK at use time.

\`\`\`bash
source env.sh
xpr-gcc examples/hello.c -o hello
xpr-validate hello
\`\`\`
EOF
{
    echo "toolkit_version=$version"
    echo "gcc_sha256=$(sha256sum "$root/libexec/k1om-mpss-linux-gcc" | awk '{print $1}')"
    echo "libgcc_s_sha256=$(sha256sum "$root/sysroot/lib64/libgcc_s.so.1" | awk '{print $1}')"
    find "$root" -type f -print0 | sort -z | xargs -0 sha256sum
} > "$root/metadata/SHA256SUMS"
while IFS= read -r -d '' candidate; do
    if file -b "$candidate" | grep -q 'ELF'; then
        if grep -a -E '/opt/mpss|mpss-sdk' "$candidate" >/dev/null; then
            echo "MPSS SDK path leaked into ELF: $candidate" >&2
            exit 1
        fi
    fi
done < <(find "$root" -type f -print0)
echo "XPR_STANDALONE_TOOLKIT_STAGING=PASS"
echo "$root"
