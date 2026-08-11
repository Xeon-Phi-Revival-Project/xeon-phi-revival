#!/usr/bin/env python3
"""Capture normalized source/header dependencies from Kbuild .cmd files."""

import argparse
import hashlib
import json
import re
from pathlib import Path


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def evidence(path: Path) -> dict:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()[:100]
    copyright_lines = sorted({line.strip(" /*\t") for line in lines if "copyright" in line.lower()})
    license_lines = sorted({
        line.strip(" /*\t")
        for line in lines
        if "general public license" in line.lower()
        or "spdx-license-identifier" in line.lower()
    })
    return {
        "path": path.as_posix(),
        "sha256": sha256(path),
        "copyright_evidence": copyright_lines,
        "license_evidence": license_lines,
        "classification": "GPL-2.0-only" if any("version 2" in line.lower() for line in license_lines) else "REVIEW_REQUIRED",
    }


def normalize(path_text: str, module_root: str, kernel_source: str, kernel_build: str) -> tuple[str, str]:
    path_text = path_text.replace("\\ ", " ").strip()
    if not path_text.startswith("/"):
        return "kernel-generated", path_text
    for category, root in (
        ("module-source", module_root),
        ("kernel-source", kernel_source),
        ("kernel-generated", kernel_build),
    ):
        root = root.rstrip("/")
        if path_text == root or path_text.startswith(root + "/"):
            return category, path_text[len(root):].lstrip("/")
    return "toolchain-or-host", path_text


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--module-source", required=True, type=Path)
    parser.add_argument("--kernel-source", required=True)
    parser.add_argument("--kernel-build", required=True)
    parser.add_argument("--recorded-module-root")
    parser.add_argument("--source-map", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    args = parser.parse_args()

    module_root = args.module_source.resolve()
    recorded_module_root = args.recorded_module_root or module_root.as_posix()
    source_map = json.loads(args.source_map.read_text(encoding="utf-8"))

    dependency_use: dict[str, dict[str, set[str]]] = {
        key: {} for key in ("module-source", "kernel-source", "kernel-generated", "toolchain-or-host")
    }
    modules = []
    owned_paths: set[Path] = set()

    for module in source_map["modules"]:
        module_id = module["id"]
        cmd_files = []
        for source_rel in module["implementation_sources"]:
            source_path = module_root / source_rel
            if not source_path.is_file():
                raise SystemExit(f"missing implementation source: {source_path}")
            owned_paths.add(source_path)
            cmd_path = source_path.with_name(f".{source_path.stem}.o.cmd")
            if not cmd_path.is_file():
                raise SystemExit(f"missing clean-build dependency file: {cmd_path}")
            cmd_files.append(cmd_path.relative_to(module_root).as_posix())
            text = cmd_path.read_text(encoding="utf-8", errors="replace").replace("\\\n", " ")
            candidates = re.findall(r"(?:/[^\s\\]+|(?:include|arch)/[^\s\\$()]+)\.h", text)
            candidates += re.findall(r"\$\(wildcard\s+([^\)]+\.h)\)", text)
            for candidate in candidates:
                category, normalized = normalize(
                    candidate,
                    recorded_module_root,
                    args.kernel_source,
                    args.kernel_build,
                )
                dependency_use[category].setdefault(normalized, set()).add(module_id)
                if category == "module-source":
                    owned_path = module_root / normalized
                    if owned_path.is_file():
                        owned_paths.add(owned_path)
        modules.append({
            "id": module_id,
            "output": module["output"],
            "tested_sha256": module["sha256"],
            "implementation_sources": module["implementation_sources"],
            "dependency_files": sorted(cmd_files),
        })

    owned_evidence = []
    ambiguous = []
    for path in sorted(owned_paths):
        item = evidence(path)
        item["path"] = path.relative_to(module_root).as_posix()
        owned_evidence.append(item)
        if item["classification"] == "REVIEW_REQUIRED":
            ambiguous.append(item["path"])

    dependencies = {}
    for category, entries in dependency_use.items():
        dependencies[category] = [
            {"path": path, "used_by": sorted(module_ids)}
            for path, module_ids in sorted(entries.items())
        ]

    output = {
        "schema": "xpr-mpss-module-clean-dependencies-v1",
        "status": "complete" if not ambiguous else "human-review-required",
        "source_archive": source_map["source_archive"],
        "kernel_build_dependency": source_map["kernel_build_dependency"],
        "capture": {
            "module_source": "$MODULE_SOURCE",
            "kernel_source": "$KERNEL_SOURCE",
            "kernel_build": "$KERNEL_BUILD",
            "dependency_format": "Linux Kbuild generated .cmd files from the clean tested module build",
        },
        "modules": modules,
        "dependencies": dependencies,
        "module_owned_file_evidence": owned_evidence,
        "ambiguous_module_owned_files": ambiguous,
        "corresponding_source_boundary": "Ship the complete hash-pinned module source archive. Kernel-source and kernel-generated dependencies are supplied by the separately mapped kernel corresponding source/build tree; toolchain headers are build prerequisites.",
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(output, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"modules={len(modules)}")
    print(f"module_owned_files={len(owned_evidence)}")
    for category, entries in dependencies.items():
        print(f"{category}={len(entries)}")
    print(f"ambiguous_module_owned_files={len(ambiguous)}")
    print(f"status={output['status']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
