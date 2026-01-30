# Automated-Consumables
Automatically updates macros for food, drinks and Potions.

Database is not TBC Ready!

Creates/updates three macros (strongest available in your bags):
- `ACFood`: simple food (health-only, no Well Fed)
- `ACDrink`: drink (mana-only)
- `ACBuff`: buff food (Well Fed)
- `ACHealthPotion`: uses a healthstone if available; if the stone is on cooldown, it shows/uses a healing potion instead
- `ACManaPotion`: best available mana potion
- `ACBandage`: best available bandage (targets yourself)

Notes:
- This addon manages `ACFood`, `ACDrink`, `ACBuff`, `ACHealthPotion`, `ACManaPotion`, and `ACBandage`.
- Optional database: you can add known itemIDs in `FoodDrinkDB.lua` to force-categorize items (drink/food/bufffood).
- Food/drink items are detected via item IDs + item class info; on Classic Era some Food/Drink items report as generic Consumable, so the addon also uses the built-in localized “must remain seated” tooltip string to identify food/drink (and avoid misclassifying potions).
- “Best” is determined by scanning your bags and reading restore amounts from tooltips using localized HEALTH/MANA strings; if amounts can’t be determined, it falls back to “any usable Food & Drink” so macros still get populated.
- Items must be usable; unusable items are ignored.

Debug:
- Run `/acdebug` in-game to toggle debug prints (shows what item IDs were detected for each macro update).
- Run `/acupdate` to force a rebuild/update, and `/acshow` to print the current macro bodies.
