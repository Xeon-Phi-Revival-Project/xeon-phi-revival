#!/usr/bin/env python3
"""Replace selected newc member payloads without changing archive metadata or size."""

import argparse
import gzip
import hashlib
import os

MAGIC = b"070701"
HEADER = 110
TRAILER = "TRAILER!!!"


def align4(value):
    return (value + 3) & ~3


def deterministic_bytes(length):
    chunks, counter = [], 0
    while length:
        block = hashlib.sha256(("xpr-mask-%08d" % counter).encode("ascii")).digest()
        chunks.append(block[:min(length, len(block))])
        length -= len(chunks[-1])
        counter += 1
    return b"".join(chunks)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--source", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--manifest", required=True)
    parser.add_argument("--prefix", action="append", required=True)
    args = parser.parse_args()
    original = open(args.source, "rb").read()
    with gzip.GzipFile(args.source, "rb") as source_gzip:
        plain = bytearray(source_gzip.read())
    cursor, masked = 0, []
    while True:
        offset = plain.find(MAGIC, cursor)
        if offset < 0:
            break
        header = bytes(plain[offset:offset + HEADER])
        try:
            fields = [int(header[6 + index * 8:14 + index * 8], 16) for index in range(13)]
        except ValueError:
            cursor = offset + 6
            continue
        size, namesize = fields[6], fields[11]
        name_start, name_end = offset + HEADER, offset + HEADER + namesize
        if not namesize or name_end > len(plain) or plain[name_end - 1:name_end] != b"\0":
            cursor = offset + 6
            continue
        name = bytes(plain[name_start:name_end - 1]).decode("utf-8", "replace")
        data_start, data_end = align4(name_end), align4(name_end) + size
        if data_end > len(plain):
            cursor = offset + 6
            continue
        if name != TRAILER and any(name.startswith(prefix) for prefix in args.prefix):
            plain[data_start:data_end] = deterministic_bytes(size)
            masked.append((name, size))
        cursor = offset + HEADER
        if name == TRAILER:
            break
    if not masked:
        raise ValueError("no matching initramfs members")
    with open(args.output, "wb") as handle:
        with gzip.GzipFile(filename="", mode="wb", fileobj=handle, mtime=0, compresslevel=9) as output_gzip:
            output_gzip.write(bytes(plain))
    with open(args.manifest, "w") as handle:
        handle.write("source_sha256=%s\n" % hashlib.sha256(original).hexdigest())
        handle.write("output_sha256=%s\n" % hashlib.sha256(open(args.output, "rb").read()).hexdigest())
        handle.write("masked_members=%d\nmasked_bytes=%d\n" % (len(masked), sum(size for _, size in masked)))
        for name, size in masked:
            handle.write("%d\t%s\n" % (size, name))


if __name__ == "__main__":
    main()
