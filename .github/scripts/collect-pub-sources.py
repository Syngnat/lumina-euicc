#!/usr/bin/env python3

"""Collect exact hosted Pub package sources referenced by package_config.json."""

from __future__ import annotations

import argparse
import json
import re
import shutil
import sys
from pathlib import Path
from urllib.parse import unquote, urljoin, urlparse
from urllib.request import url2pathname


def parse_lockfile(path: Path) -> dict[str, dict[str, str]]:
    packages: dict[str, dict[str, str]] = {}
    current: str | None = None
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        package_match = re.match(r"^  ([A-Za-z0-9_+.-]+):\s*$", raw_line)
        if package_match:
            current = package_match.group(1)
            packages[current] = {}
            continue
        if current is None:
            continue
        field_match = re.match(
            r'^    (source|version):\s*["\']?([^"\']+?)["\']?\s*$', raw_line
        )
        if field_match:
            packages[current][field_match.group(1)] = field_match.group(2)
            continue
        sha_match = re.match(r'^      sha256:\s*["\']?([0-9a-fA-F]+)', raw_line)
        if sha_match:
            packages[current]["sha256"] = sha_match.group(1).lower()
    return packages


def file_uri_to_path(uri: str) -> Path:
    parsed = urlparse(uri)
    if parsed.scheme != "file":
        raise ValueError(f"unsupported package root URI: {uri}")
    path = url2pathname(unquote(parsed.path))
    if parsed.netloc:
        path = f"//{parsed.netloc}{path}"
    return Path(path).resolve()


def pubspec_value(pubspec: Path, field: str) -> str:
    match = re.search(
        rf'^\s*{re.escape(field)}:\s*["\']?([^"\'#\r\n]+?)["\']?\s*$',
        pubspec.read_text(encoding="utf-8"),
        flags=re.MULTILINE,
    )
    return match.group(1).strip() if match else ""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("package_config", type=Path)
    parser.add_argument("pubspec_lock", type=Path)
    parser.add_argument("output_directory", type=Path)
    args = parser.parse_args()

    if args.output_directory.exists():
        raise SystemExit(
            f"refusing to overwrite dependency source output: {args.output_directory}"
        )

    config = json.loads(args.package_config.read_text(encoding="utf-8"))
    locked = parse_lockfile(args.pubspec_lock)
    config_uri = args.package_config.resolve().as_uri()
    collected: list[tuple[str, str, str, str, str]] = []

    packages_output = args.output_directory / "packages"
    packages_output.mkdir(parents=True)

    for package in sorted(config["packages"], key=lambda item: item["name"]):
        name = package["name"]
        root_uri = urljoin(config_uri, package["rootUri"])
        root = file_uri_to_path(root_uri)
        if "hosted" not in {part.lower() for part in root.parts}:
            continue

        lock = locked.get(name)
        if lock is None or lock.get("source") != "hosted":
            raise SystemExit(f"hosted package is not represented in pubspec.lock: {name}")
        version = lock.get("version", "")
        if not version:
            raise SystemExit(f"hosted package has no locked version: {name}")
        if not root.is_dir():
            raise SystemExit(f"hosted package source directory is missing: {root}")

        pubspec = root / "pubspec.yaml"
        declared_version = pubspec_value(pubspec, "version")
        if declared_version and declared_version != version:
            raise SystemExit(
                f"package cache version mismatch for {name}: "
                f"lock={version}, source={declared_version}"
            )

        destination_name = f"{name}-{version}"
        if not re.fullmatch(r"[A-Za-z0-9_.+-]+", destination_name):
            raise SystemExit(f"unsafe hosted package destination: {destination_name}")
        shutil.copytree(root, packages_output / destination_name, symlinks=True)

        upstream = pubspec_value(pubspec, "repository") or pubspec_value(
            pubspec, "homepage"
        )
        package_url = f"https://pub.dev/packages/{name}/versions/{version}"
        collected.append(
            (name, version, lock.get("sha256", "missing"), package_url, upstream)
        )

    if not collected:
        raise SystemExit("no hosted Pub package sources were collected")

    collected_names = {row[0] for row in collected}
    locked_hosted_names = {
        name for name, metadata in locked.items() if metadata.get("source") == "hosted"
    }
    if collected_names != locked_hosted_names:
        missing = sorted(locked_hosted_names - collected_names)
        unexpected = sorted(collected_names - locked_hosted_names)
        raise SystemExit(
            "hosted Pub source set does not match pubspec.lock; "
            f"missing={missing}, unexpected={unexpected}"
        )

    manifest = args.output_directory / "PUB_SOURCE_MANIFEST.tsv"
    with manifest.open("w", encoding="utf-8", newline="\n") as stream:
        stream.write("package\tversion\tpub_archive_sha256\tpackage_url\tupstream\n")
        for row in collected:
            stream.write("\t".join(value.replace("\t", " ") for value in row) + "\n")

    print(f"Collected {len(collected)} hosted Pub package source trees.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
