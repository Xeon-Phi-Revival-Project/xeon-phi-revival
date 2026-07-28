#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
build_dir="${K1OM_VALIDATION_BUILD_DIR:-${repo_root}/build/k1om-sdk-validation}"
env_script="${K1OM_ENV_SCRIPT:-/opt/mpss/3.4.10/environment-setup-k1om-mpss-linux}"

mkdir -p "${build_dir}"

if [[ -f "${env_script}" ]]; then
  # shellcheck disable=SC1090
  source "${env_script}"
fi

tools=(
  k1om-mpss-linux-gcc
  k1om-mpss-linux-g++
  k1om-mpss-linux-as
  k1om-mpss-linux-ld
  k1om-mpss-linux-objdump
  k1om-mpss-linux-readelf
)

echo "=== tool paths and versions ==="
for tool in "${tools[@]}"; do
  command -v "${tool}"
  "${tool}" --version | head -3
done

object="${build_dir}/start-exit42.o"
binary="${build_dir}/start-exit42"

echo "=== assemble ==="
k1om-mpss-linux-gcc -c "${repo_root}/tests/native/start-exit42.S" -o "${object}"
file "${object}"
k1om-mpss-linux-readelf -h "${object}" | sed -n '1,40p'

echo "=== link ==="
k1om-mpss-linux-ld -nostdlib -e _start -o "${binary}" "${object}"
file "${binary}"
k1om-mpss-linux-readelf -h "${binary}" | sed -n '1,80p'
k1om-mpss-linux-readelf -l "${binary}" | sed -n '1,120p'

echo "=== verify e_machine ==="
machine_value="$(od -An -j18 -N2 -tu2 "${binary}" | awk '{print $1}')"
echo "e_machine=${machine_value}"
if [[ "${machine_value}" != "181" ]]; then
  echo "expected K1OM e_machine 181, got ${machine_value}" >&2
  exit 20
fi

echo "=== dry-run harness ==="
bash "${repo_root}/experiments/run-native-k1om-test.sh" --binary "${binary}"

echo "validation prepared binary: ${binary}"
