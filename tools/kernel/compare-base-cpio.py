#!/usr/bin/env python
"""Compare two gzip-compressed newc Base CPIO archives without extracting them."""
from __future__ import print_function

import argparse
import hashlib
import imp
import json
import os
import stat

HERE = os.path.dirname(os.path.abspath(__file__))
NEWC = imp.load_source("xpr_newc_archive", os.path.join(HERE, "..", "uos", "newc_archive.py"))


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def file_type(mode):
    return {
        stat.S_IFREG: "file", stat.S_IFDIR: "directory", stat.S_IFLNK: "symlink",
        stat.S_IFCHR: "char", stat.S_IFBLK: "block", stat.S_IFIFO: "fifo",
        stat.S_IFSOCK: "socket"
    }.get(stat.S_IFMT(mode), "unknown")


def inventory(path):
    raw = open(path, "rb").read()
    plain, trailing, gzip_members = NEWC.gunzip(raw)
    entries, trailer_offset, archive_trailing = NEWC.parse_newc(plain)
    rows = []
    for item in entries:
        name = item["name"].decode("utf-8", "replace")
        if name == "TRAILER!!!":
            continue
        fields = item["fields"]
        mode = fields[1]
        rows.append({
            "path": "/" + name.lstrip("./"), "type": file_type(mode), "mode": mode,
            "uid": fields[2], "gid": fields[3], "nlink": fields[4], "mtime": fields[5],
            "size": fields[6], "rdevmajor": fields[9], "rdevminor": fields[10],
            "payload_sha256": sha256(item["payload"]),
            "symlink_target": item["payload"].decode("utf-8", "replace") if stat.S_ISLNK(mode) else None,
        })
    paths = [row["path"] for row in rows]
    return {"path": os.path.abspath(path), "compressed_bytes": len(raw), "compressed_sha256": sha256(raw),
            "uncompressed_bytes": len(plain), "uncompressed_sha256": sha256(plain),
            "gzip_members": gzip_members, "gzip_trailing_bytes": len(trailing),
            "archive_trailing_bytes": len(archive_trailing), "trailer_offset": trailer_offset,
            "members": rows, "duplicate_paths": sorted(set(name for name in paths if paths.count(name) > 1))}


def top_level(rows):
    result = {}
    for row in rows:
        name = row["path"].split("/", 2)[1] if row["path"].count("/") else ""
        result[name] = result.get(name, 0) + 1
    return result


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--accepted", required=True)
    parser.add_argument("--candidate", required=True)
    parser.add_argument("--json", required=True)
    parser.add_argument("--markdown", required=True)
    args = parser.parse_args()
    accepted, candidate = inventory(args.accepted), inventory(args.candidate)
    old = dict((row["path"], row) for row in accepted["members"])
    new = dict((row["path"], row) for row in candidate["members"])
    added = sorted(set(new) - set(old))
    removed = sorted(set(old) - set(new))
    compared = ("type", "mode", "uid", "gid", "nlink", "mtime", "size", "rdevmajor", "rdevminor", "payload_sha256", "symlink_target")
    changed = sorted(path for path in set(old).intersection(new) if any(old[path][key] != new[path][key] for key in compared))
    early_prefixes = ("/init", "/sbin/", "/bin/", "/xpr-tools/", "/xpr-rootfs.cpio.gz", "/lib/", "/lib64/", "/dev/", "/etc/", "/opt/xeon-phi-revival/", "/lib/modules/")
    critical = sorted(path for path in added + removed + changed if path == "/init" or path.startswith(early_prefixes))
    report = {"schema": "xpr-base-cpio-comparison-v1", "accepted": accepted, "candidate": candidate,
              "added_paths": added, "removed_paths": removed, "changed_paths": changed,
              "early_boot_deltas": critical}
    with open(args.json, "w") as handle:
        json.dump(report, handle, indent=2, sort_keys=True)
        handle.write("\n")
    lines = ["# Base CPIO Comparison", "", "| Field | Accepted | Candidate |", "| --- | ---: | ---: |"]
    for field in ("compressed_bytes", "uncompressed_bytes", "gzip_members", "trailer_offset"):
        lines.append("| %s | %s | %s |" % (field, accepted[field], candidate[field]))
    lines.extend(["", "- Accepted SHA-256: `%s`" % accepted["compressed_sha256"],
                  "- Candidate SHA-256: `%s`" % candidate["compressed_sha256"],
                  "- Added paths: %d" % len(added), "- Removed paths: %d" % len(removed),
                  "- Changed paths: %d" % len(changed), "- Early-boot deltas: %d" % len(critical), "",
                  "## Top-Level Members", "", "| Directory | Accepted | Candidate |", "| --- | ---: | ---: |"])
    old_top, new_top = top_level(accepted["members"]), top_level(candidate["members"])
    for name in sorted(set(old_top).union(new_top)):
        lines.append("| /%s | %d | %d |" % (name, old_top.get(name, 0), new_top.get(name, 0)))
    lines.extend(["", "## Early-Boot Deltas", ""] + ["- `%s`" % path for path in critical])
    with open(args.markdown, "w") as handle:
        handle.write("\n".join(lines) + "\n")
    print("accepted_members=%d candidate_members=%d added=%d removed=%d changed=%d early=%d" %
          (len(old), len(new), len(added), len(removed), len(changed), len(critical)))


if __name__ == "__main__":
    main()
