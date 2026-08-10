#!/usr/bin/env python3
"""Fail-closed provenance audit for a candidate XPR binary root filesystem.

The input ledger deliberately records per-path evidence.  A component cannot be
made distributable merely by naming its upstream project: every shipped binary
must have a source hash, build recipe, notice decision, and source location.
"""
import argparse
import imp
import fnmatch
import gzip
import hashlib
import io
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile


REPOSITORY_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
NEWC_ARCHIVE = imp.load_source(
    "xpr_newc_archive", os.path.join(REPOSITORY_ROOT, "tools", "uos", "newc_archive.py")
)


REQUIRED = ("upstream", "version", "source_url", "source_sha256", "license",
            "build_recipe", "corresponding_source", "redistribution", "spdx_id")
REJECT_NAMES = ("*python3.5*", "*python3.5/*", "*libreadline*", "*libssl.so.1.0*",
                "*libcrypto.so.1.0*", "/opt/mpss/*", "/usr/share/mpss/*",
                "/lib/firmware/*", "/usr/lib/firmware/*")


def digest(data):
    return hashlib.sha256(data).hexdigest()


def is_elf(data):
    return data.startswith(b"\x7fELF")


def cpio_entries(path):
    raw = open(path, "rb").read()
    plain, trailing, members = NEWC_ARCHIVE.gunzip(raw) if path.endswith(".gz") else (raw, b"", 0)
    entries, trailer_offset, archive_trailing = NEWC_ARCHIVE.parse_newc(plain)
    rows = []
    for item in entries:
        name = item["name"].decode("utf-8", "replace")
        if name == "TRAILER!!!":
            continue
        mode = item["fields"][1]
        if stat.S_ISDIR(mode):
            kind = "directory"
        elif stat.S_ISLNK(mode):
            kind = "symlink"
        elif stat.S_ISREG(mode):
            kind = "file"
        else:
            kind = "special"
        rows.append({"path": "/" + name.lstrip("./"), "mode": mode,
                     "payload": item["payload"], "kind": kind})
    return rows, {"sha256": digest(raw), "compressed_bytes": len(raw),
                  "uncompressed_bytes": len(plain), "gzip_members": members,
                  "trailing_bytes": len(trailing) + len(archive_trailing),
                  "trailer_offset": trailer_offset}


def root_entries(root):
    rows = []
    for base, dirs, files in os.walk(root):
        dirs.sort(); files.sort()
        for name in files:
            full = os.path.join(base, name)
            if os.path.islink(full):
                rows.append({"path": "/" + os.path.relpath(full, root).replace(os.sep, "/"),
                             "mode": os.lstat(full).st_mode, "payload": os.readlink(full).encode(),
                             "kind": "symlink"})
            elif os.path.isfile(full):
                rows.append({"path": "/" + os.path.relpath(full, root).replace(os.sep, "/"),
                             "mode": os.stat(full).st_mode, "payload": open(full, "rb").read(),
                             "kind": "file"})
    return rows, {"root": os.path.abspath(root)}


def match_component(path, components):
    matches = []
    for component in components:
        for pattern in component.get("paths", []):
            if fnmatch.fnmatch(path, pattern):
                matches.append((len(pattern), component))
    return max(matches, key=lambda item: item[0])[1] if matches else None


def elf_details(payload):
    with tempfile.NamedTemporaryFile(delete=False) as handle:
        handle.write(payload)
        temp = handle.name
    try:
        result = subprocess.Popen(["readelf", "-h", temp], stdout=subprocess.PIPE,
                                  stderr=open(os.devnull, "wb"), universal_newlines=True)
        stdout = result.communicate()[0]
        machine = next((line.split(":", 1)[1].strip() for line in stdout.splitlines()
                        if line.strip().startswith("Machine:")), "unknown")
        return {"machine": machine}
    finally:
        os.unlink(temp)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--rootfs")
    group.add_argument("--cpio")
    parser.add_argument("--ledger", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--sbom", help="SPDX JSON emitted by generate-spdx-sbom.py")
    parser.add_argument("--stage", choices=("publication", "candidate"), default="publication",
                        help="candidate accepts only explicitly candidate-approved components; publication is stricter")
    parser.add_argument("--allow-optional", action="store_true",
                        help="permit explicitly approved optional legacy components")
    args = parser.parse_args()
    ledger = json.load(io.open(args.ledger, encoding="utf-8"))
    components = ledger.get("components", [])
    sbom_ids = set()
    if args.sbom:
        sbom = json.load(io.open(args.sbom, encoding="utf-8"))
        sbom_ids = set(item.get("SPDXID") for item in sbom.get("packages", []))
    entries, artifact = cpio_entries(args.cpio) if args.cpio else root_entries(args.rootfs)
    errors, inventory = [], []
    for entry in entries:
        path, payload = entry["path"], entry["payload"]
        record = {"path": path, "sha256": digest(payload), "size": len(payload),
                  "kind": entry["kind"]}
        component = match_component(path, components)
        is_exec = bool(entry["mode"] & stat.S_IXUSR)
        binary_or_script = entry["kind"] == "file" and (is_elf(payload) or payload.startswith(b"#!") or is_exec)
        if is_elf(payload):
            record.update(elf_details(payload))
            binary_or_script = True
        if binary_or_script:
            if not component:
                errors.append("unclassified executable: " + path)
            else:
                record["component"] = component.get("id")
                for field in REQUIRED:
                    if not component.get(field):
                        errors.append("%s lacks %s for %s" % (component.get("id"), field, path))
                permitted = ("publish",) if args.stage == "publication" else ("publish", "candidate")
                if component.get("redistribution") not in permitted:
                    errors.append("%s is not approved for publication: %s" % (component.get("id"), path))
                if args.sbom and component.get("spdx_id") not in sbom_ids:
                    errors.append("%s has no SPDX package entry" % component.get("id"))
        if not args.allow_optional and any(fnmatch.fnmatch(path.lower(), rule) for rule in REJECT_NAMES):
            errors.append("excluded or Intel-like payload: " + path)
        if b"BEGIN OPENSSH PRIVATE KEY" in payload or b"BEGIN RSA PRIVATE KEY" in payload:
            errors.append("private key material: " + path)
        inventory.append(record)
    report = {"schema": "xpr-prebuilt-image-audit-v1", "artifact": artifact,
              "inventory": sorted(inventory, key=lambda row: row["path"]),
              "errors": sorted(set(errors)), "result": "PASS" if not errors else "FAIL"}
    # CentOS 7's Python 2 json module writes byte strings; archive member names
    # are decoded with replacement above, so a normal binary-compatible handle
    # keeps the audit usable on the MPSS host as well as modern Python 3.
    with open(args.output, "w") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("%s: files=%d errors=%d output=%s" % (report["result"], len(inventory), len(report["errors"]), args.output))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
