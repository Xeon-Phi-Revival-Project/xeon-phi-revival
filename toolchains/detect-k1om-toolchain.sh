#!/usr/bin/env bash
set -euo pipefail

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

cat > "${tmpdir}/hello.c" <<'C'
int main(void) { return 0; }
C

check_tool() {
  local tool="$1"
  if ! command -v "${tool}" >/dev/null 2>&1; then
    printf '%-30s missing\n' "${tool}"
    return
  fi

  local path
  path="$(command -v "${tool}")"
  printf '%-30s %s\n' "${tool}" "${path}"
  "${tool}" --version 2>&1 | head -3 | sed 's/^/  version: /' || true

  local compile_cmd=()
  if [[ "${tool}" == "icc" || "${tool}" == "icpc" ]]; then
    compile_cmd=("${tool}" -mmic -c "${tmpdir}/hello.c" -o "${tmpdir}/${tool}.o")
  elif [[ "${tool}" == *k1om*"-gcc" || "${tool}" == *k1om*"-g++" ]]; then
    compile_cmd=("${tool}" -c "${tmpdir}/hello.c" -o "${tmpdir}/${tool}.o")
  fi

  if [[ "${#compile_cmd[@]}" -gt 0 ]]; then
    if "${compile_cmd[@]}" >/tmp/k1om-detect.log 2>&1; then
      file "${tmpdir}/${tool}.o" | sed 's/^/  object: /'
      if file "${tmpdir}/${tool}.o" | grep -qi 'k1om\|Xeon Phi'; then
        echo "  result: K1OM object validated"
      else
        echo "  result: compiler ran but output was not recognized as K1OM"
      fi
    else
      echo "  result: compile failed"
      sed 's/^/    /' /tmp/k1om-detect.log | head -40
    fi
  fi
}

echo "=== PATH tools ==="
for tool in \
  icc icpc \
  x86_64-k1om-linux-gcc x86_64-k1om-linux-g++ x86_64-k1om-linux-as x86_64-k1om-linux-ld x86_64-k1om-linux-objdump x86_64-k1om-linux-readelf \
  k1om-mpss-linux-gcc k1om-mpss-linux-g++ k1om-mpss-linux-as k1om-mpss-linux-ld k1om-mpss-linux-objdump k1om-mpss-linux-readelf; do
  check_tool "${tool}"
done

echo "=== Intel environment candidates ==="
find /opt/intel /opt/mpss "$HOME/intel" -maxdepth 5 -type f \
  \( -name 'compilervars.sh' -o -name 'iccvars.sh' -o -name 'ifortvars.sh' \) \
  2>/dev/null | sort || true

find /opt/mpss -maxdepth 3 -type f \
  \( -name 'environment-setup-k1om-mpss-linux' -o -name 'site-config-k1om-mpss-linux' \) \
  2>/dev/null | sort || true
