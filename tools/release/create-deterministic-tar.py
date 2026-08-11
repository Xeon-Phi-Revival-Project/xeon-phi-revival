#!/usr/bin/env python
"""Create a deterministic uncompressed tar archive from one directory tree."""
from __future__ import print_function

import argparse
import os
import tarfile


def paths_below(root):
    yield root
    for base, dirs, files in os.walk(root):
        dirs.sort()
        files.sort()
        for name in dirs:
            yield os.path.join(base, name)
        for name in files:
            yield os.path.join(base, name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--root", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--mtime", required=True, type=int)
    args = parser.parse_args()

    root = os.path.abspath(args.root)
    parent = os.path.dirname(root)
    if not os.path.isdir(root):
        parser.error("root is not a directory: " + root)

    with tarfile.open(args.output, "w", format=tarfile.GNU_FORMAT) as archive:
        for path in paths_below(root):
            arcname = os.path.relpath(path, parent).replace(os.sep, "/")
            info = archive.gettarinfo(path, arcname)
            info.uid = 0
            info.gid = 0
            info.uname = ""
            info.gname = ""
            info.mtime = args.mtime
            if info.isfile():
                with open(path, "rb") as payload:
                    archive.addfile(info, payload)
            else:
                archive.addfile(info)

    print("deterministic_tar=" + os.path.abspath(args.output))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
