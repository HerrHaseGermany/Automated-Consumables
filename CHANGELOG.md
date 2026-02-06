## Change log

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
