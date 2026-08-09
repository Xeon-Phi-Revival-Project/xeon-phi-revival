#!/usr/bin/env python
"""Inspect and byte-preservingly reconstruct a gzip-compressed newc archive."""
from __future__ import print_function

import argparse
import gzip
import hashlib
import os
import stat
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


def replace_payload(entry, payload):
    if len(payload) > 0xffffffff:
        raise ValueError("replacement payload is too large for newc")
    header = entry["header"]
    size_start = 6 + 6 * 8
    entry["header"] = header[:size_start] + ("%08X" % len(payload)).encode("ascii") + header[size_start + 8:]
    entry["payload"] = payload
    entry["data_padding"] = b"\0" * (align4(len(payload)) - len(payload))


def set_permissions(entry, permissions):
    mode = (entry["fields"][1] & ~0o7777) | permissions
    header = entry["header"]
    mode_start = 6 + 8
    entry["header"] = header[:mode_start] + ("%08X" % mode).encode("ascii") + header[mode_start + 8:]
    entry["fields"][1] = mode


def new_entry(name, mode, payload):
    """Create a deterministic newc entry for a project-supplied payload."""
    name_blob = name.encode("ascii") + b"\0"
    values = (0, mode, 0, 0, 1, 0, len(payload), 0, 0, 0, 0, len(name_blob), 0)
    header = NEWC_MAGIC + b"".join(("%08X" % value).encode("ascii") for value in values)
    return {
        "offset": None,
        "header": header,
        "fields": list(values),
        "name": name.encode("ascii"),
        "name_blob": name_blob,
        "name_padding": b"\0" * (align4(len(header) + len(name_blob)) - len(header) - len(name_blob)),
        "payload": payload,
        "data_padding": b"\0" * (align4(len(payload)) - len(payload)),
    }


def append_entry(entries, name, mode, payload):
    if name.startswith("/") or not name or ".." in name.split("/"):
        raise ValueError("invalid archive member name: {0}".format(name))
    encoded = name.encode("ascii")
    if any(entry["name"] == encoded for entry in entries):
        raise ValueError("archive member already exists: {0}".format(name))
    entries.insert(-1, new_entry(name, mode, payload))


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
    added_members = [name for name in output_names if name not in source_names]
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
        "added_members={0}".format(",".join(added_members)),
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
    parser.add_argument("--replace-entry-from", metavar="FILE")
    parser.add_argument("--replace-entry-file", action="append", default=[], metavar="NAME=FILE")
    parser.add_argument("--set-mode", action="append", default=[], metavar="NAME=OCTAL")
    parser.add_argument("--assert-executable", action="append", default=[], metavar="NAME")
    parser.add_argument("--add-directory", action="append", default=[], metavar="NAME")
    parser.add_argument("--add-entry-from", action="append", default=[], metavar="NAME=FILE")
    parser.add_argument("--ensure-symlink", action="append", default=[], metavar="NAME=TARGET")
    parser.add_argument("--xprinit-marker", action="store_true",
                        help="replace one same-length stock /init module echo with XPRINIT")
    parser.add_argument("--xprinit-file-marker", action="store_true",
                        help="replace one same-length stock /init module echo with an /etc/x marker")
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
        if args.replace_entry or args.replace_once or args.replacement or args.replace_entry_from or args.replace_entry_file:
            raise ValueError("marker modes cannot be combined with replacement arguments")
        if args.xprinit_marker and args.xprinit_file_marker:
            raise ValueError("select only one marker mode")
        args.replace_entry = "init"
        args.replace_once = "echo $module $args"
        args.replacement = "echo XPRINIT $args" if args.xprinit_marker else "echo XPR >/etc/x  "
    if args.replace_entry or args.replace_once or args.replacement or args.replace_entry_from:
        if not args.replace_entry:
            raise ValueError("--replace-entry is required for a replacement")
        matches = [entry for entry in output_source_entries if entry["name"] == args.replace_entry.encode("ascii")]
        if len(matches) != 1:
            raise ValueError("replacement entry not found exactly once")
        entry = matches[0]
        if args.replace_entry_from:
            if args.replace_once is not None or args.replacement is not None:
                raise ValueError("file and text replacement modes cannot be combined")
            replace_payload(entry, read_bytes(args.replace_entry_from))
        else:
            if args.replace_once is None or args.replacement is None:
                raise ValueError("text replacement requires --replace-once and --with")
            old = args.replace_once.encode("ascii")
            new = args.replacement.encode("ascii")
            if len(old) != len(new):
                raise ValueError("replacement must preserve payload length")
            if entry["payload"].count(old) != 1:
                raise ValueError("replacement text not found exactly once")
            entry["payload"] = entry["payload"].replace(old, new, 1)

    for spec in args.replace_entry_file:
        if "=" not in spec:
            raise ValueError("--replace-entry-file must be NAME=FILE")
        name, path = spec.split("=", 1)
        matches = [entry for entry in output_source_entries if entry["name"] == name.encode("ascii")]
        if len(matches) != 1:
            raise ValueError("replacement entry not found exactly once: {0}".format(name))
        replace_payload(matches[0], read_bytes(path))

    for spec in args.set_mode:
        if "=" not in spec:
            raise ValueError("--set-mode must be NAME=OCTAL")
        name, mode_text = spec.split("=", 1)
        try:
            permissions = int(mode_text, 8)
        except ValueError:
            raise ValueError("invalid octal mode: {0}".format(mode_text))
        matches = [entry for entry in output_source_entries if entry["name"] == name.encode("ascii")]
        if len(matches) != 1:
            raise ValueError("mode entry not found exactly once: {0}".format(name))
        set_permissions(matches[0], permissions)

    for spec in args.ensure_symlink:
        if "=" not in spec:
            raise ValueError("--ensure-symlink must be NAME=TARGET")
        name, target = spec.split("=", 1)
        matches = [entry for entry in output_source_entries if entry["name"] == name.encode("ascii")]
        if len(matches) > 1:
            raise ValueError("symlink entry found more than once: {0}".format(name))
        if matches:
            mode = matches[0]["fields"][1]
            if stat.S_IFMT(mode) != stat.S_IFLNK or matches[0]["payload"] != target.encode("ascii"):
                raise ValueError("existing entry is not expected symlink: {0}".format(name))
        else:
            append_entry(output_source_entries, name, stat.S_IFLNK | 0o777, target.encode("ascii"))

    for name in args.add_directory:
        append_entry(output_source_entries, name.rstrip("/"), stat.S_IFDIR | 0o755, b"")
    for spec in args.add_entry_from:
        if "=" not in spec:
            raise ValueError("--add-entry-from must be NAME=FILE")
        name, path = spec.split("=", 1)
        source_mode = stat.S_IMODE(os.stat(path).st_mode)
        append_entry(output_source_entries, name, stat.S_IFREG | source_mode, read_bytes(path))

    reconstructed = serialize(output_source_entries, source_trailing)
    has_changes = bool(args.replace_entry or args.replace_entry_file or args.add_directory or args.add_entry_from or args.ensure_symlink or args.set_mode)
    if not has_changes and reconstructed != source_plain:
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
    for name in args.assert_executable:
        matches = [entry for entry in output_entries if entry["name"] == name.encode("ascii")]
        if len(matches) != 1:
            raise ValueError("executable assertion entry not found exactly once: {0}".format(name))
        mode = matches[0]["fields"][1]
        if stat.S_IFMT(mode) != stat.S_IFREG or not (mode & 0o111):
            raise ValueError("executable assertion failed: {0} mode {1:04o}".format(name, mode & 0o7777))
        print("XPR_PAYLOAD_MODE_OK {0} {1:04o}".format(name, mode & 0o7777))
    if not has_changes and source_plain != output_plain:
        raise ValueError("reconstructed decompressed archive differs from source")


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print("newc_archive.py: {0}".format(error), file=sys.stderr)
        sys.exit(1)
