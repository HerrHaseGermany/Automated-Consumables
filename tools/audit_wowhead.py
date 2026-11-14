#!/usr/bin/env python3
"""Compare a staged Wowhead dataset to the currently shipped Lua database."""

import argparse
import importlib.util
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location("import_wowhead", ROOT / "tools/import_wowhead.py")
importer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(importer)

LUA_EXPORT = r'''
dofile("FoodDrinkDB.lua")
dofile("PotionBandageDB.lua")
local function emit(id, kind, h, m, bs)
    local stats = {}
    for key, value in pairs(bs or {}) do
        stats[#stats + 1] = key .. "=" .. tostring(value)
    end
    table.sort(stats)
    print(string.format("%d\t%s\t%.12g\t%.12g\t%s", id, kind, h or 0, m or 0, table.concat(stats, ";")))
end
for id, stats in pairs(AC_FOODDRINK_ITEM_STATS) do
    emit(id, stats.kind, stats.h, stats.m, stats.bs)
end
local families = {
    healthpotion=AC_HEALTH_POTION_ITEM_IDS, manapotion=AC_MANA_POTION_ITEM_IDS,
    healthstone=AC_HEALTHSTONE_ITEM_IDS, managem=AC_MANAAGATE_ITEM_IDS,
    bandage=AC_BANDAGE_ITEM_IDS, soulstone=AC_SOULSTONE_ITEM_IDS,
}
for kind, ids in pairs(families) do
    for id in pairs(ids) do emit(id, kind) end
end
'''


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("version", choices=importer.VERSIONS)
    args = parser.parse_args()
    result = subprocess.run(["lua", "-"], input=LUA_EXPORT, text=True,
                            capture_output=True, check=True, cwd=ROOT)
    legacy = {}
    for line in result.stdout.splitlines():
        item_id, kind, h, m, stats = line.split("\t")
        bs = {}
        for key, value in (part.split("=") for part in stats.split(";") if part):
            try:
                bs[key] = float(value)
            except ValueError:
                bs[key] = value
        legacy[int(item_id)] = {"kind": kind, "h": float(h), "m": float(m), "bs": bs}
    snapshot = json.loads((ROOT / "data/sources" / (args.version + ".json")).read_text())
    changes, additions, fetched_ids = [], [], set()
    for raw in snapshot["items"]:
        fetched_ids.add(raw["id"])
        record, issues = importer.normalize(raw, args.version)
        old = legacy.get(raw["id"])
        if issues:
            continue
        if not old:
            if record:
                additions.append({"id": raw["id"], "name": raw["name"], "kind": record["kind"]})
            continue
        if record is None:
            changes.append({"id": raw["id"], "name": raw["name"], "legacy": old,
                            "wowhead": None, "note": "Source does not classify this item as a supported consumable"})
            continue
        new = {key: record[key] for key in ("kind", "h", "m")}
        new["bs"] = record.get("bs", {})
        if record.get("runtimeRestorationRequired"):
            new["amountSource"] = "current-client-required; zero fields are placeholders"
        elif record.get("runtimeRestorationPreferred"):
            new["amountSource"] = "current-client-preferred; exported values are fallback only"
        # The old potion/stone/bandage sets contain no amounts to compare.
        compare = ("kind", "h", "m", "bs") if old["kind"] in ("food", "drink", "both", "buff") else ("kind",)
        if any(old[key] != new[key] for key in compare):
            changes.append({"id": raw["id"], "name": raw["name"], "legacy": old, "wowhead": new})
    report = {"version": args.version, "note": "Differences include intentional client-specific changes; they are not all manual-entry errors.",
              "changes": sorted(changes, key=lambda row: row["id"]),
              "additions": sorted(additions, key=lambda row: row["id"]),
              "legacyNotFetched": sorted(set(legacy) - fetched_ids)}
    importer.write_json(ROOT / "data/reports" / (args.version + "-legacy-audit.json"), report)
    print(f"{len(changes)} differences, {len(additions)} additions; {len(report['legacyNotFetched'])} legacy IDs not fetched")


if __name__ == "__main__":
    main()
