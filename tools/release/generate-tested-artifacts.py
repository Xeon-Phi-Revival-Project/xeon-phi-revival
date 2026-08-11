#!/usr/bin/env python3
"""Generate immutable release artifact metadata from the files being staged."""
from __future__ import print_function

import argparse
import hashlib
import json
import os


def digest(path):
    value = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            value.update(block)
    return value.hexdigest()


def item(identity, path, source):
    return {"id": identity, "path": path[0], "sha256": digest(path[1]), "source": source,
            "redistribution": "hold-human-review"}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--kernel", required=True)
    parser.add_argument("--system-map", required=True)
    parser.add_argument("--bootstrap", required=True)
    parser.add_argument("--payload", required=True)
    parser.add_argument("--module", action="append", default=[], help="ID=PATH")
    parser.add_argument("--validation-status", choices=("pending", "passed"), required=True)
    parser.add_argument("--output", required=True)
    args = parser.parse_args()
    if len(args.commit) != 40 or any(character not in "0123456789abcdef" for character in args.commit):
        parser.error("--commit must be a full lowercase Git SHA")
    modules = []
    for value in args.module:
        try:
            identity, path = value.split("=", 1)
        except ValueError:
            parser.error("invalid --module, expected ID=PATH")
        modules.append(item(identity, ("modules/" + os.path.basename(path), path), "source-built module"))
    records = [
        item("kernel", ("kernel/bzImage", args.kernel), "source-built compatibility kernel"),
        item("system-map", ("kernel/System.map", args.system_map), "source-built compatibility kernel"),
        item("base-cpio", ("bootstrap/xpr-bootstrap.cpio.gz", args.bootstrap), "project outer Base CPIO builder"),
        item("final-root-payload", ("payload/xpr-rootfs.cpio.gz", args.payload), "project public-root builder"),
    ] + modules
    result = {"schema": "xpr-tested-artifact-freeze-v2", "release_version": args.version,
              "status": "hardware-validation-" + args.validation_status,
              "repository_commit": args.commit, "artifacts": records}
    with open(args.output, "w") as handle:
        json.dump(result, handle, indent=2, sort_keys=True)
        handle.write("\n")


if __name__ == "__main__":
    main()
