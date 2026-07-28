#!/usr/bin/env bash
set -euo pipefail

execute=0
binary=""
mic_target="${MIC_TARGET:-mic0}"
timeout_s="${K1OM_TIMEOUT:-20}"
report_dir="${K1OM_REPORT_DIR:-manifests/experiments/native-runs}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --execute) execute=1; shift ;;
    --binary) binary="$2"; shift 2 ;;
    --mic-target) mic_target="$2"; shift 2 ;;
    *) echo "unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "${binary}" || ! -f "${binary}" ]]; then
  echo "usage: $0 --binary path [--execute]" >&2
  exit 2
fi

file_text="$(file "${binary}")"
readelf_header="$(readelf -h "${binary}" 2>/dev/null || true)"
if grep -q 'Advanced Micro Devices X86-64' <<<"${readelf_header}"; then
  echo "rejecting ordinary x86-64 ELF" >&2
  exit 11
fi

if ! grep -q 'Machine:[[:space:]]*Intel K1OM' <<<"${readelf_header}"; then
  echo "rejecting non-K1OM binary: ${file_text}" >&2
  exit 10
fi

hash="$(sha256sum "${binary}" | awk '{print $1}')"
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p "${report_dir}"
report="${report_dir}/${stamp}-$(basename "${binary}").yml"
remote="/tmp/k1om-test-${stamp}"

{
  echo "id: ${stamp}-native-k1om-test"
  echo "binary: ${binary}"
  echo "sha256: ${hash}"
  echo "file: ${file_text}"
  echo "mic_target: ${mic_target}"
  echo "execute: ${execute}"
} > "${report}"

ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10 "${mic_target}" 'uname -a' >> "${report}" 2>&1 || {
  echo "mic SSH check failed" >&2
  exit 12
}

if [[ "${execute}" -ne 1 ]]; then
  echo "dry run complete; report=${report}"
  exit 0
fi

scp "${binary}" "${mic_target}:${remote}" >> "${report}" 2>&1
remote_cmd="chmod +x '${remote}' && '${remote}'"
set +e
if command -v timeout >/dev/null 2>&1; then
  timeout "${timeout_s}" ssh "${mic_target}" "${remote_cmd}" >> "${report}" 2>&1
else
  echo "warning: host timeout command unavailable; running without timeout" >> "${report}"
  ssh "${mic_target}" "${remote_cmd}" >> "${report}" 2>&1
fi
rc=$?
set -e
ssh "${mic_target}" "rm -f '${remote}'; dmesg | tail -80" >> "${report}" 2>&1 || true
echo "exit_code: ${rc}" >> "${report}"
exit "${rc}"
