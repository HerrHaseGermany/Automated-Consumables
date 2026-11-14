## Change log

# Unreleased
- Prepare disabled Retail staging with explicit client-dependent amounts and
  a bag-tooltip reader that respects protected values and item variants.
- Add per-refresh runtime caching, item-load retry/update handling and player
  resource/level refresh events, with combat deferral and isolated staging tests.
- Model explicit health caps and exclude all defenseless sleep recovery from
  ordinary combat potion selection, including Potion of Nightmares.
- Scope TOC support and default source collection to Forever, Era, TBC, Wrath,
  Cataclysm and MoP Classic. Defer Retail while retaining its collected sources.
- Validate Soulstones by their resurrection effect, excluding inert ranks and
  unrelated reputation items; verify the resurrection macro on each client.
- Parse explicit full recovery and bounded Retail percentage food, while
  retaining unresolved zero/missing source values for review.
- Enable separate rebuilt Forever, Classic Era, TBC, Wrath, Cataclysm and MoP
  Classic databases after source collection, legacy comparison and automated
  macro-selection validation. Retail is deferred and has no interface declaration.
- Parse healthstone "life" restoration, remove empty mana gems and inert old
  healthstones, and preserve reviewed level/glyph-dependent family selection.
- Evaluate bounded constant tooltip arithmetic without executing source text;
  reject unknown conditional effects and retain the MoP mana-gem rule source.
- Keep concentration/focus channels out of combat potion selection. Expose
  expertise, armor penetration, dodge, parry and additional food rating aliases.
- Enable Forever Darkspear Islands rations and bandages only in the verified
  battleground instance; reject area/UI-map IDs and other battlegrounds.
- Add a resumable source collection queue for the remaining clients, with live
  status, a log, duplicate-run protection and a queue-wide stop on HTTP 403/429.
  Source collection never activates unfinished client datasets.
- Add a version-specific, reproducible Wowhead import with saved sources,
  candidate catalogs, comparison reports, and guarded activation.
- Recover new Forever food buffs from tooltips when structured fields are empty.
- Separate lasting food regeneration buffs from eating/drinking restoration.
- Offer the supported stats present in the active food database in the existing
  preference dropdowns, with separate labels for crit rating and crit chance.
- Load published client datasets through a generated manifest and skip foreign
  datasets before allocating their tables.
- Handle percentage restoration and rank imported recovery items by effect.
- Separate sleep potions, retain harmful after-effects and enforce battleground
  and instance restrictions; defer location-triggered macro updates in combat.
- Preserve source warnings about uncertain client availability and distinguish
  deployable shared feasts from directly usable food.
- Add supplementary name-based catalog candidates for generic-subclass food
  and recovery items, including battleground rations.
- Exclude explicit unused items and quest orders named after potions.
- Preserve generic-subclass quest foods and potion injectors. Block activation
  if the parser discards a known legacy recovery item.
- Share food selection across the three food macro updates.
- Add a reproducible local preview ZIP containing only published runtime data.
- Add importer tests and a Lua harness covering actual macro selection and
  client data separation. In-game validation is still required.

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
