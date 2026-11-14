#!/usr/bin/env python3
"""Create an unreleased test ZIP from the TOC and published runtime resources."""

import argparse
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ADDON = "Automated-Consumables"


def resources():
    files = set()

    def include(path):
        if path.is_symlink():
            raise ValueError(f"Package resources must be regular files: {path}")
        path = path.resolve()
        path.relative_to(ROOT)
        if not path.is_file():
            raise ValueError(f"Missing runtime resource: {path}")
        if path in files:
            return
        files.add(path)
        if path.suffix.lower() == ".xml":
            for element in ET.parse(path).iter():
                if element.tag.rsplit("}", 1)[-1] in ("Script", "Include") and element.get("file"):
                    include(path.parent / element.get("file").replace("\\", "/"))

    toc = ROOT / (ADDON + ".toc")
    include(toc)
    for line in toc.read_text().splitlines():
        line = line.strip()
        if line and not line.startswith("#"):
            include(ROOT / line.replace("\\", "/"))
    for name in ("LICENSE", "README.md", "CHANGELOG.md"):
        include(ROOT / name)
    for path in (ROOT / "Media").rglob("*"):
        if path.is_file() and path.name != ".DS_Store":
            include(path)
    return sorted(files)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=ROOT / "dist" / (ADDON + "-preview.zip"))
    args = parser.parse_args()
    files = resources()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    temporary = args.output.with_suffix(".zip.tmp")
    with zipfile.ZipFile(temporary, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            name = ADDON + "/" + path.relative_to(ROOT).as_posix()
            # Stable timestamps and permissions make identical inputs produce
            # identical archives, independent of the checkout's file mtimes.
            info = zipfile.ZipInfo(name, date_time=(2020, 1, 1, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, path.read_bytes())
    temporary.replace(args.output)
    print(f"Created {args.output} ({len(files)} files, {args.output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
