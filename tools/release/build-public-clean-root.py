#!/usr/bin/env python3
"""Assemble an allowlisted XPR K1OM root without consuming a historical rootfs."""
from __future__ import print_function
import argparse
import glob
import hashlib
import json
import os
import shutil
import stat
import sys


APPLET_NAMES = ("sh", "ls", "cat", "cp", "mv", "rm", "mkdir", "mount", "umount",
                "uname", "ps", "env", "echo", "sleep", "test", "true", "false", "pwd",
                "printf", "grep", "sed", "awk", "find", "head", "tail", "chmod", "ln")
EGLIBC_RUNTIME = ("ld-linux-k1om.so.2", "libc.so.6", "libpthread.so.0", "libm.so.6",
                  "libdl.so.2", "librt.so.1", "libutil.so.1", "libcrypt.so.1")


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def copy_file(source, destination):
    parent = os.path.dirname(destination)
    if not os.path.isdir(parent):
        os.makedirs(parent)
    shutil.copy2(source, destination)


def runtime_source(libdir, soname):
    direct = os.path.join(libdir, soname)
    if os.path.isfile(direct):
        return direct
    pattern = "ld-*.so" if soname == "ld-linux-k1om.so.2" else soname.split(".so", 1)[0] + "-*.so"
    matches = sorted(path for path in glob.glob(os.path.join(libdir, pattern)) if os.path.isfile(path))
    if len(matches) != 1:
        raise RuntimeError("cannot resolve source-built runtime for %s in %s" % (soname, libdir))
    return matches[0]


def require_component(ledger, component_id):
    for component in ledger["components"]:
        if component["id"] == component_id:
            return component
    raise RuntimeError("component is not present in the public-clean ledger: " + component_id)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--ledger", required=True)
    parser.add_argument("--out-root", required=True)
    parser.add_argument("--busybox")
    parser.add_argument("--dropbear")
    parser.add_argument("--python-root")
    parser.add_argument("--eglibc-libdir",
                        help="directory containing source-built eglibc SONAME files")
    parser.add_argument("--libgcc", help="source-built K1OM libgcc_s.so.1")
    args = parser.parse_args()

    ledger = json.load(open(args.ledger))
    root = os.path.abspath(args.out_root)
    if os.path.exists(root):
        raise RuntimeError("refusing to overwrite existing output: " + root)
    for value in (args.busybox, args.dropbear, args.python_root, args.eglibc_libdir, args.libgcc):
        if value and ("/opt/mpss/" in os.path.abspath(value).replace("\\", "/") or "sysroot" in os.path.abspath(value).lower()):
            raise RuntimeError("Intel/MPSS sysroot inputs are forbidden in the public-clean builder")

    os.makedirs(root)
    for path in ("bin", "sbin", "etc", "dev", "proc", "sys", "run", "tmp", "var/log", "root", "usr/bin", "usr/sbin"):
        os.makedirs(os.path.join(root, path))
    os.chmod(os.path.join(root, "tmp"), 0o1777)

    repo = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
    init = os.path.join(repo, "src", "uos", "xpr_rc_root_init.sh")
    banner = os.path.join(repo, "src", "uos", "xpr-banner.txt")
    copy_file(init, os.path.join(root, "sbin", "init"))
    os.chmod(os.path.join(root, "sbin", "init"), 0o755)
    copy_file(banner, os.path.join(root, "etc", "motd"))
    copy_file(banner, os.path.join(root, "etc", "issue"))
    with open(os.path.join(root, "etc", "os-release"), "w") as handle:
        handle.write('NAME="Xeon Phi Revival K1OM uOS"\nPRETTY_NAME="Xeon Phi Revival K1OM uOS"\nID=xpr-uos\nVERSION_ID="0.1"\nARCHITECTURE="k1om"\n')
    with open(os.path.join(root, "etc", "hostname"), "w") as handle:
        handle.write("xeon-phi-k1om\n")

    selected = ["xpr-owned"]
    if args.busybox:
        component = require_component(ledger, "busybox")
        if not os.path.isfile(args.busybox):
            raise RuntimeError("BusyBox input is not a file")
        copy_file(args.busybox, os.path.join(root, "bin", "busybox"))
        os.chmod(os.path.join(root, "bin", "busybox"), 0o755)
        for name in APPLET_NAMES:
            os.symlink("busybox", os.path.join(root, "bin", name))
        selected.append(component["id"])
    if args.dropbear:
        component = require_component(ledger, "dropbear")
        if not os.path.isfile(args.dropbear):
            raise RuntimeError("Dropbear input is not a file")
        copy_file(args.dropbear, os.path.join(root, "usr", "sbin", "dropbear"))
        os.chmod(os.path.join(root, "usr", "sbin", "dropbear"), 0o755)
        selected.append(component["id"])
    if args.eglibc_libdir:
        component = require_component(ledger, "eglibc")
        if not os.path.isdir(args.eglibc_libdir):
            raise RuntimeError("eglibc runtime input is not a directory")
        for name in EGLIBC_RUNTIME:
            source = runtime_source(args.eglibc_libdir, name)
            copy_file(source, os.path.join(root, "lib64", name))
        # eglibc linker scripts refer to ld.so.1 while dynamic executables use
        # the K1OM-specific interpreter name. Both names identify this loader.
        os.symlink("ld-linux-k1om.so.2", os.path.join(root, "lib64", "ld.so.1"))
        selected.append(component["id"])
    if args.libgcc:
        component = require_component(ledger, "libgcc")
        if not os.path.isfile(args.libgcc):
            raise RuntimeError("libgcc input is not a file")
        copy_file(args.libgcc, os.path.join(root, "lib64", "libgcc_s.so.1"))
        os.symlink("libgcc_s.so.1", os.path.join(root, "lib64", "libgcc_s.so"))
        selected.append(component["id"])
    if args.python_root:
        component = require_component(ledger, "cpython")
        interpreter = os.path.join(args.python_root, "python")
        library = os.path.join(args.python_root, "Lib")
        if not os.path.isfile(interpreter) or not os.path.isdir(library):
            raise RuntimeError("Python root must contain python and Lib/")
        copy_file(interpreter, os.path.join(root, "usr", "bin", "python3.12"))
        os.symlink("python3.12", os.path.join(root, "usr", "bin", "python3"))
        os.symlink("python3.12", os.path.join(root, "usr", "bin", "python"))
        target = os.path.join(root, "opt", "xeon-phi-revival", "lib", "python3.12")
        shutil.copytree(library, target, ignore=shutil.ignore_patterns("test", "idlelib", "tkinter", "__pycache__"))
        selected.append(component["id"])

    rows = []
    for base, dirs, files in os.walk(root):
        dirs.sort(); files.sort()
        for name in files:
            path = os.path.join(base, name)
            rel = "/" + os.path.relpath(path, root).replace(os.sep, "/")
            if rel.startswith("/lib64/libgcc_s.so"):
                owner = "libgcc"
            elif rel.startswith("/lib64/"):
                owner = "eglibc"
            elif rel == "/bin/busybox" or rel.startswith("/bin/"):
                owner = "busybox"
            elif rel == "/usr/sbin/dropbear":
                owner = "dropbear"
            elif rel.startswith("/usr/bin/python") or rel.startswith("/opt/xeon-phi-revival/lib/python3.12/"):
                owner = "cpython"
            else:
                owner = "xpr-owned"
            rows.append({"path": rel, "sha256": sha256(path), "mode": oct(os.stat(path).st_mode & 0o777), "owner_component": owner})
    report = {"schema": "xpr-public-clean-root-v1", "selected_components": selected, "files": rows,
              "policy": "allowlist-only; no stock rootfs, sysroot, package archive, firmware, or private keys"}
    with open(os.path.join(root, "xpr-clean-root-manifest.json"), "w") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("clean_root=%s files=%d components=%s" % (root, len(rows), ",".join(selected)))


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        sys.stderr.write("ERROR: " + str(exc) + "\n")
        sys.exit(2)
