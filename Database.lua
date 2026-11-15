-- Version-specific data adapter. The legacy databases remain the fallback for
-- clients whose replacement dataset has not been imported and enabled yet.
AC_Database = {}

function AC_Database.ClientVersion(interface)
    interface = tonumber(interface)
    if not interface then return nil end
    if interface >= 16000 and interface < 17000 then return "forever" end
    if interface >= 100000 then return "retail" end
    local major = math.floor(interface / 10000)
    return ({ [1] = "era", [2] = "tbc", [3] = "wrath", [4] = "cata", [5] = "mop" })[major]
end

local function safeNumber(value)
    if issecretvalue and issecretvalue(value) then return nil end
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

function AC_Database.Restoration(stats, healthMax, manaMax)
    local health, mana = stats.h or 0, stats.m or 0
    if (stats.hp or 0) > 0 then
        healthMax = safeNumber(healthMax or (UnitHealthMax and UnitHealthMax("player")))
        if not healthMax or healthMax <= 0 then return nil, nil end
        health = health + healthMax * stats.hp / 100
    end
    if (stats.mp or 0) > 0 then
        manaMax = safeNumber(manaMax or (UnitPowerMax and UnitPowerMax("player", 0)))
        if not manaMax or manaMax < 0 then return nil, nil end
        mana = mana + manaMax * stats.mp / 100
    end
    if stats.healthCap then health = math.min(health, stats.healthCap) end
    return health, mana
end

function AC_Database.Score(stats, resource)
    if not AC_Database.IsEligible(stats) then return nil end
    if stats.runtimeRestorationRequired or stats.runtimeRestorationPreferred then
        local resolved = AC_Database.ResolveRuntime and AC_Database.ResolveRuntime(stats)
        if resolved then stats = resolved
        elseif stats.runtimeRestorationRequired or (C_TooltipInfo and C_TooltipInfo.GetBagItem) then return nil end
    end
    if stats.familyOnlyRestoration then return nil end
    local health, mana = AC_Database.Restoration(stats)
    if health == nil then return nil end
    if resource == "h" then return health end
    if resource == "m" then return mana end
    return health + mana
end

function AC_Database.IsEligible(stats)
    if stats.contextUnknown then return false end
    if stats.maximumLevel then
        local level = safeNumber(UnitLevel and UnitLevel("player"))
        if not level or level > stats.maximumLevel then return false end
    end
    if stats.outdoorsOnly then
        local outdoors = IsOutdoors and IsOutdoors()
        if (issecretvalue and issecretvalue(outdoors)) or outdoors ~= true then return false end
    end
    if stats.worldOnly then
        local inside = IsInInstance and IsInInstance()
        if (issecretvalue and issecretvalue(inside)) or inside ~= false then return false end
    end
    if stats.battlegroundOnly then
        if not IsInInstance then return false end
        local _, instanceType = IsInInstance()
        if instanceType ~= "pvp" then return false end
    end
    if stats.allowedInstanceIDs then
        if not GetInstanceInfo then return false end
        local instanceID = safeNumber(select(8, GetInstanceInfo()))
        if not instanceID then return false end
        for _, allowed in ipairs(stats.allowedInstanceIDs) do
            if instanceID == allowed then return true end
        end
        return false
    end
    return true
end

local buffStatLabels = {
    Stamina = "Stamina", Spirit = "Spirit", Strength = "Strength", Agility = "Agility", Intellect = "Intellect",
    AttackPower = "Attack Power", SpellPower = "Spell Power", Healing = "Healing",
    Crit = "Critical Strike Rating", CritPercent = "Critical Strike Chance (%)", SpellCrit = "Spell Critical Strike",
    Haste = "Haste", Mastery = "Mastery", Versatility = "Versatility", Hit = "Hit",
    MP5 = "Mana / 5 sec", HP5 = "Health / 5 sec", Armor = "Armor",
    Fishing = "Fishing Skill", Herbalism = "Herbalism Skill", ResistAll = "All Resistances",
    Expertise = "Expertise", ArmorPenetration = "Armor Penetration", Dodge = "Dodge", Parry = "Parry",
}

function AC_Database.BuffStatLabel(stat)
    return buffStatLabels[stat] or stat
end

function AC_Database.BuffStatOptions()
    local options = { "Stamina", "Spirit", "Strength", "Agility", "Intellect" }
    local seen = { Stamina=true, Spirit=true, Strength=true, Agility=true, Intellect=true }
    for _, stats in pairs(AC_FOODDRINK_ITEM_STATS or {}) do
        if stats.wf then
            for stat, amount in pairs(stats.bs or {}) do
                if buffStatLabels[stat] and type(amount) == "number" and amount > 0 and not seen[stat] then
                    options[#options + 1], seen[stat] = stat, true
                end
            end
        end
    end
    table.sort(options, function(left, right)
        return AC_Database.BuffStatLabel(left) < AC_Database.BuffStatLabel(right)
    end)
    options[#options + 1] = "None"
    return options
end

function AC_Database.Activate(interface, datasets)
    local version = AC_Database.ClientVersion(interface)
    local dataset = version and datasets and datasets[version]
    if not dataset or not dataset.enabled then return false end
    if type(dataset.items) ~= "table" or not next(dataset.items) then return false end

    AC_FOOD_ITEMS, AC_DRINK_ITEMS, AC_FOODDRINK_BOTH_ITEMS, AC_BUFFFOOD_ITEMS = {}, {}, {}, {}
    AC_FOOD_ITEM_IDS, AC_DRINK_ITEM_IDS, AC_BUFFFOOD_ITEM_IDS, AC_FOOD_DRINK_ITEM_IDS = {}, {}, {}, {}
    AC_FOODDRINK_ITEM_STATS, AC_CONSUMABLE_ITEM_STATS = {}, dataset.items
    AC_HEALTH_POTION_ITEM_IDS, AC_MANA_POTION_ITEM_IDS, AC_BANDAGE_ITEM_IDS = {}, {}, {}
    AC_HEALTHSTONE_ITEM_IDS, AC_MANAAGATE_ITEM_IDS, AC_SOULSTONE_ITEM_IDS = {}, {}, {}
    AC_POTION_BANDAGE_ITEM_IDS = {}

    for itemID, stats in pairs(dataset.items) do
        if stats.runtimeRestorationRequired or stats.runtimeRestorationPreferred then stats.runtimeItemID = itemID end
        local kind = stats.kind
        if kind == "food" or kind == "drink" or kind == "both" or kind == "buff" then
            AC_FOOD_DRINK_ITEM_IDS[itemID] = true
            AC_FOODDRINK_ITEM_STATS[itemID] = stats
            if kind == "food" then
                AC_FOOD_ITEMS[itemID], AC_FOOD_ITEM_IDS[itemID] = stats, true
            elseif kind == "drink" then
                AC_DRINK_ITEMS[itemID], AC_DRINK_ITEM_IDS[itemID] = stats, true
            elseif kind == "both" then
                AC_FOODDRINK_BOTH_ITEMS[itemID] = stats
            else
                AC_BUFFFOOD_ITEM_IDS[itemID] = true
                AC_BUFFFOOD_ITEMS.Other = AC_BUFFFOOD_ITEMS.Other or {}
                AC_BUFFFOOD_ITEMS.Other[itemID] = stats
                for stat in pairs(stats.bs or {}) do
                    AC_BUFFFOOD_ITEMS[stat] = AC_BUFFFOOD_ITEMS[stat] or {}
                    AC_BUFFFOOD_ITEMS[stat][itemID] = stats
                end
            end
        else
            AC_POTION_BANDAGE_ITEM_IDS[itemID] = true
            if kind == "healthpotion" or kind == "manapotion" then
                if (stats.h or 0) > 0 or (stats.hp or 0) > 0 or stats.runtimeHealth then AC_HEALTH_POTION_ITEM_IDS[itemID] = true end
                if (stats.m or 0) > 0 or (stats.mp or 0) > 0 or stats.runtimeMana then AC_MANA_POTION_ITEM_IDS[itemID] = true end
            elseif kind == "bandage" then AC_BANDAGE_ITEM_IDS[itemID] = true
            elseif kind == "healthstone" then AC_HEALTHSTONE_ITEM_IDS[itemID] = true
            elseif kind == "managem" then AC_MANAAGATE_ITEM_IDS[itemID] = true
            elseif kind == "soulstone" then AC_SOULSTONE_ITEM_IDS[itemID] = true end
        end
    end
    AC_Database.activeVersion = version
    AC_Database.source = dataset.source
    return true
end
