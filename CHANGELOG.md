## Change log

# 2.0.0 — 2026-11-14
- Enable separate, regenerated Wowhead databases for Forever, Classic Era,
  TBC, Wrath, Cataclysm, MoP Classic, and Retail. Preserve source snapshots,
  candidate provenance, coverage reports and legacy comparisons.
- Add Retail bag-tooltip resolution for missing/scaled amounts, protected-value
  handling, per-refresh caching and item-data/character update events.
- Rank recovery items by restoration, including percentages and health caps;
  prefer ordinary potions over harmful alternatives and exclude sleep channels.
- Enforce known battleground/instance/level/outdoor restrictions. Keep items
  with unmapped location rules out of automatic selection.
- Expand food-stat priorities, distinguish crit chance from rating, and separate
  lasting regeneration buffs from direct food/drink restoration.
- Preserve generic quest food, identify Soulstones by resurrection effects,
  and exclude empty gems, inert ranks and unrelated reputation items.
- Defer macro changes in combat and share food scans across macro updates.
- Add reproducible versioned release packaging and automated importer/runtime
  checks. Development caches and staging outputs stay out of release packages.

Known limits: coverage is the documented candidate catalog, not every possible
item. Retail retains 175 entries requiring readable client tooltip values;
68 unmapped location restrictions remain excluded. Automated checks passed,
but full in-game validation across all seven clients is still pending.

# 1.3.5
- add missing items to database
- add soulstone macro

# 1.3.4
- add missing item to database

# 1.3.3
- add missing item to database

# 1.3.2
- Skip consumables that require a higher level than the player

# 1.3.1
- revert changes from 1.3

# 1.3
- Macro creation now prefers character macros first and falls back to account macros only if the character macro list is full.

# 1.2
- minor fix

# 1.1.9
- license update
- minor fix

# 1.1.8
- minor fix

# 1.1.7
- Add Logo
- fix Minimap Button in TBC
- Add message when a macro updates (e.g., "ACFood Macro has been updated to Grilled Squid")
- extended Databate to TBC
- Refresh macros when `PLAYER_ALIVE` fires so they reflect new consumables after resurrection

# 1.1.6
- Add Mana Agate to Mana Potion macro with Healthstone-style cooldown fallback to mana potions

# 1.1.5
- Fix: Food/Drink/Buff macros no longer clear while swimming (don’t filter food/drink selection by `IsUsableItem` during macro rebuilds)

# 1.1.4
- minior fix

# 1.1.3
- Improve initial food/drink selection by caching tooltip-derived restore values by itemID
- Switch food/drink/buff selection to DB-driven values

# 1.1.2
- Removed Fallback
- Add option to prefer a specific stat bufffood
- minor fixes
- Refresh macros when hovering macro buttons in the addon UI (throttled)
- Refresh macros on every successful cast while out of combat (throttled)

# 1.1.1
- corrected interface version

# 1.1
- Add Database for Health Potions, Mana Potions and Bandages
- Add macros for Health Potions, Mana Potions and Bandages
- Add Healthstones (including improved variants) and prefer them over potions
- Add Healthstone cooldown fallback to use potions
- Add minimap button opening macro window (drag & drop)
- Fix minimap button styling to match standard minimap buttons
- Fix panel style
- Add tooltips
- Add Options Menu with Minimap Button toggle

# 1.0
- Inital Version
