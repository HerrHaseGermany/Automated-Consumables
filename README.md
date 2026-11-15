# Automated-Consumables 2.0.0
Automatically updates macros for food, drinks and Potions.

Creates/updates seven macros (best available in your bags):
- `ACFood`: simple food (health-only, no Well Fed)
- `ACDrink`: drink (mana-only)
- `ACBuff`: buff food (Well Fed)
- `ACHealthPotion`: uses a healthstone if available; if the stone is on cooldown, it shows/uses a healing potion instead
- `ACManaPotion`: best available mana potion
- `ACBandage`: best available bandage (targets yourself)
- `ACSoulstone`: best available soulstone

Database update (2.0.0):
- Forever, Classic Era, TBC, Wrath, Cataclysm, MoP Classic, and Retail use separate
  generated consumable datasets. The existing candidate catalog was checked
  separately for each supported client.
- Coverage is the known catalog, not a guarantee that every undiscovered or
  future item is included. Explicit source "not found" responses are reported.
- Retail uses readable bag-item tooltips for missing or scaled amounts, with
  item-cache retries, protected-value checks and character-resource updates.
  Unreadable/ambiguous required values are skipped instead of guessed.
- Generic-subclass candidates include battleground rations and recovery items.
  Shared feasts are kept separate from food that directly restores resources.
- Percentage restoration uses the player's maximum health/mana. Imported
  potions, stones and bandages are ranked by restoration instead of item ID.
- Buff priority dropdowns include supported stats present in the current data,
  including expertise, armor penetration, dodge, parry, haste and regeneration. Saved preference keys are preserved.
- Healthstones using "life" are ranked by their actual health values. Cata/MoP
  healthstones with level/glyph-dependent effects retain family selection
  without inventing numeric healing; empty mana gems are excluded.
- Dreamless Sleep potions are not substituted for combat potions. Potions with
  a harmful after-effect remain available but rank after ordinary healing
  potions. Battleground and instance restrictions are checked for the current
  location; macro updates wait until combat ends when necessary.

Notes:
- This addon manages `ACFood`, `ACDrink`, `ACBuff`, `ACHealthPotion`, `ACManaPotion`, `ACBandage`, and `ACSoulstone`.
- Optional database: you can add known itemIDs in `FoodDrinkDB.lua` to force-categorize items (drink/food/bufffood).
- Food/drink items are detected via item IDs + item class info; on Classic Era some Food/Drink items report as generic Consumable, so the addon also uses the built-in localized “must remain seated” tooltip string to identify food/drink (and avoid misclassifying potions).
- “Best” is determined by scanning your bags and reading restore amounts from tooltips using localized HEALTH/MANA strings; if amounts can’t be determined, it falls back to “any usable Food & Drink” so macros still get populated.
- Items must be usable; unusable items are ignored.

Debug:
- Run `/acdebug` in-game to toggle debug prints (shows what item IDs were detected for each macro update).
- Run `/acupdate` to force a rebuild/update, and `/acshow` to print the current macro bodies.

Build the release package:

```sh
python3 tools/package_addon.py
```

This creates `dist/Automated-Consumables-2.0.0.zip` with the runtime files and
published databases. In-game validation with the full addon setup is pending.

Installation: extract the release ZIP's `Automated-Consumables` folder into the
client's `Interface/AddOns` directory, replacing the previous addon files.
Existing `ACSettings` preferences are preserved. Source snapshots, reports,
tests and build tools belong to the repository and are excluded from the ZIP.

Retail is declared for Interface 120105 (12.1.5), matching the reviewed UI source
build. Full in-game verification with the complete addon setup remains pending.
