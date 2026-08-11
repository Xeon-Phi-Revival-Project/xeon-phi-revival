#!/bin/bash
# Reproduce the three-boot-tested Solros K1OM kernel byte for byte.
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: reproduce-tested-k1om-kernel.sh --source-archive FILE \
       --cross-compile PREFIX [--jobs N]

This historical build is path-sensitive and intentionally uses:
  source: /root/xpr-kernel-candidate-solros/phi-kernel
  output: /root/xpr-kernel-candidate-solros-build-validated

The output path must not exist. The script does not install or boot the image.
EOF
}

source_archive=
cross_compile=
jobs=2
while [ "$#" -gt 0 ]; do
    case "$1" in
        --source-archive) source_archive=$2; shift 2 ;;
        --cross-compile) cross_compile=$2; shift 2 ;;
        --jobs) jobs=$2; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        *) echo "unknown argument: $1" >&2; usage >&2; exit 2 ;;
    esac
done

[ -n "$source_archive" ] && [ -n "$cross_compile" ] || { usage >&2; exit 2; }

readonly expected_source=/root/xpr-kernel-candidate-solros/phi-kernel
readonly expected_output=/root/xpr-kernel-candidate-solros-build-validated
readonly source_archive_sha=0e876982d8e33ffda706e46c4bee731f84c76ad22601c7b8feb751a5bc6c1b59
readonly config_sha=20f240d00b033c1a0e14ffc8d2023533552adc4040ac0deff3404c79f1f12479
readonly compile_header_sha=4f2c4d56ce5708c039d0998e865701cac8f8b3b43b7eb8383fb638616b1ef9c5
readonly initramfs_sha=35964b2f888f840a74c0270f5ba1b80165e34d79d13be51322d5ea7d1a0c93ec
readonly vmlinux_sha=b96b976f2eac4da888edef36fea8234efc97b00160a72da595d5ed048021991e
readonly system_map_sha=631674771d32602354e780209b86f2193ab24f8135056d654b1729f4967834a6
readonly compressed_bin_sha=1afd554fe63f4886f32de742d03143b147afe5ebfc5262ead0e44f1cdfaea6af
readonly gzip_sha=b9341234f356a9333e5ad5e588259d36aa1bd2922047c4e2b43fb63f0d447c0a
readonly image_sha=d529aecf0de11e0b4a9a036eb0329d1bb9c907fd6a911ce08a10548c9380d4d8
readonly initramfs_mtime=1785639585
readonly gzip_mtime_octal='\241\263\156\152'

repo_root=$(git rev-parse --show-toplevel)
config_file=$repo_root/configs/kernel/k1om-solros-tested.config
compile_header=$repo_root/configs/kernel/k1om-solros-tested.compile.h

check_sha() {
    local expected=$1 path=$2 actual
    actual=$(sha256sum "$path" | awk '{print $1}')
    [ "$actual" = "$expected" ] || {
        echo "hash mismatch: $path: expected $expected, got $actual" >&2
        exit 1
    }
}

[ -f "$expected_source/Makefile" ] || { echo "missing exact source path" >&2; exit 1; }
[ ! -e "$expected_output" ] || { echo "output path already exists" >&2; exit 1; }
[ -x "${cross_compile}gcc" ] && [ -x "${cross_compile}ld" ] || {
    echo "missing K1OM cross tools" >&2; exit 1;
}
check_sha "$source_archive_sha" "$source_archive"
check_sha "$config_sha" "$config_file"
check_sha "$compile_header_sha" "$compile_header"
[ "$(gzip --version | head -n 1)" = "gzip 1.5" ] || {
    echo "exact packaging requires gzip 1.5" >&2; exit 1;
}

work_dir=$(mktemp -d /tmp/xpr-kernel-reproduce.XXXXXX)
cp "$expected_source/scripts/mkcompile_h" "$work_dir/mkcompile_h"
cp "$expected_source/usr/gen_init_cpio.c" "$work_dir/gen_init_cpio.c"
restore_sources() {
    cp "$work_dir/mkcompile_h" "$expected_source/scripts/mkcompile_h"
    cp "$work_dir/gen_init_cpio.c" "$expected_source/usr/gen_init_cpio.c"
}
trap restore_sources EXIT

mkdir -p "$expected_output"
cp "$config_file" "$expected_output/.config"
printf '1\n' > "$expected_output/.version"

cat > "$expected_source/scripts/mkcompile_h" <<EOF
#!/bin/sh
set -e
cat '$compile_header' > "\$1"
EOF
chmod 0775 "$expected_source/scripts/mkcompile_h"
sed -i "s/time(NULL)/((time_t)$initramfs_mtime)/g" \
    "$expected_source/usr/gen_init_cpio.c"

make -C "$expected_source" -j"$jobs" ARCH=k1om \
    CROSS_COMPILE="$cross_compile" O="$expected_output" bzImage

check_sha "$compile_header_sha" "$expected_output/include/generated/compile.h"
check_sha "$initramfs_sha" "$expected_output/usr/initramfs_data.cpio"
check_sha "$vmlinux_sha" "$expected_output/vmlinux"
check_sha "$system_map_sha" "$expected_output/System.map"
check_sha "$compressed_bin_sha" \
    "$expected_output/arch/x86/boot/compressed/vmlinux.bin"

cd "$expected_output"
(cat arch/x86/boot/compressed/vmlinux.bin | gzip -f -9 \
    > arch/x86/boot/compressed/vmlinux.bin.gz)
printf "$gzip_mtime_octal" | dd of=arch/x86/boot/compressed/vmlinux.bin.gz \
    bs=1 seek=4 conv=notrunc status=none
check_sha "$gzip_sha" arch/x86/boot/compressed/vmlinux.bin.gz

arch/x86/boot/compressed/mkpiggy \
    arch/x86/boot/compressed/vmlinux.bin.gz \
    > arch/x86/boot/compressed/piggy.S
"${cross_compile}gcc" -Wp,-MD,arch/x86/boot/compressed/.piggy.o.d \
    -nostdinc -isystem "$(${cross_compile}gcc -print-file-name=include)" \
    -I"$expected_source/arch/x86/include" -Iinclude \
    -I"$expected_source/mpss/include" -I"$expected_source/include" \
    -include include/generated/autoconf.h -D__KERNEL__ -m64 -O2 \
    -fno-strict-aliasing -fPIC -DDISABLE_BRANCH_PROFILING -mcmodel=small \
    -ffreestanding -fno-stack-protector -D__ASSEMBLY__ \
    -c -o arch/x86/boot/compressed/piggy.o \
    arch/x86/boot/compressed/piggy.S
"${cross_compile}ld" -m elf_k1om -T arch/x86/boot/compressed/vmlinux.lds \
    arch/x86/boot/compressed/head_64.o arch/x86/boot/compressed/misc.o \
    arch/x86/boot/compressed/string.o arch/x86/boot/compressed/cmdline.o \
    arch/x86/boot/compressed/early_serial_console.o \
    arch/x86/boot/compressed/piggy.o -o arch/x86/boot/compressed/vmlinux

"${cross_compile}nm" arch/x86/boot/compressed/vmlinux | sed -n \
    -e 's/^\([0-9a-fA-F]*\) . \(startup_32\|input_data\|_end\|z_.*\)$/#define ZO_\2 0x\1/p' \
    > arch/x86/boot/zoffset.h
"${cross_compile}gcc" -Wp,-MD,arch/x86/boot/.header.o.d -nostdinc \
    -isystem "$(${cross_compile}gcc -print-file-name=include)" \
    -I"$expected_source/arch/x86/include" -Iinclude \
    -I"$expected_source/mpss/include" -I"$expected_source/include" \
    -include include/generated/autoconf.h -D__KERNEL__ -g -Os -D_SETUP \
    -DDISABLE_BRANCH_PROFILING -Wall -Wstrict-prototypes -march=i386 \
    -mregparm=3 -include "$expected_source/arch/x86/boot/code16gcc.h" \
    -fno-strict-aliasing -fomit-frame-pointer -ffreestanding \
    -fno-toplevel-reorder -fno-stack-protector -m32 -D__ASSEMBLY__ \
    -DSVGA_MODE=NORMAL_VGA -I"$expected_source/arch/x86/boot" \
    -Iarch/x86/boot -c -o arch/x86/boot/header.o \
    "$expected_source/arch/x86/boot/header.S"

setup_objects=(a20 bioscall cmdline copy cpu cpucheck early_serial_console edd
    header main mca memory pm pmjump printf regs string tty video video-mode
    version video-vga video-vesa video-bios)
setup_args=()
for object in "${setup_objects[@]}"; do
    setup_args+=("arch/x86/boot/$object.o")
done
"${cross_compile}ld" -m elf_k1om --defsym=MIC_KERNEL_VERSION_20626=0 \
    -T "$expected_source/arch/x86/boot/setup.ld" "${setup_args[@]}" \
    -o arch/x86/boot/setup.elf
"${cross_compile}objcopy" -O binary arch/x86/boot/setup.elf \
    arch/x86/boot/setup.bin
"${cross_compile}objcopy" -O binary -R .note -R .comment -S \
    arch/x86/boot/compressed/vmlinux arch/x86/boot/vmlinux.bin
arch/x86/boot/tools/build arch/x86/boot/setup.bin \
    arch/x86/boot/vmlinux.bin CURRENT > arch/x86/boot/bzImage

check_sha "$image_sha" arch/x86/boot/bzImage
echo "PASS: exact tested K1OM kernel reproduced: $image_sha"
