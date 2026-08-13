#!/usr/bin/env python3
"""Create source, notices, manifest, and SPDX sidecars for the tested toolkit."""
from __future__ import print_function
import argparse
import hashlib
import json
import os
import shutil
import tarfile
import tempfile
from datetime import datetime

EXPECTED_TOOLKIT_SHA256 = "8227898056918423beab850b4daddd01423e88e75332698f636720d4b6fd6cc2"
UPSTREAM = (
    ("gcc-5.1.1-knc-af7cc04.tar.gz", "6538edbd3c309eb7c37bb215c40ef9822c7c015928ff354267eac2178cf5f1e3"),
    ("gmp-4.3.2.tar.bz2", "936162c0312886c21581002b79932829aa048cfaf9937c6265aeaa14f1cd1775"),
    ("mpfr-2.4.2.tar.bz2", "c7e75a08a8d49d2082e4caee1591a05d11b9d5627514e678f02d66a124bcf2ba"),
    ("mpc-0.8.1.tar.gz", "e664603757251fd8a352848276497a4c79b7f8b21fd8aedd5cc0598a38fee3e4"),
    ("binutils-2.22+mpss3.8.6.tar.bz2", "0e498581badb505bd2639bc1f75debe9299212fb50e8eee5deb40631a78abd9c"),
    ("eglibc_2.19.orig.tar.xz", "e5d30be72b702dffae527779af1be755f0dfbf13c171998a04f7265cd4da131f"),
    ("eglibc_2.19-0ubuntu6.15.debian.tar.xz", "2e0a1d4dfbc8bb666604d6804b9fbd9ce7a1f23b2a5bcb487f5a774d2c557e4c"),
)

def sha256(path):
    digest = hashlib.sha256()
    with open(path, "rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()

def safe_copytree(source, target):
    ignored = shutil.ignore_patterns(".git", "build", "dist", "__pycache__", "*.pyc")
    shutil.copytree(source, target, ignore=ignored)

def extract_member(archive, suffix, destination):
    with tarfile.open(archive, "r:*") as handle:
        member = next((item for item in handle.getmembers() if item.name.endswith(suffix)), None)
        if member is None:
            raise RuntimeError("missing %s in %s" % (suffix, archive))
        source = handle.extractfile(member)
        with open(destination, "wb") as output:
            shutil.copyfileobj(source, output)

def deterministic_tar(source, output):
    root = os.path.dirname(source)
    with tarfile.open(output, "w:xz", preset=6) as archive:
        for current, dirs, files in os.walk(source):
            dirs.sort(); files.sort()
            for name in dirs + files:
                path = os.path.join(current, name)
                info = archive.gettarinfo(path, os.path.relpath(path, root))
                info.uid = info.gid = 0
                info.uname = info.gname = "root"
                info.mtime = 0
                if info.isfile():
                    with open(path, "rb") as handle:
                        archive.addfile(info, handle)
                else:
                    archive.addfile(info)

def component_for(path):
    if path.startswith("./libexec/k1om-mpss-linux-") and not path.endswith("gcc"):
        return "SPDXRef-Binutils"
    if path.startswith("./libexec/gcc/") or path.startswith("./lib/gcc/") or path.startswith("./k1om-mpss-linux/"):
        return "SPDXRef-GCC"
    if path.startswith("./sysroot/lib64/libgcc"):
        return "SPDXRef-Libgcc"
    if path.startswith("./sysroot/"):
        return "SPDXRef-Eglibc"
    return "SPDXRef-XPR"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--toolkit", required=True)
    parser.add_argument("--source-dir", required=True)
    parser.add_argument("--rc6-sources", required=True)
    parser.add_argument("--repo", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--version", default="0.1.0")
    args = parser.parse_args()
    if sha256(args.toolkit) != EXPECTED_TOOLKIT_SHA256:
        raise SystemExit("toolkit hash does not match the validated candidate")
    os.makedirs(args.out)
    stage = os.path.join(args.out, "xpr-k1om-toolkit-%s-sources" % args.version)
    os.makedirs(stage)
    upstream_dir = os.path.join(stage, "upstream")
    os.makedirs(upstream_dir)
    sources = []
    for filename, expected in UPSTREAM:
        source = os.path.join(args.source_dir, filename)
        if sha256(source) != expected:
            raise SystemExit("source hash mismatch: " + filename)
        shutil.copy2(source, os.path.join(upstream_dir, filename))
        sources.append({"file": filename, "sha256": expected})
    solros = os.path.join(upstream_dir, "solros-bda6ce.tar.gz")
    source_solros = os.path.join(args.source_dir, "solros-bda6ce.tar.gz")
    if os.path.isfile(source_solros):
        shutil.copy2(source_solros, solros)
    else:
        extract_member(args.rc6_sources, "/sources/solros-bda6ce.tar.gz", solros)
    sources.append({"file": "solros-bda6ce.tar.gz", "sha256": sha256(solros),
                    "from": "xpr-os-0.1.0-rc6-sources.tar.gz"})
    repo_stage = os.path.join(stage, "repository")
    os.makedirs(repo_stage)
    for item in ("LICENSE", "LICENSES", "tools/toolchain", "tools/release", "examples/k1om",
                 "ubuntu-port/k1om/glibc", "docs/toolchain"):
        source = os.path.join(args.repo, item)
        destination = os.path.join(repo_stage, item)
        os.makedirs(os.path.dirname(destination), exist_ok=True)
        if os.path.isdir(source): safe_copytree(source, destination)
        else: shutil.copy2(source, destination)
    licenses = os.path.join(stage, "LICENSES")
    os.makedirs(licenses)
    shutil.copy2(os.path.join(args.repo, "LICENSE"), os.path.join(licenses, "XPR-MIT.txt"))
    extracted = (
        ("gcc-5.1.1-knc-af7cc04.tar.gz", "/COPYING3", "GPL-3.0-or-later.txt"),
        ("gcc-5.1.1-knc-af7cc04.tar.gz", "/COPYING.RUNTIME", "GCC-Runtime-Library-Exception-3.1.txt"),
        ("binutils-2.22+mpss3.8.6.tar.bz2", "/COPYING", "Binutils-GPL-3.0-or-later.txt"),
        ("eglibc_2.19.orig.tar.xz", "/COPYING.LIB", "Eglibc-LGPL-2.1-or-later.txt"),
        ("gmp-4.3.2.tar.bz2", "/COPYING.LIB", "GMP-LGPL-3.0-or-later.txt"),
        ("mpfr-2.4.2.tar.bz2", "/COPYING.LIB", "MPFR-LGPL-3.0-or-later.txt"),
        ("mpc-0.8.1.tar.gz", "/COPYING.LIB", "MPC-LGPL-3.0-or-later.txt"),
    )
    for archive, suffix, output in extracted:
        extract_member(os.path.join(upstream_dir, archive), suffix, os.path.join(licenses, output))
    notices = """# XPR K1OM Toolkit Third-Party Notices\n\nThis toolkit candidate contains source-built GCC 5.1.1 KNC, KNC binutils 2.22,\nXPR eglibc 2.19, and libgcc. Their complete corresponding source is in the\npaired source archive. GCC is GPL-3.0-or-later; libgcc_s is distributed under\nGPL-3.0-or-later with the GCC Runtime Library Exception 3.1. Binutils is\nGPL-3.0-or-later. eglibc is LGPL-2.1-or-later. GMP, MPFR, and MPC are build\nprerequisites recorded in the source bundle and are not bundled as host or\ntarget runtime binaries.\n\nKNC binutils source is the public MPSS 3.8.6 source archive. It is included\nas source only; no Intel MPSS SDK binary payload is distributed. Engineering\nreview found GPL license texts in that source archive. Qualified legal review\nremains the publication decision boundary.\n"""
    with open(os.path.join(stage, "THIRD-PARTY-NOTICES.md"), "w") as handle: handle.write(notices)
    manifest = {"name": "XPR K1OM Toolkit", "version": args.version,
                "validated_toolkit_sha256": EXPECTED_TOOLKIT_SHA256, "sources": sources,
                "build_entrypoint": "repository/tools/toolchain/build-standalone-xpr-k1om-toolkit.sh",
                "mpss_sdk_binary_payload": 0}
    with open(os.path.join(stage, "SOURCE-MANIFEST.json"), "w") as handle:
        json.dump(manifest, handle, indent=2, sort_keys=True); handle.write("\n")
    with open(os.path.join(stage, "BUILD.md"), "w") as handle:
        handle.write("# Rebuild\n\nRun:\n\n```bash\nbash repository/tools/toolchain/build-standalone-xpr-k1om-toolkit.sh --sources \"$PWD\" --out build\n```\n\nNo MPSS SDK or `/opt/mpss` input is accepted. The host C compiler is only a bootstrap compiler.\n")
    source_archive = os.path.join(args.out, "xpr-k1om-toolkit-%s-sources.tar.xz" % args.version)
    deterministic_tar(stage, source_archive)

    with tempfile.TemporaryDirectory() as temporary:
        with tarfile.open(args.toolkit, "r:xz") as archive: archive.extractall(temporary)
        root = os.path.join(temporary, os.listdir(temporary)[0])
        packages = [
            {"SPDXID":"SPDXRef-XPRToolkit","name":"XPR K1OM Toolkit","versionInfo":args.version,"downloadLocation":"NOASSERTION","licenseConcluded":"MIT","licenseDeclared":"MIT","supplier":"Organization: Xeon Phi Revival Project"},
            {"SPDXID":"SPDXRef-GCC","name":"GCC KNC","versionInfo":"5.1.1","downloadLocation":"git+https://github.com/apc-llc/gcc-5.1.1-knc.git@af7cc04cef723da3166f0d6f1539f02525fe5a93","licenseConcluded":"GPL-3.0-or-later","licenseDeclared":"GPL-3.0-or-later"},
            {"SPDXID":"SPDXRef-Binutils","name":"KNC binutils","versionInfo":"2.22+mpss3.8.6","downloadLocation":"https://archive.org/details/intel-mpss-3.8.6","licenseConcluded":"GPL-3.0-or-later","licenseDeclared":"GPL-3.0-or-later"},
            {"SPDXID":"SPDXRef-Eglibc","name":"eglibc","versionInfo":"2.19-0ubuntu6.15","downloadLocation":"https://launchpad.net/ubuntu/+source/eglibc/2.19-0ubuntu6.15","licenseConcluded":"LGPL-2.1-or-later","licenseDeclared":"LGPL-2.1-or-later"},
            {"SPDXID":"SPDXRef-Libgcc","name":"libgcc","versionInfo":"5.1.1","downloadLocation":"git+https://github.com/apc-llc/gcc-5.1.1-knc.git@af7cc04cef723da3166f0d6f1539f02525fe5a93","licenseConcluded":"GPL-3.0-or-later WITH GCC-exception-3.1","licenseDeclared":"GPL-3.0-or-later WITH GCC-exception-3.1"},
        ]
        files = [{"SPDXID":"SPDXRef-ReleaseArchive","fileName":"./xpr-k1om-toolkit-%s-linux-x86_64.tar.xz" % args.version,"checksums":[{"algorithm":"SHA256","checksumValue":EXPECTED_TOOLKIT_SHA256}],"licenseConcluded":"NOASSERTION","licenseInfoInFiles":["NOASSERTION"],"copyrightText":"NOASSERTION"}]
        relationships, known = [], set(item["SPDXID"] for item in packages)
        known.add("SPDXRef-ReleaseArchive")
        relationships.append({"spdxElementId":"SPDXRef-XPRToolkit","relationshipType":"CONTAINS","relatedSpdxElement":"SPDXRef-ReleaseArchive"})
        counter = 0
        for current, _, names in os.walk(root):
            for name in sorted(names):
                path = os.path.join(current, name)
                relative = "./" + os.path.relpath(path, root).replace(os.sep, "/")
                if os.path.islink(path): continue
                counter += 1; file_id = "SPDXRef-File-%d" % counter
                owner = component_for(relative)
                files.append({"SPDXID":file_id,"fileName":relative,"checksums":[{"algorithm":"SHA256","checksumValue":sha256(path)}],"licenseConcluded":"NOASSERTION","licenseInfoInFiles":["NOASSERTION"],"copyrightText":"NOASSERTION"})
                known.add(file_id); relationships.append({"spdxElementId":owner,"relationshipType":"CONTAINS","relatedSpdxElement":file_id})
        for package in packages[1:]: relationships.append({"spdxElementId":"SPDXRef-XPRToolkit","relationshipType":"CONTAINS","relatedSpdxElement":package["SPDXID"]})
        relationships.insert(0, {"spdxElementId":"SPDXRef-DOCUMENT","relationshipType":"DESCRIBES","relatedSpdxElement":"SPDXRef-XPRToolkit"})
        document = {"spdxVersion":"SPDX-2.3","dataLicense":"CC0-1.0","SPDXID":"SPDXRef-DOCUMENT","name":"XPR-K1OM-Toolkit-%s" % args.version,"documentNamespace":"https://github.com/Xeon-Phi-Revival-Project/xeon-phi-revival/spdx/xpr-k1om-toolkit-%s-%s" % (args.version, EXPECTED_TOOLKIT_SHA256),"creationInfo":{"created":"1970-01-01T00:00:00Z","creators":["Tool: create-standalone-toolkit-release.py"]},"packages":packages,"files":files,"relationships":relationships}
    sbom = os.path.join(args.out, "xpr-k1om-toolkit-%s.spdx.json" % args.version)
    with open(sbom, "w") as handle: json.dump(document, handle, indent=2, sort_keys=True); handle.write("\n")
    assert document["spdxVersion"] == "SPDX-2.3" and all(item["SPDXID"] in known for item in relationships for item in (item["spdxElementId"], item["relatedSpdxElement"]))
    # Ship the notices document with the license texts, not merely alongside it
    # in the corresponding-source archive.
    notices_root = os.path.join(args.out, "xpr-k1om-toolkit-%s-notices" % args.version)
    os.makedirs(notices_root)
    safe_copytree(os.path.join(stage, "LICENSES"), os.path.join(notices_root, "LICENSES"))
    shutil.copy2(os.path.join(stage, "THIRD-PARTY-NOTICES.md"), notices_root)
    notices_archive = os.path.join(args.out, "xpr-k1om-toolkit-%s-notices.tar.xz" % args.version)
    deterministic_tar(notices_root, notices_archive)
    checksums = os.path.join(args.out, "SHA256SUMS")
    with open(checksums, "w") as handle:
        for path in (args.toolkit, source_archive, sbom, notices_archive): handle.write("%s  %s\n" % (sha256(path), os.path.basename(path)))
    print("XPR_TOOLKIT_RELEASE_SIDECARS=PASS")

if __name__ == "__main__": main()
