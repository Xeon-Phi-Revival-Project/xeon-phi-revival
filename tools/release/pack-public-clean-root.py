#!/usr/bin/env python3
"""Create a deterministic gzip-compressed newc payload from a clean XPR root."""
from __future__ import print_function

import argparse
import gzip
import hashlib
import json
import os
import stat
import sys

MAGIC = b"070701"
TRAILER = "TRAILER!!!"


def align4(value):
    return (value + 3) & ~3


def digest(path):
    value = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def cpio_entry(name, mode, payload, inode):
    encoded = name.encode("utf-8") + b"\0"
    values = (inode, mode, 0, 0, 1, 0, len(payload), 0, 0, 0, 0, len(encoded), 0)
    header = MAGIC + b"".join(("%08X" % item).encode("ascii") for item in values)
    body = header + encoded
    body += b"\0" * (align4(len(body)) - len(body))
    body += payload
    body += b"\0" * (align4(len(payload)) - len(payload))
    return body


def members(root):
    result = []
    for base, dirs, files in os.walk(root):
        dirs.sort()
        files.sort()
        relative = os.path.relpath(base, root)
        if relative != ".":
            result.append(relative.replace(os.sep, "/"))
        for name in files:
            result.append(os.path.join(relative, name).replace(os.sep, "/")) if relative != "." else result.append(name)
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--manifest", required=True)
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    output = os.path.abspath(args.output)
    if not os.path.isdir(root):
        raise RuntimeError("root is not a directory: " + root)
    if os.path.exists(output) or os.path.exists(args.manifest):
        raise RuntimeError("refusing to overwrite output or manifest")

    records = []
    plain = []
    for inode, name in enumerate(members(root), 1):
        full = os.path.join(root, *name.split("/"))
        metadata = os.lstat(full)
        mode = stat.S_IFMT(metadata.st_mode) | (metadata.st_mode & 0o7777)
        if stat.S_ISLNK(metadata.st_mode):
            payload = os.readlink(full).encode("utf-8")
            kind = "symlink"
        elif stat.S_ISDIR(metadata.st_mode):
            payload = b""
            kind = "directory"
        elif stat.S_ISREG(metadata.st_mode):
            with open(full, "rb") as handle:
                payload = handle.read()
            if b"BEGIN OPENSSH PRIVATE KEY" in payload or b"BEGIN RSA PRIVATE KEY" in payload:
                raise RuntimeError("private key material rejected: " + name)
            kind = "file"
        else:
            raise RuntimeError("unsupported root member type: " + name)
        plain.append(cpio_entry(name, mode, payload, inode))
        records.append({"path": "/" + name, "kind": kind, "mode": oct(mode & 0o7777),
                        "size": len(payload), "sha256": hashlib.sha256(payload).hexdigest()})
    plain.append(cpio_entry(TRAILER, stat.S_IFREG, b"", len(records) + 1))
    data = b"".join(plain)
    with open(output, "wb") as handle:
        with gzip.GzipFile(filename="", mode="wb", fileobj=handle, mtime=0) as compressed:
            compressed.write(data)
    report = {"schema": "xpr-clean-root-payload-v1", "root": root,
              "members": records, "uncompressed_bytes": len(data),
              "uncompressed_sha256": hashlib.sha256(data).hexdigest(),
              "compressed_bytes": os.path.getsize(output), "compressed_sha256": digest(output)}
    with open(args.manifest, "w") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("payload=%s members=%d sha256=%s" % (output, len(records), report["compressed_sha256"]))


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as exc:
        sys.stderr.write("ERROR: %s\n" % exc)
        sys.exit(2)
