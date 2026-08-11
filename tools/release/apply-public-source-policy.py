#!/usr/bin/env python3
"""Apply the tracked public-source archive exclusion policy to a staged tree."""
from __future__ import print_function

import argparse
import io
import json
import os
import shutil
import sys


def safe_relative(path):
    normal = path.replace("\\", "/")
    return normal and not normal.startswith("/") and ".." not in normal.split("/")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--policy", required=True)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    root = os.path.abspath(args.root)
    policy = json.load(io.open(args.policy, encoding="utf-8"))
    if policy.get("schema") != "xpr-public-source-archive-policy-v1":
        raise RuntimeError("unexpected public-source archive policy schema")
    removed = []
    targets = list(policy.get("exclude_prefixes", [])) + list(policy.get("exclude_paths", []))
    for relative in targets:
        if not safe_relative(relative):
            raise RuntimeError("unsafe policy path: " + relative)
        path = os.path.join(root, *relative.rstrip("/").split("/"))
        if not os.path.lexists(path):
            continue
        if os.path.isdir(path) and not os.path.islink(path):
            shutil.rmtree(path)
        else:
            os.unlink(path)
        removed.append(relative)
    for relative in policy.get("required_paths", []):
        if not safe_relative(relative) or not os.path.exists(os.path.join(root, *relative.split("/"))):
            raise RuntimeError("required public-source path missing after policy: " + relative)
    print("PUBLIC_SOURCE_POLICY=PASS version=%s removed=%d" % (args.version, len(removed)))
    for relative in removed:
        print("PUBLIC_SOURCE_EXCLUDED=" + relative)


if __name__ == "__main__":
    try:
        main()
    except (IOError, OSError, RuntimeError, ValueError) as exc:
        sys.stderr.write("ERROR: %s\n" % exc)
        sys.exit(2)
