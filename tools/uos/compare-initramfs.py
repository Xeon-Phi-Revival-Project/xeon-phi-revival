#!/usr/bin/env python3
"""Compare two newc initramfs archives and write JSON plus a short Markdown report."""

import argparse
import gzip
import hashlib
import json
import os
import stat
import struct
import zlib
from collections import Counter, defaultdict

HEADER = 110
MAGIC = b"070701"
TRAILER = b"TRAILER!!!"

try:
    text_type = unicode
    byte_type = str
except NameError:
    text_type = str
    byte_type = bytes


def align4(value):
    return (value + 3) & ~3


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def json_safe(value):
    if isinstance(value, byte_type):
        return value.decode("utf-8", "replace")
    if isinstance(value, text_type):
        return value
    if isinstance(value, dict):
        return dict((json_safe(key), json_safe(item)) for key, item in value.items())
    if isinstance(value, (list, tuple)):
        return [json_safe(item) for item in value]
    return value


def load(path):
    blob = open(path, "rb").read()
    if blob[:2] != b"\x1f\x8b":
        return blob, blob, {}, 0
    inflater = zlib.decompressobj(16 + zlib.MAX_WBITS)
    plain = inflater.decompress(blob) + inflater.flush()
    if inflater.unused_data:
        raise ValueError("concatenated or trailing gzip data is unsupported: " + path)
    return blob, plain, {
        "mtime": struct.unpack("<I", blob[4:8])[0],
        "xfl": blob[8],
        "os": blob[9],
        "flags": blob[3],
    }, 1


def entry_type(mode):
    kind = stat.S_IFMT(mode)
    return {
        stat.S_IFREG: "file", stat.S_IFDIR: "directory", stat.S_IFLNK: "symlink",
        stat.S_IFCHR: "char-device", stat.S_IFBLK: "block-device", stat.S_IFIFO: "fifo",
        stat.S_IFSOCK: "socket",
    }.get(kind, "unknown")


def category(name):
    if name.startswith(("usr/lib/python", "usr/bin/python", "opt/xeon-phi-revival/python")):
        return "python"
    if name.startswith(("usr/bin/apt", "usr/lib/apt", "etc/apt", "var/lib/apt")):
        return "apt"
    if name.startswith(("usr/bin/dpkg", "usr/lib/dpkg", "etc/dpkg", "var/lib/dpkg")):
        return "dpkg"
    if name.startswith(("usr/share/doc", "usr/share/man")):
        return "documentation"
    if "/locale/" in name or name.startswith("usr/share/locale"):
        return "locales"
    if "cache" in name or name.startswith("var/cache"):
        return "cache"
    if name.startswith(("lib/", "lib64/", "usr/lib/", "usr/lib64/")):
        return "shared-libraries"
    if "firmware" in name:
        return "firmware"
    return "other"


def elf_machine(payload):
    if payload[:4] != b"\x7fELF" or len(payload) < 20:
        return None
    endian = "<" if payload[5] == 1 else ">" if payload[5] == 2 else None
    return struct.unpack(endian + "H", payload[18:20])[0] if endian else None


def inspect(path):
    compressed, plain, gz, gz_members = load(path)
    entries = []
    noncanonical_gaps = []
    cursor = 0
    while True:
        offset = plain.find(MAGIC, cursor)
        if offset < 0:
            break
        header = plain[offset:offset + HEADER]
        try:
            fields = [int(header[6 + 8 * i:14 + 8 * i], 16) for i in range(13)]
        except ValueError:
            cursor = offset + 6
            continue
        ino, mode, uid, gid, nlink, mtime, size, devmaj, devmin, rdevmaj, rdevmin, namesize, check = fields
        name_start = offset + HEADER
        name_end = name_start + namesize
        if namesize == 0 or name_end > len(plain) or plain[name_end - 1:name_end] != b"\0":
            cursor = offset + 6
            continue
        name_blob = plain[name_start:name_end - 1]
        if not name_blob or any(ord(byte) < 32 for byte in name_blob):
            cursor = offset + 6
            continue
        name = name_blob.decode("utf-8", "replace")
        data_start = align4(name_end)
        data_end = data_start + size
        if data_end > len(plain):
            cursor = offset + 6
            continue
        payload = plain[data_start:data_end]
        entries.append({"name": name, "mode": mode, "uid": uid, "gid": gid, "nlink": nlink,
                        "mtime": mtime, "size": size, "type": entry_type(mode), "rdev": [rdevmaj, rdevmin],
                        "offset": offset, "payload": payload})
        cursor = offset + HEADER
        if name == TRAILER.decode():
            break
    if not entries or entries[-1]["name"] != TRAILER.decode():
        raise ValueError("TRAILER!!! entry not found in " + path)
    for previous, current in zip(entries, entries[1:]):
        expected = align4(align4(previous["offset"] + HEADER + len(previous["name"].encode("utf-8")) + 1) + previous["size"])
        if current["offset"] != expected:
            noncanonical_gaps.append({"offset": expected, "bytes": current["offset"] - expected})
    real = entries[:-1]
    by_dir = Counter()
    by_type = Counter()
    by_category = Counter()
    elf_machines = Counter()
    for item in real:
        by_dir[(item["name"].split("/", 1)[0] if "/" in item["name"] else item["name"])] += item["size"]
        by_type[item["type"]] += item["size"]
        by_category[category(item["name"])] += item["size"]
        machine = elf_machine(item["payload"])
        if machine is not None:
            elf_machines[str(machine)] += 1
    names = [item["name"] for item in real]
    metadata = [{key: item[key] for key in ("name", "mode", "uid", "gid", "nlink", "mtime", "size", "type", "rdev")}
                for item in real]
    return {
        "path": path, "sha256": sha256(compressed), "compressed_bytes": len(compressed),
        "decompressed_bytes": len(plain), "gzip_members": gz_members, "gzip": gz,
        "member_count": len(real), "trailer_offset": entries[-1]["offset"],
        "trailing_bytes": len(plain) - align4(entries[-1]["offset"] + HEADER + len(TRAILER) + 1),
        "max_path_length": max([len(name) for name in names] or [0]),
        "noncanonical_inter_entry_gaps": noncanonical_gaps,
        "duplicate_paths": sorted([name for name, count in Counter(names).items() if count > 1]),
        "symlink_count": sum(item["type"] == "symlink" for item in real),
        "hardlink_candidates": sum(item["nlink"] > 1 for item in real),
        "device_nodes": [{"path": item["name"], "type": item["type"], "rdev": item["rdev"]}
                         for item in real if item["type"].endswith("device")],
        "bytes_by_top_level": dict(sorted(by_dir.items())), "bytes_by_type": dict(sorted(by_type.items())),
        "bytes_by_category": dict(sorted(by_category.items())), "elf_machines": dict(sorted(elf_machines.items())),
        "largest_members": [{"path": item["name"], "bytes": item["size"], "type": item["type"]}
                            for item in sorted(real, key=lambda value: value["size"], reverse=True)[:50]],
        "over_1m": sum(item["size"] > 1024 * 1024 for item in real),
        "over_4m": sum(item["size"] > 4 * 1024 * 1024 for item in real),
        "over_16m": sum(item["size"] > 16 * 1024 * 1024 for item in real),
        "metadata": metadata,
    }


def compact(report):
    return {key: value for key, value in report.items() if key != "metadata"}


def markdown(left, right):
    rows = [("compressed bytes", left["compressed_bytes"], right["compressed_bytes"]),
            ("decompressed bytes", left["decompressed_bytes"], right["decompressed_bytes"]),
            ("members", left["member_count"], right["member_count"]),
            ("max path length", left["max_path_length"], right["max_path_length"]),
            ("symlinks", left["symlink_count"], right["symlink_count"]),
            ("hardlink candidates", left["hardlink_candidates"], right["hardlink_candidates"]),
            ("files over 1 MiB", left["over_1m"], right["over_1m"]),
            ("files over 4 MiB", left["over_4m"], right["over_4m"]),
            ("files over 16 MiB", left["over_16m"], right["over_16m"])]
    lines = ["# Initramfs Comparison", "", "| Metric | Minimal | Candidate |", "| --- | ---: | ---: |"]
    lines.extend("| %s | %s | %s |" % row for row in rows)
    lines.extend(["", "## Candidate Largest Members", "", "| Path | Bytes | Type |", "| --- | ---: | --- |"])
    lines.extend("| `%s` | %d | %s |" % (item["path"], item["bytes"], item["type"])
                 for item in right["largest_members"][:15])
    return "\n".join(lines) + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("minimal")
    parser.add_argument("candidate")
    parser.add_argument("--json", required=True, dest="json_path")
    parser.add_argument("--markdown", required=True, dest="markdown_path")
    args = parser.parse_args()
    left, right = inspect(args.minimal), inspect(args.candidate)
    comparison = {
        "minimal": compact(left), "candidate": compact(right),
        "metadata_identical": left["metadata"] == right["metadata"],
        "common_members": len(set(item["name"] for item in left["metadata"]) & set(item["name"] for item in right["metadata"])),
    }
    with open(args.json_path, "w") as handle:
        json.dump(json_safe(comparison), handle, indent=2, sort_keys=True)
        handle.write("\n")
    with open(args.markdown_path, "w") as handle:
        handle.write(markdown(left, right))


if __name__ == "__main__":
    main()
