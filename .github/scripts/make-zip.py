#!/usr/bin/env python3

"""Create a ZIP recursively, including dotfiles and preserving Unix modes."""

from __future__ import annotations

import argparse
import os
import sys
import time
import zipfile
from pathlib import Path


def zip_info(path: Path, archive_name: str) -> zipfile.ZipInfo:
    metadata = path.lstat()
    timestamp = tuple(time.localtime(metadata.st_mtime)[:6])
    if timestamp[0] < 1980:
        timestamp = (1980, 1, 1, 0, 0, 0)
    info = zipfile.ZipInfo(archive_name, timestamp)
    info.create_system = 3
    info.external_attr = (metadata.st_mode & 0xFFFF) << 16
    return info


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("output_zip", type=Path)
    parser.add_argument("base_directory", type=Path)
    parser.add_argument("archive_root")
    args = parser.parse_args()

    output = args.output_zip.resolve()
    base = args.base_directory.resolve()
    root = (base / args.archive_root).resolve()
    if output.exists():
        raise SystemExit(f"refusing to overwrite ZIP: {output}")
    if not root.is_dir() or root.parent != base:
        raise SystemExit(f"archive root must be one direct child of {base}: {root}")

    with zipfile.ZipFile(
        output, "x", compression=zipfile.ZIP_DEFLATED, compresslevel=9
    ) as archive:
        for directory, directory_names, file_names in os.walk(
            root, topdown=True, followlinks=False
        ):
            directory_names.sort()
            file_names.sort()
            current = Path(directory)
            relative_directory = current.relative_to(base).as_posix()
            archive.writestr(zip_info(current, f"{relative_directory}/"), b"")

            for name in directory_names:
                candidate = current / name
                if candidate.is_symlink():
                    relative = candidate.relative_to(base).as_posix()
                    archive.writestr(
                        zip_info(candidate, relative), os.readlink(candidate).encode()
                    )

            for name in file_names:
                candidate = current / name
                relative = candidate.relative_to(base).as_posix()
                if candidate.is_symlink():
                    archive.writestr(
                        zip_info(candidate, relative), os.readlink(candidate).encode()
                    )
                    continue
                archive.write(candidate, relative)

    print(f"Created {output}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
