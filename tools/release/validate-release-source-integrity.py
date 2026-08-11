#!/usr/bin/env python3
"""Fail closed when source-package configuration bytes differ from provenance."""
from __future__ import print_function

import argparse
import hashlib
import os
import sys


def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def parse_config(value):
    try:
        relative, expected = value.rsplit("=", 1)
    except ValueError:
        raise ValueError("expected PATH=SHA256: " + value)
    if len(expected) != 64 or any(char not in "0123456789abcdef" for char in expected.lower()):
        raise ValueError("invalid SHA256 in: " + value)
    if not relative or os.path.isabs(relative) or ".." in relative.replace("\\", "/").split("/"):
        raise ValueError("unsafe relative path: " + relative)
    return relative.replace("\\", "/"), expected.lower()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True, help="repository root from the staged source package")
    parser.add_argument("--config", action="append", default=[], metavar="PATH=SHA256",
                        help="configuration file that must be LF-only and hash exactly")
    args = parser.parse_args()
    if not args.config:
        parser.error("at least one --config is required")

    root = os.path.abspath(args.root)
    if not os.path.isdir(root):
        raise RuntimeError("source root is not a directory: " + root)

    for value in args.config:
        relative, expected = parse_config(value)
        path = os.path.join(root, *relative.split("/"))
        if not os.path.isfile(path):
            raise RuntimeError("required configuration missing: " + relative)
        with open(path, "rb") as handle:
            data = handle.read()
        if b"\r" in data:
            raise RuntimeError("newline transformation rejected: " + relative)
        actual = sha256(path)
        if actual != expected:
            raise RuntimeError("configuration hash mismatch for %s: expected %s, got %s" %
                               (relative, expected, actual))
        print("SOURCE_CONFIG_INTEGRITY=PASS path=%s sha256=%s" % (relative, actual))


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, ValueError) as exc:
        sys.stderr.write("ERROR: %s\n" % exc)
        sys.exit(2)
