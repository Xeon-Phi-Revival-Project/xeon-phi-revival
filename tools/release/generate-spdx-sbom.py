#!/usr/bin/env python3
"""Generate a compact SPDX 2.3 JSON SBOM from an XPR image audit and ledger."""
import argparse
import datetime
import io
import json
import os


def component_license(component):
    return component.get("spdx_license", component["license"])


def component_download_location(component):
    return component.get("spdx_download_location", component["source_url"])


def component_source_info(component):
    return "source_sha256={0}; corresponding_source={1}; build_recipe={2}".format(
        component.get("source_sha256", "NOASSERTION"),
        component.get("corresponding_source", "NOASSERTION"),
        component.get("build_recipe", "NOASSERTION"))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--audit", required=True)
    parser.add_argument("--ledger", required=True)
    parser.add_argument("--output", required=True)
    parser.add_argument("--include-component", action="append", default=[])
    parser.add_argument("--external-file", action="append", default=[],
                        help="COMPONENT:PATH=SHA256 for a release file outside the audited root")
    parser.add_argument("--release-version", required=True,
                        help="version of the top-level binary XPR-OS release package")
    parser.add_argument("--release-file", action="append", default=[],
                        help="PATH=SHA256 for a container shipped by the binary release")
    args = parser.parse_args()
    audit = json.load(io.open(args.audit, encoding="utf-8"))
    ledger = json.load(io.open(args.ledger, encoding="utf-8"))
    used = set(row.get("component") for row in audit.get("inventory", []) if row.get("component"))
    used.update(args.include_component)
    release_id = "SPDXRef-XPRRelease"
    packages = [{"SPDXID": release_id, "name": "XPR-OS",
                 "versionInfo": args.release_version, "downloadLocation": "NOASSERTION",
                 "licenseConcluded": "NOASSERTION", "licenseDeclared": "NOASSERTION",
                 "copyrightText": "NOASSERTION", "supplier": "NOASSERTION",
                 "filesAnalyzed": False,
                 "sourceInfo": "Source inputs are in the paired XPR-OS source archive."}]
    for item in ledger.get("components", []):
        if item.get("id") not in used:
            continue
        packages.append({"SPDXID": item["spdx_id"], "name": item["id"],
                         "versionInfo": item["version"],
                         "downloadLocation": component_download_location(item),
                         "licenseConcluded": component_license(item),
                         "licenseDeclared": component_license(item),
                         "copyrightText": item.get("copyright", "NOASSERTION"),
                         "supplier": "NOASSERTION", "filesAnalyzed": False,
                         "sourceInfo": component_source_info(item)})
    files = []
    relationships = []
    component_spdx = dict((item.get("id"), item.get("spdx_id"))
                          for item in ledger.get("components", []))
    components = dict((item.get("id"), item) for item in ledger.get("components", []))
    for row in audit.get("inventory", []):
        if row.get("component"):
            component = components[row["component"]]
            file_id = "SPDXRef-File-" + row["sha256"][:16]
            files.append({"SPDXID": file_id, "fileName": "." + row["path"],
                          "checksums": [{"algorithm": "SHA256", "checksumValue": row["sha256"]}],
                          "licenseConcluded": component_license(component),
                          "licenseInfoInFiles": ["NONE"],
                          "copyrightText": component.get("copyright", "NOASSERTION")})
            relationships.append({"spdxElementId": component_spdx[row["component"]],
                                  "relationshipType": "CONTAINS", "relatedSpdxElement": file_id})
    for value in args.external_file:
        try:
            component, remainder = value.split(":", 1)
            path, sha256 = remainder.rsplit("=", 1)
        except ValueError:
            parser.error("invalid --external-file, expected COMPONENT:PATH=SHA256")
        if component not in component_spdx or len(sha256) != 64:
            parser.error("invalid component or SHA256 in --external-file: " + value)
        file_id = "SPDXRef-File-" + sha256[:16]
        component_record = components[component]
        files.append({"SPDXID": file_id, "fileName": path,
                      "checksums": [{"algorithm": "SHA256", "checksumValue": sha256}],
                      "licenseConcluded": component_license(component_record),
                      "licenseInfoInFiles": ["NONE"],
                      "copyrightText": component_record.get("copyright", "NOASSERTION")})
        relationships.append({"spdxElementId": component_spdx[component],
                              "relationshipType": "CONTAINS", "relatedSpdxElement": file_id})
    for value in args.release_file:
        try:
            path, sha256 = value.rsplit("=", 1)
        except ValueError:
            parser.error("invalid --release-file, expected PATH=SHA256")
        if not path.startswith("./") or len(sha256) != 64:
            parser.error("invalid path or SHA256 in --release-file: " + value)
        file_id = "SPDXRef-ReleaseFile-" + sha256[:16]
        files.append({"SPDXID": file_id, "fileName": path,
                      "checksums": [{"algorithm": "SHA256", "checksumValue": sha256}],
                      "licenseConcluded": "NOASSERTION", "licenseInfoInFiles": ["NONE"],
                      "copyrightText": "NOASSERTION",
                      "comment": "Shipped release container; see paired source package and release manifest."})
        relationships.append({"spdxElementId": release_id, "relationshipType": "CONTAINS",
                              "relatedSpdxElement": file_id})
    epoch = os.environ.get("SOURCE_DATE_EPOCH")
    created = (datetime.datetime.utcfromtimestamp(int(epoch)) if epoch else
               datetime.datetime.utcnow()).replace(microsecond=0).isoformat() + "Z"
    extracted = []
    for item in ledger.get("components", []):
        if item.get("id") in used and item.get("spdx_extracted_license"):
            extracted_license = item["spdx_extracted_license"]
            extracted.append({"licenseId": extracted_license["id"],
                              "name": extracted_license["name"],
                              "extractedText": "See " + extracted_license["text_file"] +
                                               " in the paired release archive."})
    doc = {"spdxVersion": "SPDX-2.3", "dataLicense": "CC0-1.0", "SPDXID": "SPDXRef-DOCUMENT",
           "name": "xpr-k1om-uos-prebuilt", "documentNamespace": "https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/spdx/" + audit.get("artifact", {}).get("sha256", "rootfs"),
           "creationInfo": {"created": created, "creators": ["Tool: xpr generate-spdx-sbom.py"]},
           "packages": packages, "files": files, "relationships": relationships,
           "hasExtractedLicensingInfos": extracted}
    relationships.insert(0, {"spdxElementId": "SPDXRef-DOCUMENT", "relationshipType": "DESCRIBES",
                             "relatedSpdxElement": release_id})
    with open(args.output, "w") as handle:
        json.dump(doc, handle, indent=2, sort_keys=True)
        handle.write("\n")
    print("SPDX packages=%d files=%d output=%s" % (len(packages), len(files), args.output))


if __name__ == "__main__":
    main()
