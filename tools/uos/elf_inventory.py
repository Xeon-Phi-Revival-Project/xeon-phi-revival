#!/usr/bin/env python3
import argparse
import csv
import hashlib
import json
import os
import re
import subprocess
import sys
from collections import defaultdict

try:
    FileNotFoundError
except NameError:
    FileNotFoundError = OSError
try:
    PermissionError
except NameError:
    PermissionError = OSError


def run(cmd):
    try:
        p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        out, err = p.communicate()
        if not isinstance(out, str):
            out = out.decode("utf-8", "replace")
        if not isinstance(err, str):
            err = err.decode("utf-8", "replace")
        class Result(object):
            pass
        result = Result()
        result.returncode = p.returncode
        result.stdout = out
        result.stderr = err
        return result
    except FileNotFoundError:
        return None
    except OSError:
        return None


def makedirs(path):
    if path and not os.path.isdir(path):
        os.makedirs(path)


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def elf_machine_value(path):
    with open(path, "rb") as f:
        ident = f.read(20)
    if len(ident) < 20 or ident[:4] != b"\x7fELF":
        return ""
    def byte_at(index):
        value = ident[index]
        return value if isinstance(value, int) else ord(value)
    if byte_at(5) == 1:
        return str(byte_at(18) | (byte_at(19) << 8))
    if byte_at(5) == 2:
        return str((byte_at(18) << 8) | byte_at(19))
    return ""


def rel(root, path):
    return "/" + os.path.relpath(path, root).replace(os.sep, "/")


def parse_readelf_header(text):
    out = {
        "elf_class": "",
        "endianness": "",
        "machine": "",
        "machine_value": "",
        "elf_type": "",
        "entry": "",
    }
    for line in text.splitlines():
        line = line.strip()
        if line.startswith("Class:"):
            out["elf_class"] = line.split(":", 1)[1].strip()
        elif line.startswith("Data:"):
            out["endianness"] = line.split(":", 1)[1].strip()
        elif line.startswith("Machine:"):
            out["machine"] = line.split(":", 1)[1].strip()
        elif line.startswith("Type:"):
            out["elf_type"] = line.split(":", 1)[1].strip()
        elif line.startswith("Entry point address:"):
            out["entry"] = line.split(":", 1)[1].strip()
    return out


def parse_interpreter(text):
    m = re.search(r"Requesting program interpreter:\s*([^\]]+)", text)
    return m.group(1).strip() if m else ""


def parse_dynamic(text):
    needed = []
    rpath = ""
    runpath = ""
    for line in text.splitlines():
        if "(NEEDED)" in line:
            m = re.search(r"\[(.*?)\]", line)
            if m:
                needed.append(m.group(1))
        elif "(RPATH)" in line:
            m = re.search(r"\[(.*?)\]", line)
            if m:
                rpath = m.group(1)
        elif "(RUNPATH)" in line:
            m = re.search(r"\[(.*?)\]", line)
            if m:
                runpath = m.group(1)
    return needed, rpath, runpath


def parse_versions(text):
    versions = sorted(set(re.findall(r"\b[A-Z]+_[A-Za-z0-9_.]+", text)))
    return versions


def parse_build_id(text):
    m = re.search(r"Build ID:\s*([0-9a-fA-F]+)", text)
    return m.group(1) if m else ""


def inspect(root, path):
    file_out = run(["file", "-b", path])
    file_text = file_out.stdout.strip() if file_out else ""

    header = run(["readelf", "-h", path])
    header_text = header.stdout if header else ""
    h = parse_readelf_header(header_text)
    h["machine_value"] = elf_machine_value(path)

    prog = run(["readelf", "-l", path])
    prog_text = prog.stdout if prog else ""
    interp = parse_interpreter(prog_text)

    dyn = run(["readelf", "-d", path])
    dyn_text = dyn.stdout if dyn else ""
    needed, rpath, runpath = parse_dynamic(dyn_text)

    ver = run(["readelf", "--version-info", path])
    ver_text = ver.stdout if ver else ""

    notes = run(["readelf", "-n", path])
    notes_text = notes.stdout if notes else ""

    stripped = "not stripped" not in file_text
    linked = "statically linked" if "statically linked" in file_text else "dynamically linked" if "dynamically linked" in file_text else ""

    return {
        "path": rel(root, path),
        "file_type": file_text,
        "elf_class": h["elf_class"],
        "endianness": h["endianness"],
        "machine": h["machine"],
        "machine_value": h["machine_value"],
        "elf_type": h["elf_type"],
        "linkage": linked,
        "interpreter": interp,
        "dt_needed": ";".join(needed),
        "rpath": rpath,
        "runpath": runpath,
        "symbol_versions": ";".join(parse_versions(ver_text)),
        "build_id": parse_build_id(notes_text),
        "stripped": "yes" if stripped else "no",
        "sha256": sha256(path),
    }


def is_elf(path):
    with open(path, "rb") as f:
        return f.read(4) == b"\x7fELF"


def write_markdown(rows, md_path, dep_md_path):
    machines = defaultdict(int)
    interpreters = defaultdict(int)
    libs = defaultdict(set)
    for row in rows:
        machines[row["machine"] or "unknown"] += 1
        interpreters[row["interpreter"] or "none"] += 1
        for lib in filter(None, row["dt_needed"].split(";")):
            libs[lib].add(row["path"])

    with open(md_path, "w") as f:
        f.write("# Stock uOS ELF Inventory\n\n")
        f.write("Public-safe metadata inventory. No binary contents are included.\n\n")
        f.write("## Summary\n\n")
        f.write("- ELF files inspected: {0}\n".format(len(rows)))
        f.write("- Machines:\n")
        for machine, count in sorted(machines.items()):
            f.write("  - `{0}`: {1}\n".format(machine, count))
        f.write("- Program interpreters:\n")
        for interp, count in sorted(interpreters.items()):
            f.write("  - `{0}`: {1}\n".format(interp, count))
        f.write("\n## Notable Paths\n\n")
        for row in rows[:80]:
            f.write("- `{0}`: `{1}`, `{2}`, `{3}`\n".format(row["path"], row["elf_type"], row["machine"], row["linkage"]))

    with open(dep_md_path, "w") as f:
        f.write("# Stock uOS Library Dependencies\n\n")
        f.write("Derived from ELF dynamic sections. No binary contents are included.\n\n")
        for lib, users in sorted(libs.items()):
            f.write("## `{0}`\n\n".format(lib))
            for user in sorted(users)[:200]:
                f.write("- `{0}`\n".format(user))
            f.write("\n")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--rootfs", required=True)
    ap.add_argument("--csv", required=True)
    ap.add_argument("--graph", required=True)
    ap.add_argument("--md", required=True)
    ap.add_argument("--deps-md", required=True)
    args = ap.parse_args()

    rows = []
    for base, _, files in os.walk(args.rootfs):
        for name in files:
            path = os.path.join(base, name)
            try:
                if os.path.islink(path) or not os.path.isfile(path):
                    continue
                if is_elf(path):
                    rows.append(inspect(args.rootfs, path))
            except (OSError, PermissionError):
                continue
    rows.sort(key=lambda r: r["path"])

    makedirs(os.path.dirname(args.csv))
    makedirs(os.path.dirname(args.graph))
    makedirs(os.path.dirname(args.md))
    makedirs(os.path.dirname(args.deps_md))

    fields = [
        "path", "file_type", "elf_class", "endianness", "machine", "machine_value",
        "elf_type", "linkage", "interpreter", "dt_needed", "rpath", "runpath",
        "symbol_versions", "build_id", "stripped", "sha256",
    ]
    csv_mode = "w" if sys.version_info[0] >= 3 else "wb"
    with open(args.csv, csv_mode) as f:
        w = csv.DictWriter(f, fieldnames=fields)
        w.writeheader()
        w.writerows(rows)

    graph = {"nodes": [], "edges": []}
    seen = set()
    for row in rows:
        if row["path"] not in seen:
            graph["nodes"].append({"id": row["path"], "type": "elf", "machine": row["machine"]})
            seen.add(row["path"])
        for lib in filter(None, row["dt_needed"].split(";")):
            if lib not in seen:
                graph["nodes"].append({"id": lib, "type": "library"})
                seen.add(lib)
            graph["edges"].append({"from": row["path"], "to": lib, "kind": "DT_NEEDED"})
    with open(args.graph, "w") as f:
        json.dump(graph, f, indent=2, sort_keys=True)

    write_markdown(rows, args.md, args.deps_md)


if __name__ == "__main__":
    main()
