-- Resolve missing Retail amounts from the actual bag item, never from another
-- client's database. Only readable on-use lines are considered.
-- API shape: Blizzard_APIDocumentationGenerated/TooltipInfoDocumentation.lua
-- and TooltipInfoSharedDocumentation.lua (ItemSpellTriggerOnUse).
local cache, slots, requested = {}, nil, {}

local function readable(value)
    return not (issecretvalue and issecretvalue(value))
end

local function numeric(value)
    return readable(value) and type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge and value or nil
end

local function textNumber(value)
    value = value:gsub("\194\160", ""):gsub("\226\128\175", "")
    local tail = value:match("[.,](%d+)$")
    if tail and #tail ~= 3 then
        local head = value:sub(1, #value - #tail - 1):gsub("[.,]", "")
        value = head .. "." .. tail
    else
        value = value:gsub("[.,]", "")
    end
    local result = numeric(tonumber(value))
    return result and result > 0 and result or nil
end

local function amountBefore(text, needle)
    if not readable(needle) or type(needle) ~= "string" or needle == "" then return nil end
    local first, last = text:find(needle:lower(), 1, true)
    if not first or text:find(needle:lower(), last + 1, true) then return nil end
    local prefix = text:sub(1, first - 1)
    local previous, current
    for start, value, finish in prefix:gmatch("()(%d[%d.,]*)()") do
        previous, current = current, {start=start, finish=finish, value=value}
    end
    if not current then return nil end
    local suffix = prefix:sub(current.finish)
    -- Do not cross a preceding sentence or another resource's description.
    if #suffix > 55 or suffix:find("[.!?;]") then return nil end
    if suffix:find("%%") and current.value:match("[.,]%d%d%d$") then return nil end
    local value = textNumber(current.value)
    if not value then return nil end
    if previous then
        local separator = prefix:sub(previous.finish, current.start - 1):gsub("%s", "")
        if separator == "to" or separator == "bis" or separator == "-" or separator == "–" or separator == "à" then
            local low = textNumber(previous.value)
            if not low then return nil end
            value = (low + value) / 2
        end
    end
    return value, suffix:find("%%") ~= nil
end

function AC_Database.ParseRuntimeUseText(text, stats)
    if not readable(text) or type(text) ~= "string" then return nil end
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
        :gsub("|T.-|t", ""):gsub("|A.-|a", ""):gsub("|H.-|h(.-)|h", "%1")
        :gsub("\194\160", ""):gsub("\226\128\175", ""):lower()
    for _ = 1, 4 do
        local grouped = text:gsub("(%d)%s(%d%d%d)(%D)", "%1%2%3")
        if grouped == text then break end
        text = grouped
    end
    if text:find("[%[%]]") or text:find(" / ", 1, true)
        or text:find("additional", 1, true) or text:find("zusätzlich", 1, true) then return nil end
    if text:find("up to", 1, true) or text:find("bis zu", 1, true) then return nil end
    local result = {h=0, m=0, hp=0, mp=0}
    local function resource(key, label, aliases)
        local value, percent = amountBefore(text, label)
        if not value then
            for _, alias in ipairs(aliases) do
                value, percent = amountBefore(text, alias)
                if value then break end
            end
        end
        if not value and key == "h" and stats.kind == "healthpotion" then
            local amount, sign = text:match("heal yourself for%s+(%d[%d.,]*)%s*(%%?)")
            if not amount then amount, sign = text:match("heilt euch.-um%s+(%d[%d.,]*)%s*(%%?)") end
            value, percent = amount and textNumber(amount), sign == "%"
        end
        if not value then return false end
        if stats.runtimePeriodic then
            -- Use only source timings whose duration and interval were explicit.
            if not stats.runtimeDuration or not stats.runtimeInterval or stats.runtimeInterval <= 0 then return false end
            value = value * stats.runtimeDuration / stats.runtimeInterval
        end
        if not numeric(value) then return false end
        result[key .. (percent and "p" or "")] = value
        return true
    end
    local healthAliases = {"health", "life"}
    if stats.kind == "bandage" then healthAliases[#healthAliases + 1] = DAMAGE or "damage" end
    if stats.runtimeHealth and not resource("h", HEALTH or "health", healthAliases) then return nil end
    if stats.runtimeMana and not resource("m", MANA or "mana", {"mana"}) then return nil end
    return result
end

function AC_Database.BeginUpdate()
    cache, slots = {}, nil
end

local function bagSlots()
    if slots then return slots end
    slots = {}
    local count = C_Container and C_Container.GetContainerNumSlots or GetContainerNumSlots
    local item = C_Container and C_Container.GetContainerItemID or GetContainerItemID
    if not count or not item then return slots end
    for bag = 0, NUM_TOTAL_EQUIPPED_BAG_SLOTS or NUM_BAG_SLOTS or 4 do
        for slot = 1, numeric(count(bag)) or 0 do
            local id = numeric(item(bag, slot))
            if id then
                slots[id] = slots[id] or {}
                slots[id][#slots[id] + 1] = {bag, slot}
            end
        end
    end
    return slots
end

local function requestItem(id)
    local now = GetTime and GetTime() or 0
    if C_Item and C_Item.RequestLoadItemDataByID and (not requested[id] or now - requested[id] >= 2) then
        requested[id] = now
        pcall(C_Item.RequestLoadItemDataByID, id)
    end
end

function AC_Database.ResolveRuntime(stats)
    if not stats.runtimeRestorationRequired and not stats.runtimeRestorationPreferred then return stats end
    if InCombatLockdown and InCombatLockdown() then return nil end
    local id = stats.runtimeItemID
    if not id or not C_TooltipInfo or not C_TooltipInfo.GetBagItem then return nil end
    if cache[id] ~= nil then return cache[id] or nil end
    cache[id] = false
    local onUse = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemSpellTriggerOnUse
    local resolved, matches = nil, 0
    for _, position in ipairs(bagSlots()[id] or {}) do
        local ok, data = pcall(C_TooltipInfo.GetBagItem, position[1], position[2])
        if ok and not readable(data) then return nil end
        if ok and type(data) == "table" and not readable(data.lines) then return nil end
        if ok and readable(data) and type(data) == "table" and readable(data.lines) and type(data.lines) == "table" then
            local candidate, lineCount, sawUse = nil, 0, false
            for _, line in ipairs(data.lines) do
                if not readable(line) then return nil end
                if type(line) == "table" and (not readable(line.type) or not readable(line.leftText)) then return nil end
                if readable(line) and type(line) == "table" and readable(line.type) and readable(line.leftText) then
                    local text = line.leftText
                    local prefix = ITEM_SPELL_TRIGGER_ONUSE
                    local isUse = onUse and line.type == onUse
                    if not isUse and type(text) == "string" and type(prefix) == "string" and prefix ~= "" then
                        isUse = text:sub(1, #prefix) == prefix
                    end
                    if isUse then
                        sawUse = true
                        local value = AC_Database.ParseRuntimeUseText(text, stats)
                        if value then candidate, lineCount = value, lineCount + 1 end
                    end
                end
            end
            if lineCount == 1 then
                -- Same-ID bag variants must agree; a macro using an ID cannot
                -- promise that the game will consume a particular variant.
                if resolved and (resolved.h ~= candidate.h or resolved.m ~= candidate.m
                    or resolved.hp ~= candidate.hp or resolved.mp ~= candidate.mp) then return nil end
                resolved, matches = candidate, matches + 1
            else
                if not sawUse then requestItem(id) end
                return nil
            end
        else
            requestItem(id)
            return nil
        end
    end
    if matches == 0 then return nil end
    local result = {}
    for key, value in pairs(stats) do result[key] = value end
    for key, value in pairs(resolved) do result[key] = value end
    result.runtimeRestorationRequired = false
    result.runtimeRestorationPreferred = false
    cache[id], requested[id] = result, nil
    return result
end
