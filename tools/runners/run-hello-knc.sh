#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_dir="${repo_root}/build/smoke"
src="${repo_root}/tests/smoke/hello-knc.c"
out="${build_dir}/hello-knc"
mic_target="${MIC_TARGET:-mic0}"
compiler="${KNC_CC:-}"
env_script="${K1OM_ENV_SCRIPT:-/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux}"

mkdir -p "${build_dir}"

if [[ -f "${env_script}" ]]; then
  # shellcheck disable=SC1090
  source "${env_script}"
fi

if [[ -z "${compiler}" ]]; then
  if command -v icc >/dev/null 2>&1; then
    compiler="icc -mmic"
  elif command -v x86_64-k1om-linux-gcc >/dev/null 2>&1; then
    compiler="x86_64-k1om-linux-gcc"
  elif command -v k1om-mpss-linux-gcc >/dev/null 2>&1; then
    compiler="k1om-mpss-linux-gcc"
  else
    echo "No KNC compiler found. Set KNC_CC, install icc with -mmic, install x86_64-k1om-linux-gcc, or source the MPSS k1om-mpss-linux SDK." >&2
    exit 2
  fi
fi

echo "compiler=${compiler}"
${compiler} -O2 -Wall -Wextra -o "${out}" "${src}"
file "${out}" || true
bash "${repo_root}/experiments/run-native-k1om-test.sh" --binary "${out}" --mic-target "${mic_target}" --execute
