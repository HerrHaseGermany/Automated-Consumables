#!/usr/bin/env python3
"""Extract candidate IDs from a released ItemDB archive, never its values.

Download source: https://www.curseforge.com/wow/addons/libitemdb/files/9580874
This script reads text without executing any third-party Lua.
"""

import argparse
import hashlib
import json
import re
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
FOLDERS = {"forever": "Forever", "era": "Vanilla", "tbc": "TBC",
           "wrath": "Wrath", "cata": "Cata", "mop": "Mists", "retail": "Retail"}
FAMILIES = re.compile(r"healthstone|soulstone|\bmana (?:agate|jade|citrine|ruby|emerald|sapphire|gem)\b", re.I)
RECOVERY_NAMES = re.compile(
    r"\b(?:potions?|bandages?|injectors?|draughts?|salves?|rations?|bread|water|milk|"
    r"soup|stew|meat|fish|salmon|trout|cake|cookie|apple|cheese|pie|juice|tea|"
    r"dumpling|sausage|steak|ham|egg|berry|berries|fruit|muffin|biscuit|"
    r"chocolate|candy|cider|nectar|broth|feast|brew)\b", re.I)


def generic_candidate_ids(core, names, primary):
    """Find extra name-based candidates without treating names as effect data."""
    rows = {int(item_id): record for item_id, record in
            re.findall(r'^\[(\d+)\]="([^"\r\n]+)"', core, re.M)}
    selected = set()
    for item_id, name in re.findall(r'^\[(\d+)\]="((?:[^"\\]|\\.)*)"', names, re.M):
        item_id = int(item_id)
        if item_id in primary or item_id not in rows:
            continue
        if rows[item_id].split(r"\031")[1] in ("0", "8") and RECOVERY_NAMES.search(name):
            selected.add(item_id)
    return sorted(selected)


def candidate_ids(core, names):
    rows = dict((int(item_id), record) for item_id, record in
                re.findall(r'^\[(\d+)\]="([^"\r\n]+)"', core, re.M))
    if not rows:
        raise ValueError("No consumable records found in the archive")
    selected = set()
    subclasses = set()
    for item_id, record in rows.items():
        fields = record.split(r"\031")
        if len(fields) < 4:
            raise ValueError(f"Unknown ItemDB encoding for {item_id}")
        subclasses.add(fields[1])
        if fields[1] in ("1", "5", "7"):
            selected.add(item_id)
    # Classic Era files every consumable under generic subclass 0. Filtering
    # that schema by modern subtype numbers would silently drop all food.
    if subclasses == {"0"}:
        selected.update(rows)
    for item_id, name in re.findall(r'^\[(\d+)\]="((?:[^"\\]|\\.)*)"', names, re.M):
        item_id = int(item_id)
        if item_id in rows and FAMILIES.search(name):
            selected.add(item_id)
    if not selected:
        raise ValueError("No candidate IDs found")
    return sorted(selected)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    parser.add_argument("--release-url", required=True, help="Human-readable release page for provenance")
    args = parser.parse_args()
    archive_hash = hashlib.sha256(args.archive.read_bytes()).hexdigest()
    pending = {}
    with zipfile.ZipFile(args.archive) as archive:
        for version, folder in FOLDERS.items():
            core_path = f"ItemDB/Data/{folder}/_core/Consumable.lua"
            names_path = f"ItemDB/Data/{folder}/enUS/Names.lua"
            core, names = archive.read(core_path), archive.read(names_path)
            ids = candidate_ids(core.decode(), names.decode())
            pending[version] = {
                "source": {"provider": "LibItemDB", "release": args.release_url,
                           "license": "MIT", "archiveSha256": archive_hash,
                           "core": core_path, "coreSha256": hashlib.sha256(core).hexdigest(),
                           "names": names_path, "namesSha256": hashlib.sha256(names).hexdigest(),
                           "scope": "Candidate IDs only; values must be fetched from this client's Wowhead export. Core data only; no seasonal data is mixed into Era.",
                           "coverage": "Food/drink, potion and bandage entries, plus named stone and mana-gem families. When the source has only generic subclass 0, the entire consumable core is included. Not proof of complete game coverage."},
                "ids": ids,
            }
            extra = generic_candidate_ids(core.decode(), names.decode(), set(ids))
            if extra:
                provenance = dict(pending[version]["source"])
                # A name is only a lead: the source may legitimately report
                # unavailable or unrelated items. Keep the strict primary
                # catalog gate separate from this supplementary search.
                provenance["candidateCore"] = provenance.pop("core")
                provenance["coverage"] = "Supplementary name-based candidates in generic subclasses 0/8; not an existence or completeness claim. Effects and eligibility come only from the client-specific source."
                pending[version + "-generic"] = {"source": provenance, "ids": extra}
    # Validate every flavor before replacing any seed file.
    for version, value in pending.items():
        path = ROOT / "data/seeds" / (version + ".json")
        path.parent.mkdir(parents=True, exist_ok=True)
        temporary = path.with_suffix(".json.tmp")
        temporary.write_text(json.dumps(value, indent=2, sort_keys=True) + "\n")
        temporary.replace(path)
        print(f"{version}: {len(value['ids'])} candidate IDs")


if __name__ == "__main__":
    main()
