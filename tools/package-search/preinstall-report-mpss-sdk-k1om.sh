#!/usr/bin/env bash
set -euo pipefail

package="${1:-${MPSS_EXTRACT_ROOT:-${HOME}/mpss-extract}/mpss-3.4.10/mpss-sdk-k1om-3.4.10-1.x86_64.rpm}"
out_dir="${2:-${XEON_PHI_LOCAL_ROOT:-${HOME}/xeon-phi-revival-local}/public-metadata/preinstall/mpss-sdk-k1om-3.4.10}"

mkdir -p "${out_dir}"

if [[ ! -f "${package}" ]]; then
  echo "package not found: ${package}" >&2
  exit 2
fi

sha256sum "${package}" > "${out_dir}/sha256.txt"
rpm --checksig -v "${package}" > "${out_dir}/checksig.txt" 2>&1 || true
rpm -qip "${package}" > "${out_dir}/info.txt" 2>&1 || true
rpm -qRp "${package}" > "${out_dir}/requires.txt" 2>&1 || true
rpm -qPp "${package}" > "${out_dir}/provides-qPp.txt" 2>&1 || true
rpm -qp --provides "${package}" > "${out_dir}/provides.txt" 2>&1 || true
rpm -qp --conflicts "${package}" > "${out_dir}/conflicts.txt" 2>&1 || true
rpm -qp --obsoletes "${package}" > "${out_dir}/obsoletes.txt" 2>&1 || true
rpm -qp --scripts "${package}" > "${out_dir}/scripts.txt" 2>&1 || true
rpm -qp --triggers "${package}" > "${out_dir}/triggers.txt" 2>&1 || true
rpm -qlp "${package}" > "${out_dir}/file-list.txt" 2>&1 || true
rpm -qlvp "${package}" > "${out_dir}/file-list-verbose.txt" 2>&1 || true

grep -E ' -> ' "${out_dir}/file-list-verbose.txt" > "${out_dir}/symlinks.txt" || true
grep -E '/environment-setup-|/site-config-' "${out_dir}/file-list.txt" > "${out_dir}/environment-scripts.txt" || true
grep -E '/k1om-mpss-linux-[^/]+$|/x86_64-k1om-linux-[^/]+$' "${out_dir}/file-list.txt" > "${out_dir}/tool-prefix-paths.txt" || true

mkdir -p "${out_dir}/grouped"
rm -f "${out_dir}/grouped/"*.txt

awk -v out="${out_dir}/grouped" '
function emit(group, line) {
  print line >> (out "/" group ".txt")
}
{
  line = $0
  if (line ~ /\/(environment-setup|site-config)-/) emit("environment", line)
  else if (line ~ /\/k1om-mpss-linux-(gcc|g\+\+|cpp|gcov)$/) emit("compiler", line)
  else if (line ~ /\/k1om-mpss-linux-(addr2line|ar|as|c\+\+filt|elfedit|gprof|ld|ld\.bfd|nm|objcopy|objdump|ranlib|readelf|size|strings|strip)$/) emit("binutils", line)
  else if (line ~ /\/(Mcrt1|Scrt1|crt1|crti|crtn|gcrt1|crtfastmath)\.o$/) emit("startup-objects", line)
  else if (line ~ /\/usr\/include\// || line ~ /\/usr\/include$/) emit("headers", line)
  else if (line ~ /\/(lib|lib64|usr\/lib64)\// && line ~ /\.(so|so\.[0-9].*|a)$/) emit("libraries", line)
  else if (line ~ /\/(usr\/share\/doc|usr\/share\/man|usr\/src\/debug|Documentation)\//) emit("documentation", line)
  else emit("other", line)
}
' "${out_dir}/file-list.txt"

{
  echo "package=${package}"
  echo "out_dir=${out_dir}"
  echo "file_count=$(wc -l < "${out_dir}/file-list.txt")"
  for group in environment compiler binutils startup-objects headers libraries documentation other; do
    path="${out_dir}/grouped/${group}.txt"
    if [[ -f "${path}" ]]; then
      echo "${group}_count=$(wc -l < "${path}")"
    else
      echo "${group}_count=0"
    fi
  done
} > "${out_dir}/summary.env"

cat "${out_dir}/summary.env"
