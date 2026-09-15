#!/usr/bin/env bash
# Host-only contract test for the xpr-build driver; no K1OM compiler required.
set -euo pipefail

repo=$(CDPATH= cd -- "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
toolkit="$tmp/toolkit"
mkdir -p "$toolkit/bin" "$toolkit/sysroot/usr/include" "$tmp/source" "$tmp/prefix"

for tool in ar as ld nm ranlib strip cpp readelf; do
  cat > "$toolkit/bin/xpr-$tool" <<'EOF'
#!/usr/bin/env bash
exit 0
EOF
  chmod 755 "$toolkit/bin/xpr-$tool"
done
cat > "$toolkit/bin/xpr-gcc" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${CC:-}" > "${XPR_BUILD_TEST_LOG:?}"
output=
while [[ $# -gt 0 ]]; do
  case "$1" in -o) output=${2:?}; shift 2 ;; *) shift ;; esac
done
[[ -n "$output" ]] || exit 2
printf 'synthetic K1OM ELF\n' > "$output"
chmod 755 "$output"
EOF
chmod 755 "$toolkit/bin/xpr-gcc"
cat > "$toolkit/bin/xpr-validate" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
test -x "${1:?}"
grep -qx 'synthetic K1OM ELF' "$1"
echo XPR_K1OM_ELF=PASS
EOF
chmod 755 "$toolkit/bin/xpr-validate"
cat > "$toolkit/bin/make" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
build=
destdir=
while [[ $# -gt 0 ]]; do
  case "$1" in
    -C) build=${2:?}; shift 2 ;;
    DESTDIR=*) destdir=${1#DESTDIR=} ; shift ;;
    -j*) shift ;;
    *) shift ;;
  esac
done
[[ -n "$build" ]] || exit 2
if [[ -n "$destdir" ]]; then
  install -d "$destdir/usr/bin"
  install -m 0755 "$build/level0" "$destdir/usr/bin/level0"
else
  "$CC" "$build/hello.c" -o "$build/level0"
fi
EOF
chmod 755 "$toolkit/bin/make"

cat > "$tmp/source/configure" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$CC|$HOST|$PKG_CONFIG_PATH|$PKG_CONFIG_LIBDIR" > configure.env
cat > Makefile <<'MAKE'
all:
	$(CC) hello.c -o level0
install: all
	install -d $(DESTDIR)/usr/bin
	install -m 0755 level0 $(DESTDIR)/usr/bin/level0
MAKE
printf 'int main(void) { return 0; }\n' > hello.c
EOF
chmod 755 "$tmp/source/configure"

"$repo/tools/xpr-build/xpr-build" env --toolkit "$toolkit" --prefix "$tmp/prefix" \
  -- bash -c 'test "$CC" = "$XPR_BUILD_TOOLKIT/bin/xpr-gcc"; test "$HOST" = k1om-mpss-linux; test -z "$PKG_CONFIG_PATH"'
"$repo/tools/xpr-build/xpr-build" configure --toolkit "$toolkit" --prefix "$tmp/prefix" \
  --source "$tmp/source" --build "$tmp/build"
grep -Fqx "$toolkit/bin/xpr-gcc|k1om-mpss-linux||$tmp/prefix/lib/pkgconfig:$tmp/prefix/share/pkgconfig" "$tmp/build/configure.env"
XPR_BUILD_TEST_LOG="$tmp/gcc.env" "$repo/tools/xpr-build/xpr-build" make --toolkit "$toolkit" --build "$tmp/build"
grep -Fqx "$toolkit/bin/xpr-gcc" "$tmp/gcc.env"
"$repo/tools/xpr-build/xpr-build" inspect --toolkit "$toolkit" "$tmp/build/level0"
"$repo/tools/xpr-build/xpr-build" stage --toolkit "$toolkit" --build "$tmp/build" --destdir "$tmp/stage"
test -x "$tmp/stage/usr/bin/level0"
echo XPR_BUILD_HOST_FIXTURE=PASS
