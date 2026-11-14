# Version-specific consumable databases

Version 2.0.0 uses reproducible, version-specific source imports for Forever,
Classic Era, TBC, Wrath, Cataclysm, MoP Classic, and Retail. Each source profile
and dataset is separate; declarations and automated tests do not establish
full in-game compatibility.

## Current status

The reviewed known-catalog datasets for Forever, Classic Era, TBC, Wrath, Cataclysm,
MoP Classic, and Retail are loaded through `Databases.xml`. `Database.lua` defines the adapter and
`DatabaseInit.lua` activates only the actual client's dataset. Foreign-client
Lua files return before constructing their tables. Other clients keep the
existing `FoodDrinkDB.lua` and `PotionBandageDB.lua` until their imports are ready.

| Client | Catalog IDs | Unique candidates | Source records | Explicitly unavailable | Normalized records |
| --- | ---: | ---: | ---: | ---: | ---: |
| Forever | 480 | 713 | 557 | 156 | 405 |
| Classic Era | 991 | 1146 | 992 | 154 | 316 |
| TBC | 507 | 623 | 623 | 0 | 475 |
| Wrath | 710 | 817 | 817 | 0 | 624 |
| Cataclysm | 914 | 1031 | 1031 | 0 | 761 |
| MoP Classic | 1137 | 1269 | 1269 | 0 | 935 |
| Retail | 2930 | 3241 | 3241 | 0 | 2050 |

All 418 legacy IDs were checked independently for each client. These snapshots
have no fetch failures, unparsed restoration effects, or discarded legacy
recovery items. Foods whose numeric buff values are missing in the source are
reported without invented values. Forever also has two zone-conditional movement
buff warnings; those buffs are not offered as unconditional stat preferences.
The expanded Forever snapshot also reports five source disclaimers about
uncertain availability. Six Darkspear rations and bandages are restricted to
Forever battleground instance 2997 (not area ID 16606 or UI map ID 2524).
The mapping is independently corroborated by
[Questie](https://github.com/Questie/Questie/blob/master/docs/forever-development.md)
and the [DenoMap Map.db2 pipeline](https://github.com/DenoHearth/DenoMap/blob/b915e4ae8ac6bf3c8a5679d2dbf6cc468c2cd824/DenoMap/tools/mjobs.py).
Their macros use ordinary items in other locations and wait until combat ends
before applying a location change. In-game validation is still pending. One deployable feast is retained separately from direct recovery food. The 713 Forever
candidates include 74 supplementary name-based IDs, with overlap against
the legacy candidates. The TBC expansion checks 95 supplementary IDs,
including overlaps. Four Blade's Edge consumables have unresolved outdoor
restrictions and are excluded from automatic selection. Explicitly unused
items and quest orders named after potions are excluded during normalization.

`staged/` contains new import results. Fetching never overwrites the enabled
runtime data. `published/` preserves the reviewed source snapshot used to
generate each enabled dataset. Known-catalog coverage is not proof that all
undiscovered or future game items are covered. In-game validation is pending.

Successfully fetched records are saved in `sources/<version>.json`. The first
Forever attempt encountered repeated HTTP 403 responses; later attempts resume
from the saved snapshot and HTTP cache. A denied request stops further network
access while still preserving later cached records. An explicit source
"Item not found!" response is recorded separately under `unavailable`, never
silently replaced with another client's item.

`seeds/<version>.json` contains candidate IDs discovered from LibItemDB v1.9.0.
Each flavor is extracted independently, with release and archive/file hashes.
Era's generic consumable subclass cannot be filtered like the modern clients:
the whole Era consumable core is included to avoid dropping its food. Seasonal
rows are not mixed into Era. `seeds/legacy.json` separately preserves all IDs
from the shipped hand-maintained databases, so their values can also be fetched
anew. These seeds are not proof of an exhaustive game catalog. Additional `*-generic.json` seeds search generic subclasses for recovery and
food names. Names supply candidate IDs only; a candidate can turn out to be an
unrelated quest item or unavailable in the requested client. This search is
heuristic and is not proof that the generic subclasses are fully covered.
Source XML
supplies the imported names, requirements, restoration, and buff data.

## Import and rebuild

Run from the repository root with Python 3.9 or later:

Offline `--rebuild` uses committed snapshots and needs no network configuration.
For new network imports, set `AC_DATABASE_SOURCE_URL` to a compatible XML
catalog base URL. The configured catalog must provide the profile paths in
`VERSIONS`, `item=<id>&xml` exports and consumable category lists. The importer
validates returned client/item links against that base URL. No default provider
is configured. Fixture tests use the reserved `catalog.example` domain.

```sh
# Discover candidate IDs from this client's source category lists.
python3 tools/import_database.py forever

# Alternatively, fetch a documented partial set of candidate IDs.
python3 tools/import_database.py forever --seed data/seeds/forever.json --seed data/seeds/legacy.json --seed data/seeds/forever-generic.json

# Try the client's category lists as well as the candidate seeds.
python3 tools/import_database.py forever --seed data/seeds/forever.json --discover

# Rebuild staging and any published runtime dataset offline.
python3 tools/import_database.py forever --rebuild

# Explicitly refresh source responses instead of reusing cached XML.
python3 tools/import_database.py forever --seed data/seeds/forever.json --seed data/seeds/legacy.json --seed data/seeds/forever-generic.json --refresh

# Compare against the shipped hand-maintained databases (requires Lua).
python3 tools/audit_database.py forever

# After reviewing the report and testing, promote the complete known catalog.
# Failed fetches, unresolved restoration, or missing catalog items block this.
python3 tools/import_database.py forever --rebuild --activate

python3 -m unittest discover -s tests -v
lua tests/database_runtime.lua 16001
```

Replace `forever` with `era`, `tbc`, `wrath`, `cata`, `mop`, or `retail` for
another source profile. Never use a snapshot from another version as a fallback.
All seven known catalogs have been collected and published. Retail's 175
client-dependent entries are reported separately; a zero placeholder is never
presented as a known healing/mana amount.
To rebuild the seeds from the same ItemDB release archive:

```sh
python3 tools/seed_from_itemdb.py /path/to/ItemDB-ItemDB-v1.9.0.zip --release-url https://www.curseforge.com/wow/addons/libitemdb/files/9580874
```

## Sequential collection queue

On macOS or Linux, collect the supported clients with one resumable command:

```sh
python3 tools/collect_databases.py

# Read the queue state and live per-client cache counts from another terminal.
python3 tools/collect_databases.py --status

# Alternatively, collect only explicitly named profiles.
python3 tools/collect_databases.py wrath cata
```

The default order is Forever, Classic Era, TBC, Wrath, Cataclysm, MoP Classic,
then Retail. Each profile
combines its primary, legacy, and supplementary generic seeds where present.
Successful responses and snapshots are reused on subsequent runs. Only one
queue can run at a time; do not start independent network imports alongside it.

The queue stops entirely after HTTP 403/429, without trying another client or
automatically retrying. An interrupted run checkpoints progress. The state and
log are in `.cache/catalog/collection.json` and `collection.log`; `--status`
also counts raw cached responses, including progress not yet in a snapshot.
Collection errors and unresolved effects stay in each client's report. The
queue never passes `--activate`, and does not modify published runtime data.
Review and test each completed profile before promoting it as described above.

The supported profiles already have complete source snapshots. Re-running
collection reuses those snapshots and cached responses. Future uncached network
imports are sequential; response time adds to the configured delay.

Food detection handles generic consumable subclasses as well as food/drink
subclasses, so quest foods and injector potions are retained. Lasting Nightfin
Soup MP5 and Poached Sunscale Salmon HP5 are distinct from direct restoration.
Battleground-specific bandages and TBC Nethergon/Cenarion recovery items are
selected only in their allowed instances. Unknown use restrictions cause an item to be skipped.

HTTP responses are cached under `.cache/catalog/<version>/`, which Git ignores.
Requests are sequential, with a default delay of 2 seconds and a minimum of
0.5 seconds. The slower default reduces request volume; it does not establish
or guarantee compliance with an undocumented provider limit. A denied or
rate-limited request stops fetching and leaves the remaining IDs marked as
unattempted. No proxy, challenge bypass, or alternate-host retry is used.

## Review before activation

- Review the discovery provenance, failures, unavailable and excluded records,
  warnings, and unparsed effects in `reports/<version>.json`. The activation
  gate requires every version-specific ItemDB catalog ID to have a source
  record. Supplementary name-based candidates require either a source item or
  an explicit unavailable response. Both seed types must match their saved
  provenance. This verifies the known catalog, not the entire game.
  Activation also requires the core consumable categories to be populated, so
  a source classification change cannot silently replace working tables with
  an incomplete family-only database. Legacy recovery candidates discarded by
  the parser also block activation until reviewed.
- `reports/<version>-legacy-audit.json` compares category, restoration and food
  buff stats. A difference can be a real Forever change, not a manual-entry bug.
- Restoration values are totals; ranges use their arithmetic mean. Percentages
  are separate `hp` / `mp` fields and must not be treated as flat amounts.
  `Database.lua` evaluates these against current player resources at runtime;
  candidates needing unavailable or secret resource values are skipped.
- Constant arithmetic containing only numbers and basic operations is reduced
  with a bounded AST whitelist. Variables, conditional alternatives, unsupported
  operations, and unknown restoration syntax are reported rather than guessed. Excluded records are not proof an item is
  absent from the game. The source may include unused or restricted items.
- Confirm all relevant consumable categories, including conjured stones and
  mana gems, are covered. A successful category page or a large count alone
  does not prove completeness.
- Select the dataset for the actual client, then check selection, restrictions,
  cache readiness, and macro behavior in that client with the full addon setup.
  The Lua harness checks selection and data separation with mocked APIs; it does
  not establish compatibility with protected in-game execution or the full UI.

Response SHA-256 hashes and client-specific records are retained per item.
Provider URLs are omitted from committed snapshots. English source text keeps
parsing independent of the player's locale; the addon uses localized names
supplied by the game at runtime. No provider endpoint is built into the tools.

## Validation and release package

```sh
python3 -m unittest discover -s tests
lua tests/database_runtime.lua 16001
lua tests/database_runtime.lua 11509
lua tests/database_runtime.lua 20506
lua tests/database_runtime.lua 30405
lua tests/database_runtime.lua 40402
lua tests/database_runtime.lua 50504
python3 tools/package_addon.py
```

The selection harness has also passed with an official Lua 5.1.5 interpreter
built locally. It checks client separation, effect ranking, regeneration buffs,
location restrictions, combat deferral, and shared food scans. It does not
replace in-game testing. The deterministic versioned ZIP includes published
runtime databases and excludes source snapshots, reports, staging, and tools.

## Reviewed non-flat effects

Old healthstones describe restoring "life"; this is normalized to health.
Empty gems and inert old healthstone records without a restoration effect are
excluded. Cataclysm's level-dependent Healthstone and MoP's glyph-dependent
Healthstone remain available by family, without assigning an invented amount.
They appear explicitly in `reports/<version>.json` under
`familyOnlyRestoration`; scoring returns no numeric value for them. They do
not enter ordinary potion lists. In those two profiles only the usable
Healthstone record remains in the imported healthstone family. Activation is
blocked if a competing healthstone appears without a numeric comparison.

Potion of Concentration and Potion of Focus retain their interruptible channel
and maximum potential restoration. They are separate recovery potions and
never replace an instant combat mana potion.

MoP's mana-gem export includes an unresolved zero/duration placeholder for Glyph
of Loose Mana. The explicit unglyphed amount supplies the total under
[Blizzard's documented equal-total rule](https://worldofwarcraft.blizzard.com/en-us/news/10932273/54-hotfixes-december-2):
the glyph changes delivery time, not total restoration. Each affected generated
record retains that rule URL. This rule is scoped to the reviewed MoP IDs and
is not applied to Retail or other conditional tooltips. As with the other
imported behavior, confirmation in the actual client remains pending.

The added Wrath/Cata/MoP interface declarations (30405/40402/50504) match the
flavor TOCs in the same LibItemDB release archive used for candidate discovery.
They are load declarations, not proof of full UI/API compatibility.

## Retail runtime data

The complete 3,241-item source snapshot produces 2,050 normalized records in
`generated/retail.lua`. There are no fetch failures or syntax cases discarded
without a record/report. The 175 exports with missing, zero, conditional or
formula-based amounts are explicitly listed under `runtimeRestorationRequired`
in `reports/retail.json`; their original issues remain attached to each record.
Those entries have no invented numeric amounts. Another 1,318 records prefer
readable current-client values over flat exported amounts, for item-level and
quality differences. Fixed percentages, full recovery and an explicit health
cap remain modeled independently of flat amounts.

`RuntimeValues.lua` reads the actual bag slot via `C_TooltipInfo.GetBagItem`.
It accepts on-use lines using the named `ItemSpellTriggerOnUse` enum, ignores
item-level/equip lines and refuses secret values and ambiguous alternatives.
It handles localized health/mana labels, grouping separators, ranges and
explicit source-backed periodic timing. No amount is calculated when the
needed timing is missing. Different values on same-ID bag variants are not
collapsed into an optimistic rank: an item-ID macro cannot choose the variant.

Values are cached only within a macro refresh. Item-data completion and player
level/maximum-resource changes refresh selection; combat updates remain
queued until combat ends. Item-load requests are throttled. Conditional
healthstones can retain usable-family fallback without pretending their
healing was numerically compared. Nightmares/sleep/concentration recovery is
kept out of ordinary combat potion lists. Source restrictions include outdoor,
world-only and maximum-level limits. The 68 records whose named location rules
have not been mapped remain ineligible rather than losing their restrictions.

The parser has English, German and French fixtures. These checks establish
those tested formats, not every locale or full client compatibility. Buff
preferences still use the imported buff-stat data. Actual in-game confirmation
with the full addon setup remains necessary.

Run the published runtime tests or rebuild staging for isolated comparison:

```sh
python3 tools/import_database.py retail --rebuild
python3 -m unittest discover -s tests
lua tests/runtime_values.lua
lua tests/database_runtime.lua 120105
lua tests/database_runtime.lua 120105 --staged
```

`--staged` exists only in the test harness: it enables the staged table in that
Lua process, without rewriting the file or the published manifest. The normal
Retail harness invocation tests the published dataset. These checks also pass
under Lua 5.1. All seven client datasets are active. Retail Interface 120105
(12.1.5) was checked against the UI-source commit
[297d7aa](https://github.com/Gethe/wow-ui-source/commit/297d7aaaa736f346b3e036f38ee088eaf7f8c07f).

API definitions used for the reader:
[TooltipInfoDocumentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua),
[TooltipInfoSharedDocumentation](https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/TooltipInfoSharedDocumentation.lua).

Soulstone names alone do not establish resurrection behavior. The classifier
requires an actual usable resurrection effect, excluding inert old ranks and
unrelated reputation items such as Demon's Soulstone. The runtime harness
checks actual `ACSoulstone` selection for all seven published clients, including
Cataclysm and MoP where only the current usable Soulstone remains.

## Repository and release layout

Track `generated/`, `published/`, `sources/`, `seeds/` and `reports/` for
reproducibility. `staged/` is disposable generated output and is Git-ignored;
recreate it with `--rebuild`. Local HTTP/toolchain caches and `dist/` are ignored.
Do not remove published/source snapshots merely to reduce the installed size:
`.gitattributes` uses `export-ignore` to omit tests, tools, development snapshots,
reports and repository configuration from GitHub's automatic source archives.
The rules must be committed in the release tag. These files remain tracked and
available in a normal clone. The addon runtime files and `data/generated/`
remain included. `tools/package_addon.py` and `.pkgmeta` apply the equivalent
exclusions to separately packaged releases.
The release ZIP is named from the TOC version and contains only runtime assets
plus the license, README and changelog.
