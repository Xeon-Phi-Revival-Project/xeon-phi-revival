#!/usr/bin/env python
"""Inspect and byte-preservingly reconstruct a gzip-compressed newc archive."""
from __future__ import print_function

import argparse
import gzip
import hashlib
import os
import struct
import sys
import zlib

NEWC_HEADER_SIZE = 110
NEWC_MAGIC = b"070701"
TRAILER = b"TRAILER!!!"


def sha256(data):
    return hashlib.sha256(data).hexdigest()


def align4(value):
    return (value + 3) & ~3


def read_bytes(path):
    with open(path, "rb") as handle:
        return handle.read()


def gzip_info(data):
    if len(data) < 10 or data[:2] != b"\x1f\x8b":
        raise ValueError("not a gzip stream")
    flags = ord(data[3:4])
    mtime = struct.unpack("<I", data[4:8])[0]
    return {
        "id1": ord(data[0:1]),
        "id2": ord(data[1:2]),
        "method": ord(data[2:3]),
        "flags": flags,
        "mtime": mtime,
        "xfl": ord(data[8:9]),
        "os": ord(data[9:10]),
    }


def gunzip(data):
    """Return all concatenated gzip members and bytes after the final member."""
    remaining = data
    parts = []
    member_count = 0
    while remaining:
        inflater = zlib.decompressobj(16 + zlib.MAX_WBITS)
        parts.append(inflater.decompress(remaining) + inflater.flush())
        member_count += 1
        remaining = inflater.unused_data
        if not remaining or remaining[:2] != b"\x1f\x8b":
            break
    return b"".join(parts), remaining, member_count


def parse_newc(data):
    entries = []
    offset = 0
    while True:
        if offset + NEWC_HEADER_SIZE > len(data):
            raise ValueError("truncated newc header at {0}".format(offset))
        header = data[offset:offset + NEWC_HEADER_SIZE]
        if header[:6] != NEWC_MAGIC:
            raise ValueError("unexpected newc magic at {0}: {1!r}".format(offset, header[:6]))
        values = [int(header[6 + index * 8:14 + index * 8], 16) for index in range(13)]
        ino, mode, uid, gid, nlink, mtime, size, devmajor, devminor, rdevmajor, rdevminor, namesize, check = values
        name_start = offset + NEWC_HEADER_SIZE
        name_end = name_start + namesize
        if namesize == 0 or name_end > len(data):
            raise ValueError("invalid newc name at {0}".format(offset))
        name_blob = data[name_start:name_end]
        if name_blob[-1:] != b"\0":
            raise ValueError("newc name is not NUL terminated at {0}".format(offset))
        data_start = align4(name_end)
        data_end = data_start + size
        if data_end > len(data):
            raise ValueError("truncated newc payload at {0}".format(offset))
        next_offset = align4(data_end)
        if next_offset > len(data):
            raise ValueError("truncated newc padding at {0}".format(offset))
        entry = {
            "offset": offset,
            "header": header,
            "fields": values,
            "name": name_blob[:-1],
            "name_blob": name_blob,
            "name_padding": data[name_end:data_start],
            "payload": data[data_start:data_end],
            "data_padding": data[data_end:next_offset],
        }
        entries.append(entry)
        offset = next_offset
        if entry["name"] == TRAILER:
            return entries, offset, data[offset:]


def serialize(entries, trailing):
    parts = []
    for entry in entries:
        parts.extend((entry["header"], entry["name_blob"], entry["name_padding"], entry["payload"], entry["data_padding"]))
    parts.append(trailing)
    return b"".join(parts)


def entry_metadata_fingerprint(entry):
    return (
        entry["header"], entry["name_blob"], entry["name_padding"], entry["data_padding"],
    )


def write_report(path, source_path, source_compressed, source_plain, source_tail, source_gzip_members, source_entries, source_trailer_end,
                 output_path, output_compressed, output_plain, output_tail, output_gzip_members, output_entries, output_trailer_end):
    source_gzip = gzip_info(source_compressed)
    output_gzip = gzip_info(output_compressed)
    source_names = [entry["name"].decode("utf-8", "replace") for entry in source_entries]
    output_names = [entry["name"].decode("utf-8", "replace") for entry in output_entries]
    metadata_match = [entry_metadata_fingerprint(entry) for entry in source_entries] == [entry_metadata_fingerprint(entry) for entry in output_entries]
    changed_payloads = [source_names[index] for index, entry in enumerate(source_entries)
                        if entry["payload"] != output_entries[index]["payload"]]
    lines = [
        "format=SVR4-newc",
        "source={0}".format(source_path),
        "source_compressed_bytes={0}".format(len(source_compressed)),
        "source_compressed_sha256={0}".format(sha256(source_compressed)),
        "source_decompressed_bytes={0}".format(len(source_plain)),
        "source_decompressed_sha256={0}".format(sha256(source_plain)),
        "source_gzip_members={0}".format(source_gzip_members),
        "source_member_count={0}".format(len(source_entries)),
        "source_trailer_offset={0}".format(source_trailer_end),
        "source_trailing_bytes={0}".format(len(source_tail)),
        "source_gzip_header={0}".format(",".join("{0}={1}".format(key, source_gzip[key]) for key in sorted(source_gzip))),
        "output={0}".format(output_path),
        "output_compressed_bytes={0}".format(len(output_compressed)),
        "output_compressed_sha256={0}".format(sha256(output_compressed)),
        "output_decompressed_bytes={0}".format(len(output_plain)),
        "output_decompressed_sha256={0}".format(sha256(output_plain)),
        "output_gzip_members={0}".format(output_gzip_members),
        "output_member_count={0}".format(len(output_entries)),
        "output_trailer_offset={0}".format(output_trailer_end),
        "output_trailing_bytes={0}".format(len(output_tail)),
        "output_gzip_header={0}".format(",".join("{0}={1}".format(key, output_gzip[key]) for key in sorted(output_gzip))),
        "member_order_match={0}".format(source_names == output_names),
        "entry_metadata_match={0}".format(metadata_match),
        "payload_changes={0}".format(",".join(changed_payloads)),
        "archive_bytes_match={0}".format(source_plain == output_plain),
        "gzip_bytes_match={0}".format(source_compressed == output_compressed),
    ]
    with open(path, "w") as handle:
        handle.write("\n".join(lines) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--report", required=True)
    parser.add_argument("--replace-entry")
    parser.add_argument("--replace-once")
    parser.add_argument("--with", dest="replacement")
    parser.add_argument("--xprinit-marker", action="store_true",
                        help="replace one same-length stock /init module echo with XPRINIT")
    parser.add_argument("--xprinit-file-marker", action="store_true",
                        help="replace one same-length stock /init module echo with a /tmp/x marker")
    args = parser.parse_args()

    source_compressed = read_bytes(args.source)
    source_plain, source_tail, source_gzip_members = gunzip(source_compressed)
    source_entries, source_trailer_end, source_trailing = parse_newc(source_plain)
    if source_tail:
        raise ValueError("unexpected bytes after gzip stream: {0}".format(len(source_tail)))
    if source_trailing is None:
        raise ValueError("invalid source archive state")

    output_source_entries = [dict(entry) for entry in source_entries]
    if args.xprinit_marker or args.xprinit_file_marker:
        if args.replace_entry or args.replace_once or args.replacement:
            raise ValueError("marker modes cannot be combined with replacement arguments")
        if args.xprinit_marker and args.xprinit_file_marker:
            raise ValueError("select only one marker mode")
        args.replace_entry = "init"
        args.replace_once = "echo $module $args"
        args.replacement = "echo XPRINIT $args" if args.xprinit_marker else "echo XPR >/tmp/x  "
    if args.replace_entry or args.replace_once or args.replacement:
        if not (args.replace_entry and args.replace_once is not None and args.replacement is not None):
            raise ValueError("all replacement arguments are required together")
        old = args.replace_once.encode("ascii")
        new = args.replacement.encode("ascii")
        if len(old) != len(new):
            raise ValueError("replacement must preserve payload length")
        matches = [entry for entry in output_source_entries if entry["name"] == args.replace_entry.encode("ascii")]
        if len(matches) != 1:
            raise ValueError("replacement entry not found exactly once")
        entry = matches[0]
        if entry["payload"].count(old) != 1:
            raise ValueError("replacement text not found exactly once")
        entry["payload"] = entry["payload"].replace(old, new, 1)

    reconstructed = serialize(output_source_entries, source_trailing)
    if not args.replace_entry and reconstructed != source_plain:
        raise ValueError("serializer did not preserve decompressed archive bytes")

    output_dir = os.path.dirname(os.path.abspath(args.output))
    if output_dir and not os.path.isdir(output_dir):
        os.makedirs(output_dir)
    with open(args.output, "wb") as handle:
        with gzip.GzipFile(filename="", mode="wb", fileobj=handle, compresslevel=9, mtime=0) as gz:
            gz.write(reconstructed)

    output_compressed = read_bytes(args.output)
    output_plain, output_tail, output_gzip_members = gunzip(output_compressed)
    output_entries, output_trailer_end, output_trailing = parse_newc(output_plain)
    if output_tail:
        raise ValueError("unexpected bytes after output gzip stream: {0}".format(len(output_tail)))
    write_report(args.report, args.source, source_compressed, source_plain, source_tail, source_gzip_members, source_entries, source_trailer_end,
                 args.output, output_compressed, output_plain, output_tail, output_gzip_members, output_entries, output_trailer_end)
    if not args.replace_entry and source_plain != output_plain:
        raise ValueError("reconstructed decompressed archive differs from source")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("newc_archive.py: {0}".format(error), file=sys.stderr)
        sys.exit(1)
