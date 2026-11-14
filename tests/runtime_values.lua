-- Focused checks of public bag tooltip values; no claim of in-game validation.
dofile("Database.lua")
dofile("RuntimeValues.lua")
HEALTH, MANA, DAMAGE = "Health", "Mana", "Damage"
local hp = {kind="healthpotion", runtimeHealth=true}
local both = {kind="both", runtimeHealth=true, runtimeMana=true}
local parse = AC_Database.ParseRuntimeUseText
assert(parse("Use: Restores 12,345 health over 20 sec.", hp).h == 12345)
assert(parse("Use: Restores 2,700 to 4,500 health.", hp).h == 3600)
assert(parse("Use: Restores 2.5% of your maximum health.", hp).hp == 2.5)
assert(parse("Use: Restores 3% of your health and mana.", both).mp == 3)
assert(parse("Use: Restores 100 health and 250 mana.", both).m == 250)
HEALTH = "Gesundheit"
assert(parse("Benutzen: Stellt im Verlauf von 18 Sek. 1.200 Gesundheit wieder her.", hp).h == 1200)
assert(parse("Benutzen: Stellt 2.700 bis 4.500 Gesundheit wieder her.", hp).h == 3600)
HEALTH = "Vie"
assert(parse("Utiliser : Rend 1 200 points de vie en 18 sec.", hp).h == 1200)
assert(parse("Utiliser : Rend 1\194\160200 points de vie en 18 sec.", hp).h == 1200)
HEALTH = "Health"
assert(parse("Use: Heal yourself for 9156, but suffer Plague damage.", hp).h == 9156)
assert(parse("Use: Restores [25% health / 40% health].", hp) == nil)
assert(parse("Use: Restores 25% health plus an additional 30%.", hp) == nil)
assert(parse("Use: Restores 0 health.", hp) == nil)
assert(parse("Use: Restores 2.000% health.", hp) == nil, "Ambiguous percentage separators must not become 2000 percent")
assert(parse("Use: Restores up to 500 health.", hp) == nil)
assert(parse("Use: Restores health.", hp) == nil)
local periodic = {kind="bandage", runtimeHealth=true, runtimePeriodic=true, runtimeInterval=1, runtimeDuration=8}
assert(parse("Use: Heals 10% of their maximum health every 1 sec for 8 sec.", periodic).hp == 80)
periodic.runtimeDuration = nil
assert(parse("Use: Heals 10% of their maximum health every 1 sec.", periodic) == nil)

local protected = setmetatable({}, {__tostring=function() error("secret was inspected") end})
issecretvalue = function(value) return value == protected end
assert(parse(protected, hp) == nil)
local combat, ready, calls, loads = false, true, 0, 0
InCombatLockdown = function() return combat end
GetTime = function() return 100 end
Enum = {TooltipDataLineType={ItemSpellTriggerOnUse=44}}
local bag = {117}
local text = "Use: Restores 5000 health over 18 sec."
C_Container = {
    GetContainerNumSlots=function(b) return b == 0 and #bag or 0 end,
    GetContainerItemID=function(_, slot) return bag[slot] end,
}
C_Item = {RequestLoadItemDataByID=function(id) assert(id == 117); loads = loads + 1 end}
C_TooltipInfo = {GetBagItem=function(_, slot)
    calls = calls + 1
    if not ready then return nil end
    return {lines={
        {type=0, leftText="Item Level 999999 Health"},
        {type=45, leftText="Equip: Restores 999999 health."},
        {type=44, leftText=slot == 2 and "Use: Restores 6000 health." or text},
    }}
end}
local stats = {kind="food", runtimeRestorationRequired=true, runtimeHealth=true, runtimeItemID=117, h=0, m=0, hp=0, mp=0}
AC_Database.BeginUpdate()
assert(AC_Database.ResolveRuntime(stats).h == 5000)
assert(AC_Database.ResolveRuntime(stats).h == 5000 and calls == 1)
assert(stats.h == 0, "Live values must not overwrite the source snapshot")
text = "Use: Restores 7000 health."
AC_Database.BeginUpdate()
assert(AC_Database.ResolveRuntime(stats).h == 7000)
combat = true
assert(AC_Database.ResolveRuntime(stats) == nil)
combat = false
ready = false
AC_Database.BeginUpdate()
assert(AC_Database.ResolveRuntime(stats) == nil and loads == 1)
AC_Database.BeginUpdate()
assert(AC_Database.ResolveRuntime(stats) == nil and loads == 1, "Load requests must be throttled")
ready = true
text = protected
AC_Database.BeginUpdate()
assert(AC_Database.ResolveRuntime(stats) == nil)
text = "Use: Restores 5000 health."
bag = {117, 117}
AC_Database.BeginUpdate()
assert(AC_Database.ResolveRuntime(stats) == nil, "Conflicting same-ID bag variants must not be overestimated")
UnitHealthMax = function() return 1000000 end
assert(AC_Database.Restoration({hp=50, healthCap=175000}) == 175000)
assert(AC_Database.Restoration({hp=50, healthCap=175000}, 200000) == 100000)
IsOutdoors = function() return false end
assert(not AC_Database.IsEligible({outdoorsOnly=true}))
IsInInstance = function() return true, "party" end
assert(not AC_Database.IsEligible({worldOnly=true}))
UnitLevel = function() return 80 end
assert(not AC_Database.IsEligible({maximumLevel=49}))
print("Public runtime amounts, locales, caching, protected values and restrictions passed")
