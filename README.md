# Automated-Consumables
Automatically updates macros for food and drinks (Classic Era).

Creates/updates three macros (strongest available in your bags):
- `ACbutton1`: simple food (health-only, no Well Fed)
- `ACbutton2`: drink (mana-only)
- `ACbutton3`: buff food (Well Fed)

Notes:
- This addon only manages `ACbutton1`, `ACbutton2`, and `ACbutton3`.
- Optional database: you can add known itemIDs in `FoodDrinkDB.lua` to force-categorize items (drink/food/bufffood).
- Food/drink items are detected via item IDs + item class info; on Classic Era some Food/Drink items report as generic Consumable, so the addon also uses the built-in localized “must remain seated” tooltip string to identify food/drink (and avoid misclassifying potions).
- “Best” is determined by scanning your bags and reading restore amounts from tooltips using localized HEALTH/MANA strings; if amounts can’t be determined, it falls back to “any usable Food & Drink” so macros still get populated.
- Items must be usable; unusable items are ignored.

Debug:
- Run `/acdebug` in-game to toggle debug prints (shows what item IDs were detected for each macro update).
- Run `/acupdate` to force a rebuild/update, and `/acshow` to print the current macro bodies.
