-- Runs against the shipped modules with a small WoW API harness. This checks
-- data and macro-selection behavior, not protected in-game execution or UI.
SlashCmdList = {}
local report = print
print = function() end
UIParent = {}
local interface = tonumber(arg[1]) or 16001
GetBuildInfo = function() return "test", "test", "test", interface end
UnitHealthMax = function() return 10000 end
UnitPowerMax = function() return 6000 end
UnitLevel = function() return ({[20506]=70, [30405]=80, [40402]=85, [50504]=90})[interface] or 60 end
local inCombat = false
InCombatLockdown = function() return inCombat end
IsUsableItem = function() return true end
GetTime = function() return 100 end
CreateFrame = function()
    return {
        SetOwner = function() end, RegisterEvent = function() end, RegisterUnitEvent = function() end,
        SetScript = function(self, key, value) self[key] = value end,
        GetScript = function(self, key) return self[key] end,
        ClearLines = function() end, SetBagItem = function() end, NumLines = function() return 2 end,
    }
end

dofile("FoodDrinkDB.lua")
dofile("PotionBandageDB.lua")
local legacyFood = AC_FOOD_ITEMS
dofile("Database.lua")
dofile("RuntimeValues.lua")
local manifest = assert(io.open("Databases.xml")):read("*a")
for file in manifest:gmatch('<Script file="([^"]+)"') do dofile(file) end
local version = AC_Database.ClientVersion(interface)
if not (AC_WOWHEAD_DATABASES and AC_WOWHEAD_DATABASES[version]) then
    local staging = "data/staged/" .. version .. ".lua"
    local file = io.open(staging)
    if file then file:close(); dofile(staging) end
end
local stagedRetail = version == "retail" and arg[2] == "--staged"
if stagedRetail then
    assert(AC_WOWHEAD_DATABASES.retail.enabled == false, "Retail staging must stay disabled on disk")
    AC_WOWHEAD_DATABASES.retail.enabled = true -- test process only; never publish
    UnitLevel = function() return 90 end
end
dofile("DatabaseInit.lua")
assert(AC_Database.ClientVersion(11509) == "era")
assert(AC_Database.ClientVersion(16001) == "forever")
assert(AC_Database.ClientVersion(20506) == "tbc")
assert(AC_Database.ClientVersion(30405) == "wrath")
assert(AC_Database.ClientVersion(40402) == "cata")
assert(AC_Database.ClientVersion(50504) == "mop")
assert(AC_Database.ClientVersion(120105) == "retail")

local activeTBC = interface == 20506 and AC_Database.activeVersion == "tbc"
local activeEra = interface == 11509 and AC_Database.activeVersion == "era"
local activeWrath = interface == 30405 and AC_Database.activeVersion == "wrath"
local activeCata = interface == 40402 and AC_Database.activeVersion == "cata"
local activeMoP = interface == 50504 and AC_Database.activeVersion == "mop"
if stagedRetail then
    assert(AC_Database.activeVersion == "retail")
    assert(AC_CONSUMABLE_ITEM_STATS[117].runtimeRestorationRequired)
    assert(AC_HEALTH_POTION_ITEM_IDS[109223])
    assert(AC_MANA_POTION_ITEM_IDS[2455])
    assert(not AC_SOULSTONE_ITEM_IDS[153113])
elseif activeEra then
    assert(AC_WOWHEAD_DATABASES.forever == nil and AC_WOWHEAD_DATABASES.tbc == nil)
    assert(AC_DRINK_ITEMS[8077].m == 1992)
    assert(AC_BUFFFOOD_ITEMS.MP5[13931].bs.MP5 == 8)
    assert(AC_BUFFFOOD_ITEMS.HP5[13932].bs.HP5 == 6)
    assert(AC_MANAAGATE_ITEM_IDS[5514])
    assert(not AC_HEALTH_POTION_ITEM_IDS[22829], "TBC potions must not leak into Era")
elseif activeMoP then
    assert(AC_WOWHEAD_DATABASES.forever == nil and AC_WOWHEAD_DATABASES.cata == nil)
    assert(AC_CONSUMABLE_ITEM_STATS[5512].familyOnlyRestoration)
    assert(AC_Database.Score(AC_CONSUMABLE_ITEM_STATS[5512], "h") == nil)
    assert(AC_CONSUMABLE_ITEM_STATS[5513].m == 45000)
    assert(AC_CONSUMABLE_ITEM_STATS[5514].m == 585)
    assert(AC_CONSUMABLE_ITEM_STATS[5513].totalInvariantUnderGlyph)
    assert(not AC_MANA_POTION_ITEM_IDS[76092], "Focus potions must not replace instant combat recovery")
    assert(AC_CONSUMABLE_ITEM_STATS[101745].m == 300000, "Numeric source arithmetic must retain its total")
elseif activeWrath or activeCata then
    assert(AC_WOWHEAD_DATABASES.forever == nil and AC_WOWHEAD_DATABASES.tbc == nil)
    assert(AC_CONSUMABLE_ITEM_STATS[5223] == nil, "Empty Mana Gem is not usable recovery")
    assert(AC_DRINK_ITEMS[8077].m == 1992)
    assert(not AC_MANA_POTION_ITEM_IDS[57194], "Concentration potions must not replace instant combat recovery")
    if activeWrath then
        assert(AC_CONSUMABLE_ITEM_STATS[5512].h == 100)
        assert(AC_BUFFFOOD_ITEMS.Expertise[42994].bs.Expertise == 40)
        assert(AC_BUFFFOOD_ITEMS.ArmorPenetration[42995].bs.ArmorPenetration == 40)
    else
        assert(AC_CONSUMABLE_ITEM_STATS[5512].familyOnlyRestoration)
        assert(AC_Database.Score(AC_CONSUMABLE_ITEM_STATS[5512], "h") == nil)
        assert(AC_CONSUMABLE_ITEM_STATS[57194].restorationUpperBound)
    end
elseif interface ~= 16001 and not activeTBC then
    assert(AC_Database.activeVersion == nil)
    assert(AC_FOOD_ITEMS == legacyFood, "Another client's data must not be replaced by Forever")
    assert(AC_HEALTH_POTION_ITEM_IDS[22829], "Legacy TBC data must remain available")
elseif activeTBC then
    assert(AC_WOWHEAD_DATABASES.forever == nil, "Foreign datasets must return before registration")
    assert(AC_DRINK_ITEMS[8077].m == 1992, "TBC water must not use Forever's changed value")
    assert(AC_BUFFFOOD_ITEMS.MP5[13931].bs.MP5 == 8)
    assert(AC_BUFFFOOD_ITEMS.HP5[13932].bs.HP5 == 6)
    assert(AC_BUFFFOOD_ITEMS.ResistAll[33867].bs.ResistAll == 8)
    assert(AC_MANAAGATE_ITEM_IDS[22044])
else
assert(AC_Database.activeVersion == "forever")
local activeFood = AC_FOOD_ITEMS
assert(not AC_Database.Activate(16001, {forever={enabled=true, items={}}}))
assert(AC_FOOD_ITEMS == activeFood, "An empty replacement must not erase working data")
assert(AC_FOOD_ITEMS[8077] == nil and AC_DRINK_ITEMS[8077].m == 1915)
assert(AC_BUFFFOOD_ITEMS.Agility[238638].bs.Agility == 25)
assert(AC_BUFFFOOD_ITEMS.Stamina[250078].bs.Stamina == 10, "Tooltip-only Forever stats must survive")
assert(AC_MANAAGATE_ITEM_IDS[5514], "Mana Agate must survive inconsistent source item classification")
assert(not AC_HEALTH_POTION_ITEM_IDS[22829], "Absent TBC items must not leak into Forever")
assert(not AC_HEALTH_POTION_ITEM_IDS[12190], "Sleep potions must not replace combat healing")
local options = {}
for _, stat in ipairs(AC_Database.BuffStatOptions()) do options[stat] = true end
assert(options.CritPercent and options.Armor, "Imported food stats must be selectable")
assert(not options.MovementSpeedPercent, "Conditional zone buffs must not be offered as unconditional stats")
assert(AC_Database.BuffStatLabel("CritPercent") ~= AC_Database.BuffStatLabel("Crit"))
assert(AC_MANA_POTION_ITEM_IDS[18253] and AC_HEALTH_POTION_ITEM_IDS[18253], "Hybrid potions belong to both resources")
local health, mana = AC_Database.Restoration({hp=30, mp=20})
assert(health == 3000 and mana == 1200)
assert(AC_Database.Restoration({hp=30}, 0) == nil)
issecretvalue = function(value) return value == "secret" end
assert(AC_Database.Restoration({hp=30}, "secret") == nil)
issecretvalue = nil
end

local bag = {}
local bagItems = {}
local function setBag(ids)
    bag, bagItems = {}, ids
    for _, id in ipairs(ids) do bag[id] = (bag[id] or 0) + 1 end
end
local countQueries = {}
GetItemCount = function(id)
    countQueries[id] = (countQueries[id] or 0) + 1
    return bag[id] or 0
end
GetItemInfo = function(id)
    local stats = (AC_CONSUMABLE_ITEM_STATS and AC_CONSUMABLE_ITEM_STATS[id]) or AC_FOODDRINK_ITEM_STATS[id]
    return stats and stats.name or ("item:" .. id), nil, nil, nil, stats and stats.requiredLevel or 0
end
C_Container = {
    GetContainerNumSlots = function(bagID) return bagID == 0 and #bagItems or 0 end,
    GetContainerItemID = function(_, slot) return bagItems[slot] end,
    GetContainerItemCooldown = function() return 0, 0, 1 end,
}
local macros, byName = {}, {}
GetNumMacros = function() return #macros, 0 end
GetMacroIndexByName = function(name) return byName[name] or 0 end
GetMacroInfo = function(index)
    local entry = macros[index]
    if entry then return entry.name, 1, entry.body end
end
CreateMacro = function(name, _, body)
    local index = #macros + 1
    macros[index] = {name=name, body=body}
    byName[name] = index
    return index
end
EditMacro = function(index, name, _, body)
    macros[index] = {name=name, body=body}
    byName[name] = index
end
local function uses(name, id)
    local body = assert(macros[assert(byName[name])]).body
    assert(body:find("/use item:" .. id .. "\n", 1, true)
        or body:find("/use [@player] item:" .. id .. "\n", 1, true), name .. " selected incorrectly: " .. body)
end

local liveAmounts, tooltipQueries, dataLoads, missing = {}, {}, {}, {}
if stagedRetail then
    HEALTH, MANA, DAMAGE = "Health", "Mana", "Damage"
    Enum = {TooltipDataLineType={ItemSpellTriggerOnUse=44}}
    C_Item = {RequestLoadItemDataByID=function(id) dataLoads[id] = (dataLoads[id] or 0) + 1 end}
    C_TooltipInfo = {GetBagItem=function(_, slot)
        local id = bagItems[slot]
        tooltipQueries[id] = (tooltipQueries[id] or 0) + 1
        if missing[id] then return nil end
        local text = liveAmounts[id]
        if not text then return nil end
        return {lines={{type=0, leftText="Item Level 999999"}, {type=44, leftText=text}}}
    end}
end

dofile("Automated-Consumables.lua")
if AC_Database.activeVersion then
    local bestSoulstone = ({forever=16896, era=16896, tbc=22116, wrath=36895, cata=5232, mop=5232, retail=5232})[version]
    assert(not AC_SOULSTONE_ITEM_IDS[1199], "An inert Charged Soulstone must not enter the resurrection macro")
    setBag({1199, 5232, 16896, 22116, 36895, 153113})
    SlashCmdList.ACUPDATE()
    uses("ACSoulstone", assert(bestSoulstone))
end
if stagedRetail then
    liveAmounts[117] = "Use: Restores 1000 health over 18 sec."
    liveAmounts[2455] = "Use: Restores 4000 mana."
    liveAmounts[109223] = "Use: Restores 50000 health."
    liveAmounts[194048] = "Use: Heals 30000 damage over 8 sec."
    setBag({117, 159, 2455, 109223, 194048})
    local before = tooltipQueries[117] or 0
    SlashCmdList.ACUPDATE()
    uses("ACFood", 117)
    uses("ACDrink", 159)
    uses("ACHealthPotion", 109223)
    uses("ACManaPotion", 2455)
    uses("ACBandage", 194048)
    assert((tooltipQueries[117] or 0) - before == 1, "Food macros must share one runtime lookup")
    liveAmounts[118] = "Use: Restores 1000 health."
    liveAmounts[76097] = "Use: Restores 50000 health."
    setBag({118, 76097})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 76097) -- prefer the live amount over an old export's six health
    liveAmounts[191369] = "Use: Heal yourself for 915600, but suffer that much as Plague damage."
    setBag({109223, 191369})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 109223) -- avoid harmful recovery even when its live amount is larger
    setBag({118, 109223})
    missing[109223] = true
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 118)
    assert(dataLoads[109223])
    missing[109223] = false
    local handler = AutomatedConsumablesFrame:GetScript("OnEvent")
    handler(AutomatedConsumablesFrame, "ITEM_DATA_LOAD_RESULT", 109223, true)
    uses("ACHealthPotion", 109223)
    liveAmounts[5845] = "Use: Restores 5000 health over 24 sec."
    setBag({117, 5845})
    SlashCmdList.ACUPDATE()
    uses("ACFood", 5845)
    inCombat = true
    liveAmounts[117] = "Use: Restores 9000 health over 18 sec."
    local queriesBefore = tooltipQueries[117]
    handler(AutomatedConsumablesFrame, "ITEM_DATA_LOAD_RESULT", 117, true)
    uses("ACFood", 5845)
    assert(tooltipQueries[117] == queriesBefore)
    inCombat = false
    handler(AutomatedConsumablesFrame, "PLAYER_REGEN_ENABLED")
    uses("ACFood", 117)
    liveAmounts[5512] = "Use: Instantly restores 25% health."
    setBag({5512})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 5512)
    liveAmounts[118] = "Use: Restores 6000 health."
    setBag({118, 258138})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 118)
    UnitHealthMax = function() return 40000 end
    local previousQueries = tooltipQueries[118]
    handler(AutomatedConsumablesFrame, "UNIT_MAXHEALTH", "party1")
    assert(tooltipQueries[118] == previousQueries)
    handler(AutomatedConsumablesFrame, "UNIT_MAXHEALTH", "player")
    uses("ACHealthPotion", 258138)
    local deferred
    C_Timer = {After=function(delay, callback) assert(delay == 0); deferred = callback end}
    liveAmounts[118] = "Use: Restores 100000 health."
    handler(AutomatedConsumablesFrame, "PLAYER_LEVEL_UP", 91)
    uses("ACHealthPotion", 258138)
    assert(deferred)
    deferred()
    uses("ACHealthPotion", 118)
    report("Retail staging: actual bag values, source overrides, requests, combat deferral and macros passed")
    return
end
if activeMoP then
    setBag({117, 75026, 76097, 76098, 76092, 72985, 72986})
    SlashCmdList.ACUPDATE()
    uses("ACFood", 75026)
    uses("ACDrink", 75026)
    uses("ACHealthPotion", 76097)
    uses("ACManaPotion", 76098)
    uses("ACBandage", 72986)
    setBag({5513, 5514})
    SlashCmdList.ACUPDATE()
    uses("ACManaPotion", 5513) -- 45000 total mana beats the newer ID's 585
    setBag({5512})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 5512)
    setBag({101745, 62670})
    ACSettings.buffFoodPreferenceMode = "stat"
    ACSettings.buffFoodPreferredStat1 = "Mastery"
    SlashCmdList.ACUPDATE()
    uses("ACBuff", 101745)
    report("MoP arithmetic totals, glyph-safe gems, family-only healthstone and macro selection passed")
    return
end
if activeWrath then
    setBag({117, 43523, 33447, 33448, 21991, 34722})
    SlashCmdList.ACUPDATE()
    uses("ACFood", 43523)
    uses("ACDrink", 43523)
    uses("ACHealthPotion", 33447)
    uses("ACManaPotion", 33448)
    uses("ACBandage", 34722)
    setBag({5510, 19004})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 5510) -- 800 life beats a newer minor stone's 110
    setBag({42994, 42999})
    ACSettings.buffFoodPreferenceMode = "stat"
    ACSettings.buffFoodPreferredStat1 = "Expertise"
    SlashCmdList.ACUPDATE()
    uses("ACBuff", 42994)
    report("Wrath data, healthstone life values, food ratings and actual macro selection passed")
    return
end
if activeCata then
    setBag({117, 43523, 57191, 57192, 57194, 53050, 53051})
    SlashCmdList.ACUPDATE()
    uses("ACFood", 43523)
    uses("ACDrink", 43523)
    uses("ACHealthPotion", 57191)
    uses("ACManaPotion", 57192)
    uses("ACBandage", 53051)
    setBag({5512})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 5512) -- keep the usable family without inventing base-health scaling
    setBag({62670, 42999})
    ACSettings.buffFoodPreferenceMode = "stat"
    ACSettings.buffFoodPreferredStat1 = "Strength"
    SlashCmdList.ACUPDATE()
    uses("ACBuff", 62670)
    report("Cataclysm data, family-only healthstone, channel exclusions and macro selection passed")
    return
end
if activeEra then
    setBag({117, 8077, 118, 13446, 14529, 14530})
    SlashCmdList.ACUPDATE()
    uses("ACFood", 117)
    uses("ACDrink", 8077)
    uses("ACHealthPotion", 13446)
    uses("ACBandage", 14530)
    setBag({13931, 21217, 13444})
    ACSettings.buffFoodPreferenceMode = "stat"
    ACSettings.buffFoodPreferredStat1 = "MP5"
    SlashCmdList.ACUPDATE()
    uses("ACBuff", 13931)
    uses("ACManaPotion", 13444)
    report("Era data, regeneration buffs, potion and bandage macro selection passed")
    return
end
if activeTBC then
    setBag({117, 8077, 22829, 23579})
    local before = countQueries[117] or 0
    SlashCmdList.ACUPDATE()
    assert((countQueries[117] or 0) - before <= 4, "A full update must share food selection between its three macros")
    uses("ACDrink", 8077)
    uses("ACHealthPotion", 22829)

    setBag({22832, 31677})
    SlashCmdList.ACUPDATE()
    uses("ACManaPotion", 22832) -- no spellpower penalty in preference to ordinary mana recovery

    setBag({13931, 21217})
    ACSettings.buffFoodPreferenceMode = "stat"
    ACSettings.buffFoodPreferredStat1 = "MP5"
    SlashCmdList.ACUPDATE()
    uses("ACBuff", 13931)

    setBag({21990, 21991})
    SlashCmdList.ACUPDATE()
    uses("ACBandage", 21991)

    setBag({22832, 32902})
    local instanceID = 0
    GetInstanceInfo = function() return "test", "party", nil, nil, nil, nil, nil, instanceID end
    SlashCmdList.ACUPDATE()
    uses("ACManaPotion", 22832)
    instanceID = 554
    AutomatedConsumablesFrame:GetScript("OnEvent")(AutomatedConsumablesFrame, "ZONE_CHANGED_NEW_AREA")
    uses("ACManaPotion", 32902)
    instanceID = 545
    AutomatedConsumablesFrame:GetScript("OnEvent")(AutomatedConsumablesFrame, "PLAYER_ENTERING_WORLD")
    uses("ACManaPotion", 22832)

    setBag({118, 32904})
    for _, id in ipairs({548, 546, 545, 547}) do
        instanceID = id
        SlashCmdList.ACUPDATE()
        uses("ACHealthPotion", 32904)
    end
    instanceID = 550
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 118) -- Coilfang salves cannot be used in Tempest Keep
    assert(not AC_Database.IsEligible(AC_CONSUMABLE_ITEM_STATS[32783]))
    report("TBC data, regeneration buffs, potion penalties and instance-restricted recovery passed")
    return
end
if interface ~= 16001 then
    setBag({118, 22829})
    SlashCmdList.ACUPDATE()
    uses("ACHealthPotion", 22829)
    report("Client separation and legacy macro selection passed for interface " .. interface)
    return
end
setBag({117, 8077, 13446, 288896})
local before = countQueries[117] or 0
SlashCmdList.ACUPDATE()
assert((countQueries[117] or 0) - before <= 4, "A full update must share food selection between its three macros")
uses("ACFood", 117)
uses("ACDrink", 8077)
uses("ACHealthPotion", 13446) -- stronger than the much newer ID 288896

setBag({13446, 241650, 20002})
SlashCmdList.ACUPDATE()
uses("ACHealthPotion", 13446) -- no sleep or harmful after-effect in preference to a safe potion

setBag({241650})
SlashCmdList.ACUPDATE()
uses("ACHealthPotion", 241650) -- still available when it is the only healing potion

setBag({117, 8077, 21215})
SlashCmdList.ACUPDATE()
uses("ACFood", 21215)
uses("ACDrink", 21215)

ACSettings.buffFoodPreferenceMode = "stat"
ACSettings.buffFoodPreferredStat1 = "Stamina"
setBag({5479, 250078})
SlashCmdList.ACUPDATE()
uses("ACBuff", 250078) -- 10 Stamina recovered from the tooltip, versus 3

ACSettings.buffFoodPreferredStat1 = "CritPercent"
setBag({250078, 13928})
SlashCmdList.ACUPDATE()
uses("ACBuff", 13928)

setBag({5514, 5513})
SlashCmdList.ACUPDATE()
uses("ACManaPotion", 5513) -- stronger Mana Jade despite its lower item ID

setBag({5510, 19004})
SlashCmdList.ACUPDATE()
uses("ACHealthPotion", 5510) -- 960 life beats a newer minor stone's 110

UnitHealthMax = function() return 0 end
setBag({117, 19696})
SlashCmdList.ACUPDATE()
uses("ACFood", 117) -- do not rank percent food using unknown player health
UnitHealthMax = function() return 10000 end

setBag({17348, 118})
IsInInstance = function() return false, "none" end
SlashCmdList.ACUPDATE()
uses("ACHealthPotion", 118)
IsInInstance = function() return true, "pvp" end
SlashCmdList.ACUPDATE()
uses("ACHealthPotion", 17348)

setBag({1251, 19066})
local instanceID = 529
GetInstanceInfo = function() return "test", "pvp", nil, nil, nil, nil, nil, instanceID end
SlashCmdList.ACUPDATE()
uses("ACBandage", 1251) -- Warsong bandage cannot be used in Arathi Basin
instanceID = 489
AutomatedConsumablesFrame:GetScript("OnEvent")(AutomatedConsumablesFrame, "ZONE_CHANGED_NEW_AREA")
uses("ACBandage", 19066)
inCombat = true
IsInInstance = function() return false, "none" end
instanceID = 0
AutomatedConsumablesFrame:GetScript("OnEvent")(AutomatedConsumablesFrame, "ZONE_CHANGED_NEW_AREA")
uses("ACBandage", 19066) -- protected macro changes are deferred during combat
inCombat = false
AutomatedConsumablesFrame:GetScript("OnEvent")(AutomatedConsumablesFrame, "PLAYER_REGEN_ENABLED")
uses("ACBandage", 1251)

setBag({117, 19060, 8077})
IsInInstance = function() return false, "none" end
SlashCmdList.ACUPDATE()
uses("ACFood", 117)
uses("ACDrink", 8077)
IsInInstance = function() return true, "pvp" end
instanceID = 529
SlashCmdList.ACUPDATE()
uses("ACFood", 117) -- Warsong rations cannot be used in Arathi Basin
instanceID = 489
AutomatedConsumablesFrame:GetScript("OnEvent")(AutomatedConsumablesFrame, "ZONE_CHANGED_NEW_AREA")
uses("ACFood", 19060)
uses("ACDrink", 19060)

assert(AC_CONSUMABLE_ITEM_STATS[238641].kind == "placedfood")
assert(not AC_BUFFFOOD_ITEM_IDS[238641], "Placing a feast does not directly grant its meal's buff")
setBag({117, 8077, 1251, 272055, 272058})
for _, id in ipairs({489, 16606, 2524}) do
    instanceID = id
    SlashCmdList.ACUPDATE()
    uses("ACFood", 117)
    uses("ACDrink", 8077)
    uses("ACBandage", 1251)
end
instanceID = 2997
AutomatedConsumablesFrame:GetScript("OnEvent")(AutomatedConsumablesFrame, "ZONE_CHANGED_NEW_AREA")
uses("ACFood", 272055)
uses("ACDrink", 272055)
uses("ACBandage", 272058)
for id = 272053, 272058 do
    assert(AC_Database.IsEligible(AC_CONSUMABLE_ITEM_STATS[id]), "Every Darkspear ration and bandage must retain its verified context")
end
IsInInstance = function() return false, "none" end
SlashCmdList.ACUPDATE()
uses("ACFood", 117)
uses("ACBandage", 1251)
assert(AC_CONSUMABLE_ITEM_STATS[227813].availabilityUncertain)
setBag({15723})
SlashCmdList.ACUPDATE()
uses("ACHealthPotion", 15723)
uses("ACManaPotion", 15723)

setBag({8077, 19997})
SlashCmdList.ACUPDATE()
uses("ACDrink", 19997) -- 60% of 6000 mana beats 1915

report("Forever data, percentages, eligibility and actual macro selection passed")
