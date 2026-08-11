#!/usr/bin/env python3
"""Strict local SPDX 2.3 sanity validation for XPR release metadata."""
from __future__ import print_function

import argparse
import io
import json
import re
import sys


LICENSE_IDS = set(("MIT", "GPL-2.0-only", "GPL-3.0-only", "GPL-3.0-or-later", "LGPL-2.1-or-later",
                   "PSF-2.0", "CC0-1.0"))
EXCEPTION_IDS = set(("GCC-exception-3.1",))
LOCATION = re.compile(r"^(?:https?://|git(?:\+git|\+https|\+http|\+ssh)?://|NONE$|NOASSERTION$)")
TOKEN = re.compile(r"LicenseRef-[A-Za-z0-9.-]+|[A-Za-z0-9.+-]+|\(|\)")


def valid_expression(value, extracted):
    if value in ("NONE", "NOASSERTION"):
        return True
    tokens = TOKEN.findall(value)
    if "".join(tokens) != re.sub(r"\s+", "", value):
        return False
    expect_term = True
    index = 0
    while index < len(tokens):
        token = tokens[index]
        if expect_term:
            if token == "(":
                pass
            elif token in LICENSE_IDS or token in extracted:
                expect_term = False
            else:
                return False
        else:
            if token == ")":
                pass
            elif token in ("AND", "OR"):
                expect_term = True
            elif token == "WITH":
                index += 1
                if index >= len(tokens) or tokens[index] not in EXCEPTION_IDS:
                    return False
            else:
                return False
        index += 1
    return not expect_term


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--input", required=True)
    parser.add_argument("--require-release-coverage", action="store_true")
    args = parser.parse_args()
    document = json.load(io.open(args.input, encoding="utf-8"))
    errors = []
    if document.get("spdxVersion") != "SPDX-2.3":
        errors.append("spdxVersion must be SPDX-2.3")
    extracted = set(item.get("licenseId") for item in document.get("hasExtractedLicensingInfos", []))
    for item in document.get("hasExtractedLicensingInfos", []):
        if not item.get("licenseId", "").startswith("LicenseRef-") or not item.get("extractedText"):
            errors.append("invalid extracted licensing information")
    ids = set(("SPDXRef-DOCUMENT",))
    for package in document.get("packages", []):
        package_id = package.get("SPDXID")
        if not package_id or package_id in ids:
            errors.append("duplicate or missing package SPDXID: " + str(package_id))
        ids.add(package_id)
        if not LOCATION.match(package.get("downloadLocation", "")):
            errors.append("invalid downloadLocation for " + str(package.get("name")))
        for field in ("licenseDeclared", "licenseConcluded"):
            if not valid_expression(package.get(field, ""), extracted):
                errors.append("invalid %s for %s" % (field, package.get("name")))
    for file_record in document.get("files", []):
        file_id = file_record.get("SPDXID")
        if not file_id or file_id in ids:
            errors.append("duplicate or missing file SPDXID: " + str(file_id))
        ids.add(file_id)
        for field in ("licenseConcluded",):
            if not valid_expression(file_record.get(field, ""), extracted):
                errors.append("invalid %s for %s" % (field, file_record.get("fileName")))
        for value in file_record.get("licenseInfoInFiles", []):
            if not valid_expression(value, extracted):
                errors.append("invalid licenseInfoInFiles for " + str(file_record.get("fileName")))
    for relation in document.get("relationships", []):
        if relation.get("spdxElementId") not in ids or relation.get("relatedSpdxElement") not in ids:
            errors.append("relationship references unknown SPDX ID")
    if args.require_release_coverage:
        release_id = "SPDXRef-XPRRelease"
        release_files = set()
        for relation in document.get("relationships", []):
            if relation.get("spdxElementId") == "SPDXRef-DOCUMENT" and \
               relation.get("relationshipType") == "DESCRIBES" and \
               relation.get("relatedSpdxElement") == release_id:
                release_files.add("document")
            if relation.get("spdxElementId") == release_id and relation.get("relationshipType") == "CONTAINS":
                release_files.add(relation.get("relatedSpdxElement"))
        names = dict((item.get("SPDXID"), item.get("fileName")) for item in document.get("files", []))
        covered = set(names.get(item) for item in release_files if item in names)
        if release_id not in ids or "document" not in release_files:
            errors.append("top-level XPR release package is not described by the SPDX document")
        for required in ("./bootstrap/xpr-bootstrap.cpio.gz", "./payload/xpr-rootfs.cpio.gz"):
            if required not in covered:
                errors.append("release SPDX does not cover " + required)
    if errors:
        for error in sorted(set(errors)):
            sys.stderr.write("SPDX_2_3_VALIDATION=FAIL %s\n" % error)
        return 1
    print("SPDX_2_3_VALIDATION=PASS packages=%d files=%d" %
          (len(document.get("packages", [])), len(document.get("files", []))))
    return 0


if __name__ == "__main__":
    sys.exit(main())
