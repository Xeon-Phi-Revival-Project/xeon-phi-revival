#!/usr/bin/env bash
set -euo pipefail

pattern='k1om|mic|mpss|compiler|composer|sysroot|sdk|cross|binutils|crt1|crti|crtn'
out="${1:-package-search.txt}"

{
  echo "=== rpm -qa filtered ==="
  rpm -qa | sort | egrep -i "${pattern}" || true
  echo

  echo "=== installed package files filtered ==="
  rpm -qa | sort | while read -r package; do
    files="$(rpm -ql "${package}" 2>/dev/null | egrep -i "${pattern}|include|/as$|/ld$|/gcc$|/icc$|/icpc$|\.h$" || true)"
    if [[ -n "${files}" ]]; then
      echo "--- package:${package}"
      printf '%s\n' "${files}"
    fi
  done
  echo

  echo "=== yum repos ==="
  yum repolist all 2>/dev/null || true
  echo

  echo "=== yum list all filtered ==="
  yum list all 2>/dev/null | egrep -i "${pattern}" || true
  echo

  echo "=== repo/cache/package metadata files ==="
  for base in /etc/yum.repos.d /var/cache/yum /var/lib/yum /usr/share/mpss /opt/intel /root; do
    [[ -e "${base}" ]] || continue
    find "${base}" -maxdepth 7 2>/dev/null | egrep -i "repomd|primary|filelists|${pattern}|rpm$|repo$|\\.repo" || true
  done
  echo

  echo "=== local rpm manifests filtered ==="
  for rpm_file in $(find /root /usr/share/mpss /opt/intel -maxdepth 7 -type f -name '*.rpm' 2>/dev/null | sort); do
    echo "--- rpm:${rpm_file}"
    rpm -qip "${rpm_file}" 2>/dev/null | egrep -i 'Name|Version|Release|Summary|Description|License|Group|Architecture' || true
    rpm -qlp "${rpm_file}" 2>/dev/null | egrep -i "${pattern}|include|/as$|/ld$|/gcc$|/icc$|/icpc$|\.h$" || true
  done
} > "${out}"

wc -l "${out}"
