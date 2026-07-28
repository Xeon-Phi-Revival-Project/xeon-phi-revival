#!/usr/bin/env python3
import argparse
import os


WANTED = [
    "/lib64/ld-linux-k1om.so.2",
    "/lib64/libc.so.6",
    "/lib64/libgcc_s.so.1",
    "/lib64/libpthread.so.0",
    "/lib64/libm.so.6",
    "/lib64/libdl.so.2",
    "/usr/lib64/crt1.o",
    "/usr/lib64/crti.o",
    "/usr/lib64/crtn.o",
    "/lib64/crt1.o",
    "/lib64/crti.o",
    "/lib64/crtn.o",
]


def resolve(root, p):
    target = os.path.join(root, p.lstrip("/"))
    if not os.path.lexists(target):
        return None
    kind = "symlink" if os.path.islink(target) else "file" if os.path.isfile(target) else "other"
    link = os.readlink(target) if os.path.islink(target) else ""
    return {"path": p, "kind": kind, "target": link, "exists": True}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rootfs", required=True)
    ap.add_argument("--out", required=True)
    args = ap.parse_args()

    rows = [(p, resolve(args.rootfs, p)) for p in WANTED]
    out_dir = os.path.dirname(args.out)
    if out_dir and not os.path.isdir(out_dir):
        os.makedirs(out_dir)
    with open(args.out, "w") as f:
        f.write("# Minimum K1OM Runtime Set\n\n")
        f.write("Public-safe metadata report. No runtime library contents are included.\n\n")
        f.write("## Files Checked\n\n")
        for p, info in rows:
            if info:
                target = " -> `{0}`".format(info["target"]) if info["target"] else ""
                f.write("- `{0}`: present, {1}{2}\n".format(p, info["kind"], target))
            else:
                f.write("- `{0}`: missing\n".format(p))
        f.write("\n## Initial Interpretation\n\n")
        f.write("- Runtime loader and core shared libraries are runtime components.\n")
        f.write("- `crt1.o`, `crti.o`, and `crtn.o` are link-time startup objects.\n")
        f.write("- If startup objects are missing, the stock uOS is not a complete development sysroot by itself.\n")
        f.write("- Missing unversioned `.so` linker names may also indicate runtime-only contents.\n")


if __name__ == "__main__":
    main()
