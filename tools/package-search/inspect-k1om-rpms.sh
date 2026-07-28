#!/usr/bin/env bash
set -euo pipefail

out="${1:-k1om-rpm-manifests.txt}"
shift || true

if [[ "$#" -eq 0 ]]; then
  extract_root="${MPSS_EXTRACT_ROOT:-${HOME}/mpss-extract}"
  set -- \
    "${extract_root}/mpss-3.4.10/mpss-sdk-k1om-3.4.10-1.x86_64.rpm" \
    "${extract_root}/mpss-3.4.10/intel-composerxe-compat-k1om-3.4.10-1.x86_64.rpm" \
    "${extract_root}/mpss-3.6.1/mpss-sdk-k1om-3.6.1-1.x86_64.rpm" \
    "${extract_root}/mpss-3.6.1/intel-composerxe-compat-k1om-3.6.1-1.x86_64.rpm"
fi

info_pattern='Name|Version|Release|Summary|Description|License|Architecture|Group'
file_pattern='k1om|crt1|crti|crtn|binutils|/as$|/ld$|/gcc$|/g\+\+$|/cpp$|include|\.h$|lib.*\.a$|lib.*\.so|sysroot|compiler|composer|icc|icpc|ld-linux'

{
  for rpm_file in "$@"; do
    echo "=== rpm: ${rpm_file}"
    if [[ ! -f "${rpm_file}" ]]; then
      echo "missing"
      continue
    fi
    echo "--- header"
    rpm -qip "${rpm_file}" 2>/dev/null | egrep "${info_pattern}" || true
    echo "--- files"
    rpm -qlp "${rpm_file}" 2>/dev/null | egrep -i "${file_pattern}" || true
    echo
  done
} > "${out}"

wc -l "${out}"
