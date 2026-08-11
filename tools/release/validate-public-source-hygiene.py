#!/usr/bin/env python3
"""Reject developer-specific absolute paths in a staged public source tree."""
from __future__ import print_function

import argparse
import io
import json
import os
import re
import sys


PATTERNS = (
    re.compile(r"(?i)[a-z]:[\\/]users[\\/]"),
    re.compile(r"(?i)(?:^|[\\/])onedrive(?:[\\/]|$)"),
    re.compile(r"/(?:root|home)/(?:xpr|xeon|mpss|phi-kernel|intel)[^/\\\"'`[:space:]]*"),
)


def text_file(path):
    try:
        data = open(path, "rb").read()
    except IOError:
        return None
    if b"\0" in data:
        return None
    return data.decode("utf-8", "replace")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--policy", required=True)
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    policy = json.load(io.open(args.policy, encoding="utf-8"))
    if policy.get("schema") != "xpr-public-source-archive-policy-v1":
        raise RuntimeError("unexpected public-source archive policy schema")
    allow_paths = set(policy.get("allow_paths", []))
    findings = []
    for base, directories, files in os.walk(root):
        directories.sort()
        files.sort()
        for name in files:
            path = os.path.join(base, name)
            text = text_file(path)
            if text is None:
                continue
            relative = os.path.relpath(path, root).replace(os.sep, "/")
            if relative in allow_paths:
                continue
            for line_number, line in enumerate(text.splitlines(), 1):
                if any(pattern.search(line) for pattern in PATTERNS):
                    findings.append("%s:%d" % (relative, line_number))
    if findings:
        for finding in findings:
            sys.stderr.write("PRIVATE_BUILD_PATH_LEAK=%s\n" % finding)
        return 1
    print("PRIVATE_BUILD_PATH_LEAKS=0")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (IOError, OSError, RuntimeError, ValueError) as exc:
        sys.stderr.write("ERROR: %s\n" % exc)
        sys.exit(2)
