	
		local BAG_ID_BACKPACK = 0
		local BAG_ID_LAST = 4
	
		local basicMacroButtonName = "ACbutton";

		if type(ACSettings) ~= "table" then
			ACSettings = {}
		end
		if ACSettings.defaultsVersion ~= 1 then
			ACSettings.showMinimapButton = true
			ACSettings.showMacroUpdateMessages = true
			ACSettings.defaultsVersion = 1
		end
		if ACSettings.showMinimapButton == nil then
			ACSettings.showMinimapButton = true
		end
		if ACSettings.showMacroUpdateMessages == nil then
			ACSettings.showMacroUpdateMessages = true
		end
		if ACSettings.buffFoodPreferenceMode == nil then
			ACSettings.buffFoodPreferenceMode = "restore"
		end
		if ACSettings.buffFoodPreferredStat1 == nil then
			ACSettings.buffFoodPreferredStat1 = ACSettings.buffFoodPreferredStat or "Stamina"
		end
		if ACSettings.buffFoodPreferredStat2 == nil then
			ACSettings.buffFoodPreferredStat2 = "Spirit"
		end
			if ACSettings.buffFoodPreferredStat3 == nil then
				ACSettings.buffFoodPreferredStat3 = "None"
			end
			if ACSettings.foodDrinkItemStats == nil then
				ACSettings.foodDrinkItemStats = {}
			end

		local macroButtonNames = {
			"ACFood", -- food
			"ACDrink", -- drink
			"ACBuff", -- buff food
			"ACHealthPotion",
			"ACManaPotion",
			"ACBandage",
		}

		local legacyFoodDrinkMacroNames = {
			[1] = "ACbutton1",
			[2] = "ACbutton2",
			[3] = "ACbutton3",
		}
	
	local tableOfAddOnMacroButtonContentStrings;
	local tableOfAddOnMacroButtonExistanceStatus;
	local tableOfOldMacroButtonNames = {}
	
	local initialAddOnMacroString = "#showtooltip\n/use ";

	-- Setting up string for console output
	local ACADDON_CHAT_TITLE = "|CFF9482C9Automated-Consumables:|r "

	local AC_DEBUG = false

	local updateMacroLater = false;
	local updateMacroNow = false;

	local function getNumberOfMacroButtons()
		return 6;
	end

	local function getContainerNumSlots(bagId)
		if C_Container and C_Container.GetContainerNumSlots then
			return C_Container.GetContainerNumSlots(bagId)
		end
		return GetContainerNumSlots(bagId)
	end

	local function getContainerItemID(bagId, slotIndex)
		if C_Container and C_Container.GetContainerItemID then
			return C_Container.GetContainerItemID(bagId, slotIndex)
		end
		if GetContainerItemID then
			return GetContainerItemID(bagId, slotIndex)
		end
		return nil
	end

	local function getContainerItemLink(bagId, slotIndex)
		if C_Container and C_Container.GetContainerItemLink then
			return C_Container.GetContainerItemLink(bagId, slotIndex)
		end
		if GetContainerItemLink then
			return GetContainerItemLink(bagId, slotIndex)
		end
		return nil
	end

	local function getContainerItemIDFallback(bagId, slotIndex)
		if C_Container and C_Container.GetContainerItemInfo then
			local itemInfo = C_Container.GetContainerItemInfo(bagId, slotIndex)
			return itemInfo and itemInfo.itemID or nil
		end
		if GetContainerItemInfo then
			local itemInfo = GetContainerItemInfo(bagId, slotIndex)
			if type(itemInfo) == "table" then
				return itemInfo.itemID
			end
		end
		return nil
	end

	local itemScanTooltip = CreateFrame("GameTooltip", "AutomatedConsumablesScanTooltip", UIParent, "GameTooltipTemplate")
	itemScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

			local function parseRestoreAmountsFromTooltip(bagId, slotIndex, wantBuffStats)
				itemScanTooltip:ClearLines()
				itemScanTooltip:SetBagItem(bagId, slotIndex)

		local restoresHealth = 0
		local restoresMana = 0
		local requiresSeated = false
		local isWellFed = false
		local mentionsHealth = false
		local mentionsMana = false
		local buffStats = wantBuffStats and {} or nil
		local tooltipLines = itemScanTooltip:NumLines() or 0

		local function parseLocalizedNumber(numText)
			if not numText then
				return nil
			end
			local cleaned = numText:gsub("%.", ""):gsub(",", "")
			return tonumber(cleaned)
		end

		local function maybeRecordBuffStat(statKey, amount)
			if not buffStats or not statKey or not amount or amount <= 0 then
				return
			end
			local prev = buffStats[statKey] or 0
			if amount > prev then
				buffStats[statKey] = amount
			end
		end

			local function parseBuffStatsFromText(lowerText)
				if not buffStats or not lowerText or lowerText == "" then
					return
				end

			local function tryStat(statKey, needleLower)
				local numText = lowerText:match("([%d%.,]+)%s+" .. needleLower)
				local amount = parseLocalizedNumber(numText)
				if not amount then
					numText = lowerText:match(needleLower .. ".-by%s+([%d%.,]+)")
					amount = parseLocalizedNumber(numText)
				end
				if not amount then
					numText = lowerText:match(needleLower .. ".-um%s+([%d%.,]+)")
					amount = parseLocalizedNumber(numText)
				end
				maybeRecordBuffStat(statKey, amount)
				return amount
			end

				local staminaAmount = tryStat("Stamina", "stamina") or tryStat("Stamina", "ausdauer")
				local spiritAmount = tryStat("Spirit", "spirit") or tryStat("Spirit", "willenskraft")
				local ignored = tryStat("Strength", "strength") or tryStat("Strength", "stärke")
				ignored = tryStat("Agility", "agility") or tryStat("Agility", "beweglichkeit")
				ignored = tryStat("Intellect", "intellect") or tryStat("Intellect", "intelligenz")

				if staminaAmount and (not spiritAmount or spiritAmount <= 0) then
					local hasSpiritWord = lowerText:find("spirit", 1, true) or lowerText:find("willenskraft", 1, true)
					local hasSpiritNumber = lowerText:match("([%d%.,]+)%s+spirit") or lowerText:match("([%d%.,]+)%s+willenskraft")
					if hasSpiritWord and not hasSpiritNumber then
						maybeRecordBuffStat("Spirit", staminaAmount)
					end
				end

				if isWellFed == false and next(buffStats) ~= nil then
					isWellFed = true
				end
			end

		local function applyTooltipText(text)
			if not text or text == "" then
				return
			end

			local seatedNeedle = _G.ITEM_MUST_REMAIN_SEATED
			if seatedNeedle and seatedNeedle ~= "" and text:find(seatedNeedle, 1, true) then
				requiresSeated = true
			end

			local lowerText = text:lower()
			if lowerText:find("must remain seated", 1, true) then
				requiresSeated = true
			end
			if lowerText:find("ihr müsst sitzen bleiben", 1, true) or lowerText:find("ihr müsst sitzen", 1, true) then
				requiresSeated = true
			end

			if lowerText:find("well fed", 1, true) then
				isWellFed = true
			end
			if lowerText:find("wohlgenährt", 1, true) or lowerText:find("satt", 1, true) then
				isWellFed = true
			end
			if lowerText:find("bien nourri", 1, true) then
				isWellFed = true
			end
			if wantBuffStats then
				parseBuffStatsFromText(lowerText)
			end

			local healthNeedleLower = _G.HEALTH and _G.HEALTH:lower() or nil
			local manaNeedleLower = _G.MANA and _G.MANA:lower() or nil
			local hasHealthWord = healthNeedleLower and lowerText:find(healthNeedleLower, 1, true)
			local hasManaWord = manaNeedleLower and lowerText:find(manaNeedleLower, 1, true)

			if hasHealthWord or hasManaWord then
				if hasHealthWord then
					mentionsHealth = true
				end
				if hasManaWord then
					mentionsMana = true
				end

				local numbers = {}
				for num in text:gmatch("([%d%.,]+)") do
					table.insert(numbers, num)
				end

				if hasHealthWord and hasManaWord and #numbers >= 2 then
					restoresHealth = parseLocalizedNumber(numbers[1]) or restoresHealth
					restoresMana = parseLocalizedNumber(numbers[2]) or restoresMana
				elseif hasHealthWord and #numbers >= 1 then
					restoresHealth = parseLocalizedNumber(numbers[1]) or restoresHealth
				elseif hasManaWord and #numbers >= 1 then
					restoresMana = parseLocalizedNumber(numbers[1]) or restoresMana
				end
			end
		end

		for lineIndex = 2, itemScanTooltip:NumLines() do
			local leftLine = _G["AutomatedConsumablesScanTooltipTextLeft" .. lineIndex]
			local rightLine = _G["AutomatedConsumablesScanTooltipTextRight" .. lineIndex]
			applyTooltipText(leftLine and leftLine:GetText() or nil)
			applyTooltipText(rightLine and rightLine:GetText() or nil)
		end

			return restoresHealth, restoresMana, requiresSeated, isWellFed, tooltipLines, mentionsHealth, mentionsMana, buffStats
		end

		local function getFoodDrinkStatsFromDB(itemID)
			if not itemID then
				return nil
			end
			if type(_G.AC_FOOD_ITEMS) == "table" then
				local s = _G.AC_FOOD_ITEMS[itemID]
				if type(s) == "table" then
					return { h = s.h or 0, m = s.m or 0, wf = false, bs = nil, kind = "food" }
				end
			end
			if type(_G.AC_DRINK_ITEMS) == "table" then
				local s = _G.AC_DRINK_ITEMS[itemID]
				if type(s) == "table" then
					return { h = s.h or 0, m = s.m or 0, wf = false, bs = nil, kind = "drink" }
				end
			end
			if type(_G.AC_BUFFFOOD_ITEMS) == "table" then
				for _, statBucket in pairs(_G.AC_BUFFFOOD_ITEMS) do
					if type(statBucket) == "table" then
						local s = statBucket[itemID]
						if type(s) == "table" then
							return { h = s.h or 0, m = s.m or 0, wf = true, bs = s.bs, kind = "buff" }
						end
					end
				end
			end
			local static = type(_G.AC_FOODDRINK_ITEM_STATS) == "table" and _G.AC_FOODDRINK_ITEM_STATS[itemID] or nil
			if static then
				return static
			end
			local cached = type(ACSettings) == "table"
				and type(ACSettings.foodDrinkItemStats) == "table"
				and ACSettings.foodDrinkItemStats[itemID]
				or nil
			return cached
		end

		local function foodDrinkDBOnlyEnabled()
			return true
		end

		local function pickBestAvailableFoodDrinkItemID(predicate)
			local statsTable = type(_G.AC_FOODDRINK_ITEM_STATS) == "table" and _G.AC_FOODDRINK_ITEM_STATS or nil
			if not statsTable then
				return nil
			end
			local bestItemID = nil
			local bestScore = -1
			for itemID, stats in pairs(statsTable) do
				if type(itemID) == "number" and type(stats) == "table" then
					local count = GetItemCount and GetItemCount(itemID) or 0
					if count and count > 0 then
						if not predicate or predicate(itemID, stats) then
							local score = (stats.h or 0) + (stats.m or 0)
							if score > bestScore or (score == bestScore and (not bestItemID or itemID > bestItemID)) then
								bestScore = score
								bestItemID = itemID
							end
						end
					end
				end
			end
			return bestItemID
		end

		local function pickBestBuffFoodByPreferredStats(preferredStat1, preferredStat2, preferredStat3)
			local statsTable = type(_G.AC_FOODDRINK_ITEM_STATS) == "table" and _G.AC_FOODDRINK_ITEM_STATS or nil
			if not statsTable then
				return nil
			end
			local bestItemID = nil
			local bestA1, bestA2, bestA3, bestRestore = -1, -1, -1, -1

			for itemID, stats in pairs(statsTable) do
				if type(itemID) == "number" and type(stats) == "table" then
					local isBuff = stats.wf == true or (type(stats.bs) == "table" and next(stats.bs) ~= nil)
					if isBuff then
						local count = GetItemCount and GetItemCount(itemID) or 0
						if count and count > 0 then
							local bs = type(stats.bs) == "table" and stats.bs or nil
							local a1 = (bs and preferredStat1) and (bs[preferredStat1] or 0) or 0
							local a2 = (bs and preferredStat2) and (bs[preferredStat2] or 0) or 0
							local a3 = (bs and preferredStat3) and (bs[preferredStat3] or 0) or 0
							local restore = (stats.h or 0) + (stats.m or 0)
							if a1 > bestA1
								or (a1 == bestA1 and a2 > bestA2)
								or (a1 == bestA1 and a2 == bestA2 and a3 > bestA3)
								or (a1 == bestA1 and a2 == bestA2 and a3 == bestA3 and restore > bestRestore)
								or (a1 == bestA1 and a2 == bestA2 and a3 == bestA3 and restore == bestRestore and (not bestItemID or itemID > bestItemID))
							then
								bestA1, bestA2, bestA3, bestRestore = a1, a2, a3, restore
								bestItemID = itemID
							end
						end
					end
				end
			end

			return bestItemID
		end

		local function rememberFoodDrinkStats(itemID, restoresHealth, restoresMana, isWellFed, mentionsHealth, mentionsMana, buffStats)
			if not itemID or itemID <= 0 then
				return
			end
			if type(ACSettings) ~= "table" or type(ACSettings.foodDrinkItemStats) ~= "table" then
				return
			end
			if (restoresHealth or 0) <= 0 and (restoresMana or 0) <= 0 and not isWellFed and (not buffStats or not next(buffStats)) then
				return
			end
			ACSettings.foodDrinkItemStats[itemID] = {
				h = restoresHealth or 0,
				m = restoresMana or 0,
				wf = isWellFed and true or false,
				mh = mentionsHealth and true or false,
				mm = mentionsMana and true or false,
				bs = buffStats,
			}
		end

	local function itemIsConsumable(itemID)
		if C_Item and C_Item.GetItemInfoInstant then
			local _, _, _, _, _, classID = C_Item.GetItemInfoInstant(itemID)
			return classID == 0
		end
		if GetItemInfoInstant then
			local _, _, _, _, _, classID = GetItemInfoInstant(itemID)
			return classID == 0
		end
		local _, _, _, _, _, itemType = GetItemInfo(itemID)
		return itemType == "Consumable" or itemType == "Verbrauchbar"
	end

	local function getItemClassInfo(itemID)
		if C_Item and C_Item.GetItemInfoInstant then
			local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
			return classID, subClassID
		end
		if GetItemInfoInstant then
			local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
			return classID, subClassID
		end
		local _, _, _, _, _, _, _, _, _, _, _, classID, subClassID = GetItemInfo(itemID)
		return classID, subClassID
	end

	local function itemIsFoodOrDrink(itemID)
		if type(_G.AC_FOOD_DRINK_ITEM_IDS) == "table" and _G.AC_FOOD_DRINK_ITEM_IDS[itemID] then
			return true
		end
		if type(_G.AC_DRINK_ITEM_IDS) == "table" and _G.AC_DRINK_ITEM_IDS[itemID] then
			return true
		end
		if type(_G.AC_FOOD_ITEM_IDS) == "table" and _G.AC_FOOD_ITEM_IDS[itemID] then
			return true
		end
		if type(_G.AC_BUFFFOOD_ITEM_IDS) == "table" and _G.AC_BUFFFOOD_ITEM_IDS[itemID] then
			return true
		end

		if C_Item and C_Item.GetItemInfoInstant then
			local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
			if classID == 0 and subClassID == 5 then
				return true
			end
		end

		if GetItemInfoInstant then
			local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
			if classID == 0 and subClassID == 5 then
				return true
			end
		end

		local _, _, _, _, _, itemType, itemSubType, _, _, _, _, classID, subClassID = GetItemInfo(itemID)
		if classID == 0 and subClassID == 5 then
			return true
		end
		return itemType == "Consumable" and itemSubType == "Food & Drink"
	end

			local function scanBagsForBestConsumables()
				if foodDrinkDBOnlyEnabled() then
					local buffFoodPreferenceMode = ACSettings and ACSettings.buffFoodPreferenceMode or "restore"
					local preferredStat1 = ACSettings and ACSettings.buffFoodPreferredStat1 or nil
					local preferredStat2 = ACSettings and ACSettings.buffFoodPreferredStat2 or nil
					local preferredStat3 = ACSettings and ACSettings.buffFoodPreferredStat3 or nil

					local function normalizeStat(stat)
						if not stat or stat == "" or stat == "None" then
							return nil
						end
						return stat
					end
					preferredStat1 = normalizeStat(preferredStat1)
					preferredStat2 = normalizeStat(preferredStat2)
					preferredStat3 = normalizeStat(preferredStat3)
					if preferredStat2 == preferredStat1 then
						preferredStat2 = nil
					end
					if preferredStat3 == preferredStat1 or preferredStat3 == preferredStat2 then
						preferredStat3 = nil
					end

					local bestSimpleFoodItemID = pickBestAvailableFoodDrinkItemID(function(itemID, stats)
						if type(_G.AC_FOOD_ITEM_IDS) == "table" and _G.AC_FOOD_ITEM_IDS[itemID] then
							return true
						end
						if stats.kind == "food" then
							return true
						end
						if stats.kind == "both" then
							return (stats.h or 0) > 0
						end
						return (stats.h or 0) > 0 and (stats.m or 0) == 0 and stats.wf ~= true
					end)

					local bestDrinkItemID = pickBestAvailableFoodDrinkItemID(function(itemID, stats)
						if type(_G.AC_DRINK_ITEM_IDS) == "table" and _G.AC_DRINK_ITEM_IDS[itemID] then
							return true
						end
						if stats.kind == "drink" then
							return true
						end
						if stats.kind == "both" then
							return (stats.m or 0) > 0
						end
						return (stats.m or 0) > 0 and (stats.h or 0) == 0
					end)

					local bestBuffFoodItemID = nil
					if buffFoodPreferenceMode == "stat" and preferredStat1 ~= nil then
						bestBuffFoodItemID = pickBestBuffFoodByPreferredStats(preferredStat1, preferredStat2, preferredStat3)
					end
					if not bestBuffFoodItemID then
						bestBuffFoodItemID = pickBestAvailableFoodDrinkItemID(function(itemID, stats)
							if type(_G.AC_BUFFFOOD_ITEM_IDS) == "table" and _G.AC_BUFFFOOD_ITEM_IDS[itemID] then
								return true
							end
							return stats.wf == true or stats.kind == "buff" or (type(stats.bs) == "table" and next(stats.bs) ~= nil)
						end)
					end

					return bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID
				end

				local bestSimpleFoodItemID = nil
				local bestDrinkItemID = nil
				local bestBuffFoodItemID = nil
			local bestPreferredBuffFoodItemID = nil
			local bestFoodAndDrinkItemID = nil
			local bestAnyUsableFoodOrDrinkItemID = nil
			local bestAnyUsableFoodItemID = nil
			local bestAnyUsableDrinkItemID = nil
			local bestSimpleFoodScore = -1
			local bestDrinkScore = -1
			local bestBuffFoodScore = -1
			local bestPreferredBuffFoodStatAmount = -1
			local bestPreferredBuffFoodRestoreScore = -1
			local bestPreferredBuffFoodStatAmount2 = -1
			local bestPreferredBuffFoodStatAmount3 = -1
			local bestFoodAndDrinkScore = -1

			local buffFoodPreferenceMode = ACSettings and ACSettings.buffFoodPreferenceMode or "restore"
			local preferredStat1 = ACSettings and ACSettings.buffFoodPreferredStat1 or nil
			local preferredStat2 = ACSettings and ACSettings.buffFoodPreferredStat2 or nil
			local preferredStat3 = ACSettings and ACSettings.buffFoodPreferredStat3 or nil

			local function normalizeStat(stat)
				if not stat or stat == "" or stat == "None" then
					return nil
				end
				return stat
			end

			preferredStat1 = normalizeStat(preferredStat1)
			preferredStat2 = normalizeStat(preferredStat2)
			preferredStat3 = normalizeStat(preferredStat3)
			if preferredStat2 == preferredStat1 then
				preferredStat2 = nil
			end
			if preferredStat3 == preferredStat1 or preferredStat3 == preferredStat2 then
				preferredStat3 = nil
			end

							local wantBuffStats = buffFoodPreferenceMode == "stat" and preferredStat1 ~= nil

			local debugCandidatesPrinted = 0
			for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
				local numSlots = getContainerNumSlots(bagId) or 0
				for slotIndex = 1, numSlots do
				local itemID = getContainerItemID(bagId, slotIndex)
				if not itemID then
					itemID = getContainerItemIDFallback(bagId, slotIndex)
					end
					if itemID then
							local restoresHealth, restoresMana, requiresSeated, isWellFed, tooltipLines, mentionsHealth, mentionsMana, buffStats
							local db = getFoodDrinkStatsFromDB(itemID)
							if db then
								restoresHealth = db.h or 0
								restoresMana = db.m or 0
								requiresSeated = false
								isWellFed = db.wf and true or false
								tooltipLines = 1
								mentionsHealth = db.mh ~= nil and db.mh or (restoresHealth > 0)
								mentionsMana = db.mm ~= nil and db.mm or (restoresMana > 0)
								buffStats = (wantBuffStats and type(db.bs) == "table") and db.bs or nil
							else
								restoresHealth, restoresMana, requiresSeated, isWellFed, tooltipLines, mentionsHealth, mentionsMana, buffStats =
									parseRestoreAmountsFromTooltip(bagId, slotIndex, wantBuffStats)
								rememberFoodDrinkStats(itemID, restoresHealth, restoresMana, isWellFed, mentionsHealth, mentionsMana, buffStats)
							end
						local classID, subClassID = getItemClassInfo(itemID)
						local isFoodOrDrink = itemIsFoodOrDrink(itemID)
							or ((classID == 0 and subClassID == 0) and requiresSeated)

					if isFoodOrDrink then
						if AC_DEBUG and debugCandidatesPrinted < 10 then
							local itemName = GetItemInfo(itemID)
							print(string.format(
								"%sCandidate: %s (item:%d) seated=%s hp=%d mana=%d mH=%s mM=%s lines=%d",
								ACADDON_CHAT_TITLE,
								tostring(itemName),
								itemID,
								tostring(requiresSeated),
								restoresHealth,
								restoresMana,
								tostring(mentionsHealth),
								tostring(mentionsMana),
								tooltipLines
							))
							debugCandidatesPrinted = debugCandidatesPrinted + 1
						end

						local usable = (not IsUsableItem) or IsUsableItem(itemID)
						if usable and not bestAnyUsableFoodOrDrinkItemID then
							bestAnyUsableFoodOrDrinkItemID = itemID
						end

							local forcedDrink = type(_G.AC_DRINK_ITEM_IDS) == "table" and _G.AC_DRINK_ITEM_IDS[itemID]
							local forcedFood = type(_G.AC_FOOD_ITEM_IDS) == "table" and _G.AC_FOOD_ITEM_IDS[itemID]
								local forcedBuffFood = type(_G.AC_BUFFFOOD_ITEM_IDS) == "table" and _G.AC_BUFFFOOD_ITEM_IDS[itemID]
								local isBuffFood = forcedBuffFood or isWellFed or (wantBuffStats and buffStats and next(buffStats) ~= nil)
								local treatAsDrink = forcedDrink or (restoresMana > 0 and restoresHealth == 0)
								local treatAsSimpleFood = forcedFood or (restoresHealth > 0 and restoresMana == 0 and not isBuffFood)
								local treatAsAnyDrink = treatAsDrink or (mentionsMana and not mentionsHealth and not forcedFood)
								local treatAsAnyFood = treatAsSimpleFood or (mentionsHealth and not mentionsMana and not forcedDrink)

							if usable and treatAsAnyDrink and not bestAnyUsableDrinkItemID then
								bestAnyUsableDrinkItemID = itemID
							end
							if usable and treatAsAnyFood and not bestAnyUsableFoodItemID then
								bestAnyUsableFoodItemID = itemID
							end

								local score = restoresHealth + restoresMana

								if isBuffFood and score > 0 and score > bestBuffFoodScore then
									bestBuffFoodScore = score
									bestBuffFoodItemID = itemID
								end

								if wantBuffStats and isBuffFood and score > 0 then
									local a1 = (buffStats and preferredStat1) and (buffStats[preferredStat1] or 0) or 0
									local a2 = (buffStats and preferredStat2) and (buffStats[preferredStat2] or 0) or 0
									local a3 = (buffStats and preferredStat3) and (buffStats[preferredStat3] or 0) or 0
									if a1 > 0 or a2 > 0 or a3 > 0 then
										if a1 > bestPreferredBuffFoodStatAmount
											or (a1 == bestPreferredBuffFoodStatAmount and a2 > bestPreferredBuffFoodStatAmount2)
											or (a1 == bestPreferredBuffFoodStatAmount and a2 == bestPreferredBuffFoodStatAmount2 and a3 > bestPreferredBuffFoodStatAmount3)
											or (a1 == bestPreferredBuffFoodStatAmount and a2 == bestPreferredBuffFoodStatAmount2 and a3 == bestPreferredBuffFoodStatAmount3 and score > bestPreferredBuffFoodRestoreScore)
										then
											bestPreferredBuffFoodStatAmount = a1
											bestPreferredBuffFoodStatAmount2 = a2
											bestPreferredBuffFoodStatAmount3 = a3
											bestPreferredBuffFoodRestoreScore = score
											bestPreferredBuffFoodItemID = itemID
										end
									end
								elseif restoresHealth > 0 and restoresMana > 0 and score > bestFoodAndDrinkScore then
									bestFoodAndDrinkScore = score
									bestFoodAndDrinkItemID = itemID
								elseif treatAsSimpleFood and restoresHealth > bestSimpleFoodScore then
								bestSimpleFoodScore = restoresHealth
								bestSimpleFoodItemID = itemID
							elseif treatAsDrink and restoresMana > bestDrinkScore then
								bestDrinkScore = restoresMana
								bestDrinkItemID = itemID
							end
					end
					end
				end
			end

				if bestPreferredBuffFoodItemID then
					bestBuffFoodItemID = bestPreferredBuffFoodItemID
				end

				return bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID, bestFoodAndDrinkItemID, bestAnyUsableFoodOrDrinkItemID, bestAnyUsableFoodItemID, bestAnyUsableDrinkItemID
			end

	local function buildSortedItemIDListFromSet(setTable)
		if type(setTable) ~= "table" then
			return {}
		end
		local list = {}
		for itemID in pairs(setTable) do
			if type(itemID) == "number" then
				list[#list + 1] = itemID
			end
		end
		table.sort(list)
		return list
	end

		local healthPotionItemIDs = buildSortedItemIDListFromSet(_G.AC_HEALTH_POTION_ITEM_IDS)
		local healthstoneItemIDs = buildSortedItemIDListFromSet(_G.AC_HEALTHSTONE_ITEM_IDS)
		local manaPotionItemIDs = buildSortedItemIDListFromSet(_G.AC_MANA_POTION_ITEM_IDS)
		local manaAgateItemIDs = buildSortedItemIDListFromSet(_G.AC_MANAAGATE_ITEM_IDS)
		local bandageItemIDs = buildSortedItemIDListFromSet(_G.AC_BANDAGE_ITEM_IDS)

	local function findBestUsableItemIDFromSortedList(sortedItemIDs)
		for i = #sortedItemIDs, 1, -1 do
			local itemID = sortedItemIDs[i]
			local count = GetItemCount(itemID)
			if count and count > 0 then
				if not IsUsableItem or IsUsableItem(itemID) then
					return itemID
				end
			end
		end
		return nil
	end

	local function findBestUsableItemIDInBagsByNameNeedle(nameNeedleLower)
		if not nameNeedleLower or nameNeedleLower == "" then
			return nil
		end

		local bestItemID = nil
		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			for slotIndex = 1, numSlots do
				local itemID = getContainerItemID(bagId, slotIndex) or getContainerItemIDFallback(bagId, slotIndex)
				if itemID then
					local itemName = GetItemInfo(itemID)
					if itemName and itemName ~= "" then
						if itemName:lower():find(nameNeedleLower, 1, true) then
							if not IsUsableItem or IsUsableItem(itemID) then
								if not bestItemID or itemID > bestItemID then
									bestItemID = itemID
								end
							end
						end
					end
				end
			end
		end
		return bestItemID
	end

		local function findBestHealthstoneItemID()
			return findBestUsableItemIDFromSortedList(healthstoneItemIDs)
				or findBestUsableItemIDInBagsByNameNeedle("healthstone")
		end

	local function buildUseItemMacro(itemID, targetPlayer)
		if not itemID then
			return initialAddOnMacroString .. "\n"
		end
		if targetPlayer then
			return string.format("#showtooltip item:%d\n/use [@player] item:%d\n", itemID, itemID)
		end
		return string.format("#showtooltip item:%d\n/use item:%d\n", itemID, itemID)
	end

	local function getContainerItemCooldown(bagId, slotIndex)
		if C_Container and C_Container.GetContainerItemCooldown then
			return C_Container.GetContainerItemCooldown(bagId, slotIndex)
		end
		if GetContainerItemCooldown then
			return GetContainerItemCooldown(bagId, slotIndex)
		end
		return nil, nil, nil
	end

	local function getCooldownForItemIDFromBags(itemID)
		if not itemID then
			return nil, nil, nil
		end
		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			for slotIndex = 1, numSlots do
				local slotItemID = getContainerItemID(bagId, slotIndex) or getContainerItemIDFallback(bagId, slotIndex)
				if slotItemID == itemID then
					return getContainerItemCooldown(bagId, slotIndex)
				end
			end
		end
		return nil, nil, nil
	end

	local function itemIsOnCooldown(itemID)
		if not itemID or not GetItemCooldown then
			return false
		end
		local startTime, duration, enable = GetItemCooldown(itemID)
		if (not startTime) or (not duration) then
			startTime, duration, enable = getCooldownForItemIDFromBags(itemID)
		end

		if not startTime or enable == 0 then
			return false
		end
		if startTime <= 0 then
			return false
		end
		if not duration or duration <= 0 then
			return true
		end
		return (startTime + duration - GetTime()) > 0
	end

		local function buildHealthstoneOrPotionMacro(healthstoneItemID, healthPotionItemID)
			if not healthstoneItemID and not healthPotionItemID then
				return initialAddOnMacroString .. "\n"
			end

		local stoneOnCooldown = itemIsOnCooldown(healthstoneItemID)
		local potionOnCooldown = itemIsOnCooldown(healthPotionItemID)

		local firstItemID = nil
		local secondItemID = nil

		if healthstoneItemID and not stoneOnCooldown then
			firstItemID = healthstoneItemID
			secondItemID = healthPotionItemID
		elseif healthPotionItemID and not potionOnCooldown then
			firstItemID = healthPotionItemID
			secondItemID = healthstoneItemID
		else
			firstItemID = healthstoneItemID or healthPotionItemID
			secondItemID = (firstItemID == healthstoneItemID) and healthPotionItemID or healthstoneItemID
		end

		if secondItemID then
			return string.format(
				"#showtooltip item:%d\n/use item:%d\n/use item:%d\n",
				firstItemID,
				firstItemID,
				secondItemID
			)
		end

			return buildUseItemMacro(firstItemID, false)
		end

		local function buildManaAgateOrPotionMacro(manaAgateItemID, manaPotionItemID)
			if not manaAgateItemID and not manaPotionItemID then
				return initialAddOnMacroString .. "\n"
			end

			local agateOnCooldown = itemIsOnCooldown(manaAgateItemID)
			local potionOnCooldown = itemIsOnCooldown(manaPotionItemID)

			local firstItemID = nil
			local secondItemID = nil

			if manaAgateItemID and not agateOnCooldown then
				firstItemID = manaAgateItemID
				secondItemID = manaPotionItemID
			elseif manaPotionItemID and not potionOnCooldown then
				firstItemID = manaPotionItemID
				secondItemID = manaAgateItemID
			else
				firstItemID = manaAgateItemID or manaPotionItemID
				secondItemID = (firstItemID == manaAgateItemID) and manaPotionItemID or manaAgateItemID
			end

			if secondItemID then
				return string.format(
					"#showtooltip item:%d\n/use item:%d\n/use item:%d\n",
					firstItemID,
					firstItemID,
					secondItemID
				)
			end

			return buildUseItemMacro(firstItemID, false)
		end

			local function buildMacroStringForButton(macroButtonNumber)
				if macroButtonNumber <= 3 then
					local bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID = scanBagsForBestConsumables()

					local itemID = nil
					local kind = nil

					if macroButtonNumber == 1 then
						itemID = bestSimpleFoodItemID
						kind = "Food"
					elseif macroButtonNumber == 2 then
						itemID = bestDrinkItemID
						kind = "Drink"
					elseif macroButtonNumber == 3 then
						itemID = bestBuffFoodItemID
						kind = "Buff Food"
					end

					if not itemID then
						if AC_DEBUG then
							local macroName = macroButtonNames[macroButtonNumber] or (basicMacroButtonName .. macroButtonNumber)
							print(string.format("%sNo usable %s found in bags for %s", ACADDON_CHAT_TITLE, kind or "item", macroName))
						end
						return initialAddOnMacroString .. "\n"
					end

					return initialAddOnMacroString .. string.format("item:%d\n", itemID)
				end

				if macroButtonNumber == 4 then
					local healthstoneItemID = findBestHealthstoneItemID()
					local healthPotionItemID = findBestUsableItemIDFromSortedList(healthPotionItemIDs)
					return buildHealthstoneOrPotionMacro(healthstoneItemID, healthPotionItemID)
				end

					if macroButtonNumber == 5 then
						local manaAgateItemID = findBestUsableItemIDFromSortedList(manaAgateItemIDs)
						local manaPotionItemID = findBestUsableItemIDFromSortedList(manaPotionItemIDs)
						return buildManaAgateOrPotionMacro(manaAgateItemID, manaPotionItemID)
					end

				if macroButtonNumber == 6 then
					return buildUseItemMacro(findBestUsableItemIDFromSortedList(bandageItemIDs), true)
				end

				return initialAddOnMacroString .. "\n"
			end

	local function playerLoggedIn(event)
		return event == "PLAYER_LOGIN";
	end

	local function playerEnteringWorld(event)
		return event == "PLAYER_ENTERING_WORLD"
	end

	local function playerAlive(event)
		return event == "PLAYER_ALIVE"
	end

	local function spellsChanged(event)
		return event == "SPELLS_CHANGED"
	end

			local function forcedUpdate(event)
				return event == "AC_FORCE_UPDATE" or event == "AC_INITIAL_UPDATE" or event == "AC_HOVER_UPDATE" or event == "AC_CAST_UPDATE"
			end

		local lastCastMacroRefreshAt = 0
		local castMacroRefreshCooldownSeconds = 2

		local function shouldRefreshMacrosOnCast()
			if not GetTime then
				return false
			end
			if InCombatLockdown and InCombatLockdown() then
				return false
			end
			local now = GetTime()
			if (now - lastCastMacroRefreshAt) < castMacroRefreshCooldownSeconds then
				return false
			end
			lastCastMacroRefreshAt = now
			return true
		end

			local function onLogin(event)
				if event == "PLAYER_LOGIN" then
					print(string.format("%sLoaded.", ACADDON_CHAT_TITLE))
				end
			end

				local uiInitialized = false
				local acMacroPanel = nil
				local acMacroPanelButtons = {}
				local getMacroIndexByNameSafe
				local acMinimapButton = nil
					local acOptionsPanel = nil
					local acOptionsCategoryID = nil
					local didInitialMacroRefresh = false
					local initialMacroRefreshScheduled = false
					local initialMacroRefreshTicker = nil
					local initialMacroRefreshTicksLeft = 0
					local initialMacroRefreshStartedAt = 0
					local initialMacroRefreshMaxSeconds = 60
					local bagOpenHooksInstalled = false
						local createMinimapButton
							local lastHoverMacroRefreshAt = 0
							local hoverMacroRefreshCooldownSeconds = 2
							local lastBagOpenMacroRefreshAt = 0
							local bagOpenMacroRefreshCooldownSeconds = 1

						local function requestHoverMacroRefresh()
						if not GetTime then
							return
						end
						local now = GetTime()
					if (now - lastHoverMacroRefreshAt) < hoverMacroRefreshCooldownSeconds then
						return
					end
					lastHoverMacroRefreshAt = now

					if AutomatedConsumablesFrame and AutomatedConsumablesFrame.GetScript then
						local handler = AutomatedConsumablesFrame:GetScript("OnEvent")
						if handler then
							handler(AutomatedConsumablesFrame, "AC_HOVER_UPDATE")
						end
					end
				end

				local function requestBagOpenMacroRefresh()
					if not GetTime then
						return
					end
					local now = GetTime()
					if (now - lastBagOpenMacroRefreshAt) < bagOpenMacroRefreshCooldownSeconds then
						return
					end
					lastBagOpenMacroRefreshAt = now

									if AutomatedConsumablesFrame and AutomatedConsumablesFrame.GetScript then
										local handler = AutomatedConsumablesFrame:GetScript("OnEvent")
										if handler then
											handler(AutomatedConsumablesFrame, "AC_INITIAL_UPDATE")
										end
									end
				end

				local function installBagOpenHooksOnce()
					if bagOpenHooksInstalled then
						return
					end
					bagOpenHooksInstalled = true

					local numFrames = _G.NUM_CONTAINER_FRAMES or 13
					for i = 1, numFrames do
						local frame = _G["ContainerFrame" .. i]
						if frame and frame.HookScript then
							frame:HookScript("OnShow", requestBagOpenMacroRefresh)
						end
					end
				end

	local function parseFirstItemIDFromMacroBody(body)
		if not body or body == "" then
			return nil
		end
		local itemIDText = body:match("item:(%d+)")
		return itemIDText and tonumber(itemIDText) or nil
	end

	local function getMacroUpdateTargetFromBody(body)
		local itemID = parseFirstItemIDFromMacroBody(body)
		if not itemID then
			return "empty"
		end
		if GetItemInfo then
			local itemName = GetItemInfo(itemID)
			if itemName and itemName ~= "" then
				return itemName
			end
		end
		return "item:" .. itemID
	end

	local function maybePrintMacroUpdate(macroButtonName, oldBody, newBody)
		if not (ACSettings and ACSettings.showMacroUpdateMessages) then
			return
		end
		local oldItemID = parseFirstItemIDFromMacroBody(oldBody)
		local newItemID = parseFirstItemIDFromMacroBody(newBody)
		if oldItemID == newItemID then
			return
		end
		local targetName = getMacroUpdateTargetFromBody(newBody)
		print(string.format("%s%s Macro has been updated to %s", ACADDON_CHAT_TITLE, macroButtonName, targetName))
	end

	local function getBestIconForMacro(macroIndex)
		if not macroIndex or macroIndex <= 0 then
			return "Interface\\Icons\\INV_Misc_QuestionMark"
		end

		local _, iconTexture, body = GetMacroInfo(macroIndex)
		local itemID = parseFirstItemIDFromMacroBody(body)
		if itemID and GetItemIcon then
			local itemIcon = GetItemIcon(itemID)
			if itemIcon then
				return itemIcon
			end
		end

		return iconTexture or "Interface\\Icons\\INV_Misc_QuestionMark"
	end

		local function refreshMacroPanelButtons()
			if not acMacroPanel then
				return
			end

			for _, button in ipairs(acMacroPanelButtons) do
				local macroIndex = getMacroIndexByNameSafe(button.macroName) or 0
				if button.icon then
					button.icon:SetTexture(getBestIconForMacro(macroIndex))
				end
				button:SetEnabled(macroIndex > 0)
			end
		end

		local function refreshOptionsMacroButtons(optionsPanel)
			if not optionsPanel then
				return
			end
			for _, child in ipairs({ optionsPanel:GetChildren() }) do
				if child and child.macroName and child.icon then
					local macroIndex = getMacroIndexByNameSafe(child.macroName) or 0
					child.icon:SetTexture(getBestIconForMacro(macroIndex))
					child:SetEnabled(macroIndex > 0)
				end
			end
		end

	local function pickupMacroByName(macroName)
		local macroIndex = getMacroIndexByNameSafe(macroName) or 0
		if macroIndex > 0 then
			PickupMacro(macroIndex)
			return true
		end
		return false
	end

		local function toggleMacroPanel()
			if not acMacroPanel then
				return
			end
		if acMacroPanel:IsShown() then
			acMacroPanel:Hide()
		else
			acMacroPanel:SetFrameStrata("DIALOG")
			acMacroPanel:SetFrameLevel(100)
			refreshMacroPanelButtons()
			acMacroPanel:Show()
		end
		end

		local function openOptionsPanel()
			if not acOptionsPanel then
				return
			end

			if Settings and Settings.OpenToCategory and acOptionsCategoryID then
				Settings.OpenToCategory(acOptionsCategoryID)
				return
			end

			if InterfaceOptionsFrame_OpenToCategory then
				InterfaceOptionsFrame_OpenToCategory(acOptionsPanel)
				InterfaceOptionsFrame_OpenToCategory(acOptionsPanel)
			end
		end

		local function updateMinimapButtonVisibility()
			if ACSettings.showMinimapButton then
				if not acMinimapButton then
					createMinimapButton()
				end
				if acMinimapButton then
					acMinimapButton:Show()
				end
			else
				if acMinimapButton then
					acMinimapButton:Hide()
				end
			end
		end

		local function getMacroDefs()
			return {
				{ macroName = "ACFood", label = "Food", tooltip = "Food", choices = "Uses the best food available." },
				{ macroName = "ACDrink", label = "Drink", tooltip = "Drink", choices = "Uses the best drink available." },
				{ macroName = "ACBuff", label = "Buff", tooltip = "Buff Food", choices = "Uses the best buff food available. If Buff food selection is set to Prefer stat, prefers the chosen stat buff. Fallback: if none, uses normal food; then food+drink; then any usable food/drink." },
				{ macroName = "ACHealthPotion", label = "Health", tooltip = "Healthstone / Healing Potion", choices = "Prefers Healthstone (incl. improved variants). Falls back to the best healing potion available." },
				{ macroName = "ACManaPotion", label = "Mana", tooltip = "Mana Potion", choices = "Uses the best mana potion available." },
				{ macroName = "ACBandage", label = "Bandage", tooltip = "Bandage (self)", choices = "Uses the best bandage available on yourself." },
			}
		end

		createMinimapButton = function()
			if acMinimapButton or not Minimap then
				return
			end

			local button = CreateFrame("Button", "ACMinimapButton", Minimap)
			button:SetSize(32, 32)
			button:SetFrameStrata("MEDIUM")
			button:SetFrameLevel((Minimap:GetFrameLevel() or 0) + 1)
			button:SetClampedToScreen(true)
			button:EnableMouse(true)
			button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
			button:SetPoint("TOP", Minimap, "BOTTOM", 0, -4)

			local background = button:CreateTexture(nil, "BACKGROUND")
			background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
			background:SetPoint("TOPLEFT", button, "TOPLEFT", 5, -5)
			background:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -5, 5)

			local border = button:CreateTexture(nil, "OVERLAY")
			border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
			border:SetSize(54, 54)
			border:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)

			local icon = button:CreateTexture(nil, "ARTWORK")
			icon:SetTexture("Interface\\Icons\\INV_Potion_27")
			icon:SetPoint("TOPLEFT", button, "TOPLEFT", 6, -6)
			icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -6, 6)
			icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
			button.icon = icon

			button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
			local highlight = button:GetHighlightTexture()
			if highlight then
				highlight:SetSize(54, 54)
				highlight:SetPoint("CENTER", button, "CENTER", 0, 0)
			end

			button:SetScript("OnClick", function(_, mouseButton)
				if mouseButton == "RightButton" then
					if not uiInitialized then
						initUIOnce()
					end
					openOptionsPanel()
					return
				end
				toggleMacroPanel()
			end)

			button:SetScript("OnMouseDown", function(self)
				if self.icon then
					self.icon:ClearAllPoints()
					self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", 7, -7)
					self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -5, 5)
				end
			end)

			button:SetScript("OnMouseUp", function(self)
				if self.icon then
					self.icon:ClearAllPoints()
					self.icon:SetPoint("TOPLEFT", self, "TOPLEFT", 6, -6)
					self.icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", -6, 6)
				end
			end)

			button:SetScript("OnEnter", function(self)
				GameTooltip:SetOwner(self, "ANCHOR_LEFT")
				GameTooltip:SetText("Automated-Consumables")
				GameTooltip:AddLine("Click: show/hide macro panel", 1, 1, 1)
				GameTooltip:AddLine("Right-click: open options", 1, 1, 1)
				GameTooltip:Show()
			end)

			button:SetScript("OnLeave", function()
				GameTooltip:Hide()
			end)

			acMinimapButton = button
		end

			local function createOptionsPanel()
				if acOptionsPanel then
					return
				end

				local panel = CreateFrame("Frame", "ACOptionsPanel", UIParent)
				panel.name = "Automated-Consumables"

				local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
				title:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
				title:SetText("Automated-Consumables")

				local function forceMacroUpdate()
									if AutomatedConsumablesFrame and AutomatedConsumablesFrame.GetScript then
										local handler = AutomatedConsumablesFrame:GetScript("OnEvent")
										if handler then
											handler(AutomatedConsumablesFrame, "AC_INITIAL_UPDATE")
										end
									end
				end

				local minimapCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
				minimapCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
				minimapCheckbox.Text:SetText("Show minimap button")
				minimapCheckbox:SetChecked(ACSettings.showMinimapButton and true or false)
				minimapCheckbox:SetScript("OnClick", function(self)
					ACSettings.showMinimapButton = self:GetChecked() and true or false
					updateMinimapButtonVisibility()
				end)

				local macroMessageCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
				macroMessageCheckbox:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -8)
				macroMessageCheckbox.Text:SetText("Show macro update messages")
				macroMessageCheckbox:SetChecked(ACSettings.showMacroUpdateMessages and true or false)
				macroMessageCheckbox:SetScript("OnClick", function(self)
					ACSettings.showMacroUpdateMessages = self:GetChecked() and true or false
				end)

				local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
				help:SetPoint("TOPLEFT", macroMessageCheckbox, "BOTTOMLEFT", 0, -16)
				help:SetText("Drag and drop Macro to Bar")

					local macroDefs = getMacroDefs()
					local buttonSize = 96
				local padding = 16
				local cols = 3
				local rows = 2
				local labelPad = 12
				local rowSpacing = buttonSize + padding + labelPad
				local gridWidth = cols * buttonSize + (cols - 1) * padding
				local gridHeight = rows * buttonSize + (rows - 1) * padding + rows * labelPad

				local gridFrame = CreateFrame("Frame", nil, panel)
				gridFrame:SetSize(gridWidth, gridHeight)
				gridFrame:SetPoint("TOPLEFT", help, "BOTTOMLEFT", 0, -8)

				for i = 1, #macroDefs do
						local def = macroDefs[i]
						local button = CreateFrame("Button", "ACOptionsMacroButton" .. i, panel)
						button:SetSize(buttonSize, buttonSize)
						button.macroName = def.macroName

					local col = (i - 1) % cols
					local row = math.floor((i - 1) / cols)
					button:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", col * (buttonSize + padding), -row * rowSpacing)

				button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
				button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
				button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

					local iconBorder = button:CreateTexture(nil, "OVERLAY")
					iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
					iconBorder:SetAllPoints(button)
					button.iconBorder = iconBorder

						local icon = button:CreateTexture(nil, "ARTWORK")
						icon:SetSize(56, 56)
						icon:SetPoint("CENTER", button, "CENTER", 0, 0)
						icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
						icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
						button.icon = icon

						local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormal")
						label:SetPoint("TOP", button, "BOTTOM", 0, -2)
						label:SetText(def.label)

					button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
					button:RegisterForDrag("LeftButton")

				button:SetScript("OnClick", function()
					pickupMacroByName(def.macroName)
				end)

				button:SetScript("OnDragStart", function()
					pickupMacroByName(def.macroName)
				end)

					button:SetScript("OnEnter", function(self)
						requestHoverMacroRefresh()
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						local macroIndex = getMacroIndexByNameSafe(def.macroName) or 0
						if macroIndex > 0 then
							local macroName = GetMacroInfo(macroIndex)
							GameTooltip:SetText(def.tooltip)
						if def.choices then
							GameTooltip:AddLine(def.choices, 0.9, 0.9, 0.9, true)
						end
						GameTooltip:AddLine(macroName or def.macroName, 0.8, 0.8, 0.8)
						GameTooltip:AddLine("Drag to your action bar", 1, 1, 1)
					else
						GameTooltip:SetText(def.tooltip)
						if def.choices then
							GameTooltip:AddLine(def.choices, 0.9, 0.9, 0.9, true)
						end
						GameTooltip:AddLine(def.macroName, 0.8, 0.8, 0.8)
						GameTooltip:AddLine("Macro not found yet. Run /acupdate.", 1, 0.2, 0.2)
					end
					GameTooltip:Show()
				end)

						button:SetScript("OnLeave", function()
							GameTooltip:Hide()
						end)
					end

				local buffPrefLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				buffPrefLabel:SetPoint("TOPLEFT", gridFrame, "BOTTOMLEFT", 0, -16)
				buffPrefLabel:SetText("Buff food selection")

				local buffPrefDropdown = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
				buffPrefDropdown:SetPoint("TOPLEFT", buffPrefLabel, "BOTTOMLEFT", -16, -4)
				UIDropDownMenu_SetWidth(buffPrefDropdown, 220)

				local statLabel = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
				statLabel:SetPoint("TOPLEFT", buffPrefDropdown, "BOTTOMLEFT", 16, -10)
				statLabel:SetText("Preferred stats (priority)")

				local statDropdown1 = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
				statDropdown1:SetPoint("TOPLEFT", statLabel, "BOTTOMLEFT", -16, -4)
				UIDropDownMenu_SetWidth(statDropdown1, 220)

				local statDropdown2 = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
				statDropdown2:SetPoint("TOPLEFT", statDropdown1, "BOTTOMLEFT", 0, -2)
				UIDropDownMenu_SetWidth(statDropdown2, 220)

				local statDropdown3 = CreateFrame("Frame", nil, panel, "UIDropDownMenuTemplate")
				statDropdown3:SetPoint("TOPLEFT", statDropdown2, "BOTTOMLEFT", 0, -2)
				UIDropDownMenu_SetWidth(statDropdown3, 220)

				local function refreshBuffPrefUI()
					local mode = ACSettings and ACSettings.buffFoodPreferenceMode or "restore"
					local preferStat = mode == "stat"
					if statLabel then
						statLabel:SetShown(preferStat)
					end
					if statDropdown1 then
						statDropdown1:SetShown(preferStat)
					end
					if statDropdown2 then
						statDropdown2:SetShown(preferStat)
					end
					if statDropdown3 then
						statDropdown3:SetShown(preferStat)
					end
				end

				local function applyBuffPrefDropdownText()
					local mode = ACSettings and ACSettings.buffFoodPreferenceMode or "restore"
					local text = (mode == "stat") and "Prefer stat" or "Best restore (default)"
					UIDropDownMenu_SetSelectedValue(buffPrefDropdown, mode)
					UIDropDownMenu_SetText(buffPrefDropdown, text)
				end

				local function applyStatDropdownText()
					local stat1 = ACSettings and ACSettings.buffFoodPreferredStat1 or "Stamina"
					local stat2 = ACSettings and ACSettings.buffFoodPreferredStat2 or "Spirit"
					local stat3 = ACSettings and ACSettings.buffFoodPreferredStat3 or "None"
					UIDropDownMenu_SetSelectedValue(statDropdown1, stat1)
					UIDropDownMenu_SetText(statDropdown1, stat1)
					UIDropDownMenu_SetSelectedValue(statDropdown2, stat2)
					UIDropDownMenu_SetText(statDropdown2, stat2)
					UIDropDownMenu_SetSelectedValue(statDropdown3, stat3)
					UIDropDownMenu_SetText(statDropdown3, stat3)
				end

				UIDropDownMenu_Initialize(buffPrefDropdown, function(self, level)
					local current = ACSettings and ACSettings.buffFoodPreferenceMode or "restore"

					local function onPick(button)
						local value = button and button.value
						ACSettings.buffFoodPreferenceMode = value
						applyBuffPrefDropdownText()
						refreshBuffPrefUI()
						forceMacroUpdate()
					end

					local info = UIDropDownMenu_CreateInfo()
					info.text = "Best restore (default)"
					info.value = "restore"
					info.func = onPick
					info.checked = (current == "restore")
					UIDropDownMenu_AddButton(info, level)

					info = UIDropDownMenu_CreateInfo()
					info.text = "Prefer stat"
					info.value = "stat"
					info.func = onPick
					info.checked = (current == "stat")
					UIDropDownMenu_AddButton(info, level)
				end)

				local function initStatDropdown(dropdown, settingsKey)
					UIDropDownMenu_Initialize(dropdown, function(_, level)
						local stats = { "Stamina", "Spirit", "Strength", "Agility", "Intellect", "None" }
						for i = 1, #stats do
							local stat = stats[i]
							local info = UIDropDownMenu_CreateInfo()
							info.text = stat
							info.value = stat
							info.func = function(button)
								local value = button and button.value
								ACSettings[settingsKey] = value
								applyStatDropdownText()
								forceMacroUpdate()
							end
							UIDropDownMenu_AddButton(info, level)
						end
					end)
				end

				initStatDropdown(statDropdown1, "buffFoodPreferredStat1")
				initStatDropdown(statDropdown2, "buffFoodPreferredStat2")
				initStatDropdown(statDropdown3, "buffFoodPreferredStat3")

			panel:SetScript("OnShow", function()
				minimapCheckbox:SetChecked(ACSettings.showMinimapButton and true or false)
				macroMessageCheckbox:SetChecked(ACSettings.showMacroUpdateMessages and true or false)
				applyBuffPrefDropdownText()
				applyStatDropdownText()
				refreshBuffPrefUI()
				refreshOptionsMacroButtons(panel)
			end)

			if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
				local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
				Settings.RegisterAddOnCategory(category)
				if category then
					acOptionsCategoryID = (category.GetID and category:GetID()) or category.ID
				end
			elseif InterfaceOptions_AddCategory then
				InterfaceOptions_AddCategory(panel)
			end

			acOptionsPanel = panel
		end

	local function createMacroPanel()
		if acMacroPanel then
			return
		end

			local panel = CreateFrame("Frame", "ACMacroPanel", UIParent, "BasicFrameTemplateWithInset")
			panel:SetSize(200, 190)
			panel:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			panel:SetClampedToScreen(true)
			panel:SetMovable(true)
			panel:EnableMouse(true)
			panel:SetFrameStrata("DIALOG")
			panel:SetFrameLevel(100)
			panel:Hide()
			panel.TitleText:SetText("Automated-Consumables")

			local function applyBackgroundAlpha(frame, alpha)
				if not frame or not frame.GetRegions then
					return
				end
				local regions = { frame:GetRegions() }
				for i = 1, #regions do
					local region = regions[i]
					if region and region.GetObjectType and region:GetObjectType() == "Texture" then
						local layer = region.GetDrawLayer and region:GetDrawLayer()
						if layer == "BACKGROUND" then
							region:SetAlpha(alpha)
						end
					end
				end
			end

			local panelBackgroundAlpha = 0.7
			applyBackgroundAlpha(panel, panelBackgroundAlpha)
			if panel.Inset then
				applyBackgroundAlpha(panel.Inset, panelBackgroundAlpha)
			end
			if panel.Inset and panel.Inset.Bg then
				panel.Inset.Bg:SetAlpha(panelBackgroundAlpha)
			end
			if panel.Bg then
				panel.Bg:SetAlpha(panelBackgroundAlpha)
			end

			local hintText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
			hintText:SetPoint("TOP", panel, "TOP", 0, -24)
			hintText:SetText("Drag and drop Macro to Bar")
			panel.ACHintText = hintText

			if UISpecialFrames then
				local panelName = panel:GetName()
				if panelName then
					local alreadySpecial = false
					for i = 1, #UISpecialFrames do
						if UISpecialFrames[i] == panelName then
							alreadySpecial = true
							break
						end
					end
					if not alreadySpecial then
						tinsert(UISpecialFrames, panelName)
					end
				end
			end

			panel:RegisterEvent("PLAYER_REGEN_DISABLED")
			panel:SetScript("OnEvent", function(self, event)
				if event == "PLAYER_REGEN_DISABLED" then
					self:Hide()
				end
			end)

			panel:SetScript("OnHide", function(self)
				self:StopMovingOrSizing()
			end)

			local dragFrame = CreateFrame("Frame", nil, panel)
			dragFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
			dragFrame:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
			dragFrame:SetHeight(26)
			dragFrame:EnableMouse(true)
			dragFrame:RegisterForDrag("LeftButton")
			dragFrame:SetScript("OnDragStart", function()
				panel:StartMoving()
			end)
			dragFrame:SetScript("OnDragStop", function()
				panel:StopMovingOrSizing()
			end)

			local macroDefs = getMacroDefs()

			local buttonSize = 52
			local padding = 12
			local cols = 3
			local rows = 2
			local gridWidth = cols * buttonSize + (cols - 1) * padding
			local labelPad = 12
			local gridHeight = rows * buttonSize + (rows - 1) * padding + labelPad

			local contentFrame = panel.Inset or panel
			local gridFrame = CreateFrame("Frame", nil, contentFrame)
			gridFrame:SetSize(gridWidth, gridHeight)
			gridFrame:SetPoint("CENTER", contentFrame, "CENTER", 0, -(labelPad / 2))

			for i = 1, #macroDefs do
				local def = macroDefs[i]
				local button = CreateFrame("Button", "ACMacroPanelButton" .. i, panel)
				button:SetSize(buttonSize, buttonSize)

				local col = (i - 1) % cols
				local row = math.floor((i - 1) / cols)
				button:SetPoint("TOPLEFT", gridFrame, "TOPLEFT", col * (buttonSize + padding), -row * (buttonSize + padding))

				button.macroName = def.macroName

				button:SetNormalTexture("Interface\\Buttons\\UI-Quickslot2")
				button:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
				button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")

				local iconBorder = button:CreateTexture(nil, "OVERLAY")
				iconBorder:SetTexture("Interface\\Buttons\\UI-Quickslot2")
				iconBorder:SetAllPoints(button)
				button.iconBorder = iconBorder

				local icon = button:CreateTexture(nil, "ARTWORK")
				icon:SetSize(32, 32)
				icon:SetPoint("CENTER", button, "CENTER", 0, 0)
				icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
				icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
				button.icon = icon

				button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
				button:RegisterForDrag("LeftButton")

				button:SetScript("OnClick", function()
					pickupMacroByName(def.macroName)
				end)

				button:SetScript("OnDragStart", function()
					pickupMacroByName(def.macroName)
				end)

					button:SetScript("OnEnter", function(self)
						requestHoverMacroRefresh()
						GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
						local macroIndex = getMacroIndexByNameSafe(def.macroName) or 0
						if macroIndex > 0 then
							local macroName = GetMacroInfo(macroIndex)
							GameTooltip:SetText(def.tooltip)
						if def.choices then
							GameTooltip:AddLine(def.choices, 0.9, 0.9, 0.9, true)
						end
						GameTooltip:AddLine(macroName or def.macroName, 0.8, 0.8, 0.8)
						GameTooltip:AddLine("Drag to your action bar", 1, 1, 1)
					else
						GameTooltip:SetText(def.tooltip)
						if def.choices then
							GameTooltip:AddLine(def.choices, 0.9, 0.9, 0.9, true)
						end
						GameTooltip:AddLine(def.macroName, 0.8, 0.8, 0.8)
						GameTooltip:AddLine("Macro not found yet. Run /acupdate.", 1, 0.2, 0.2)
					end
					GameTooltip:Show()
				end)

				button:SetScript("OnLeave", function()
					GameTooltip:Hide()
				end)

				table.insert(acMacroPanelButtons, button)

				local label = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
				label:SetPoint("TOP", button, "BOTTOM", 0, -2)
				label:SetText(def.label)
			end

		acMacroPanel = panel
	end

			local function initUIOnce()
				if uiInitialized then
					return
				end
				uiInitialized = true
				createMacroPanel()
				createOptionsPanel()
				updateMinimapButtonVisibility()
				installBagOpenHooksOnce()
			end
	
	local function bagContentChanged(event)
		return event == "BAG_UPDATE" or event == "BAG_UPDATE_DELAYED";
	end

	local function bagCooldownChanged(event)
		return event == "BAG_UPDATE_COOLDOWN";
	end

	local function bagItemDataLooksReady()
		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			if numSlots > 0 then
				local slotA = 1
				local slotB = math.floor(numSlots / 2)
				if slotB < 1 then
					slotB = 1
				end
				local slotC = numSlots

				local itemID = getContainerItemID(bagId, slotA) or getContainerItemIDFallback(bagId, slotA)
				if itemID then
					return true
				end
				itemID = getContainerItemID(bagId, slotB) or getContainerItemIDFallback(bagId, slotB)
				if itemID then
					return true
				end
				itemID = getContainerItemID(bagId, slotC) or getContainerItemIDFallback(bagId, slotC)
				if itemID then
					return true
				end
			end
		end
		return false
	end

	local function bagTooltipDataLooksReady()
		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			if numSlots > 0 then
				local slotA = 1
				local slotB = math.floor(numSlots / 2)
				if slotB < 1 then
					slotB = 1
				end
				local slotC = numSlots

				local function checkSlot(slotIndex)
					local itemID = getContainerItemID(bagId, slotIndex) or getContainerItemIDFallback(bagId, slotIndex)
					if not itemID then
						return false
					end
					local _, _, _, _, tooltipLines = parseRestoreAmountsFromTooltip(bagId, slotIndex)
					return (tooltipLines or 0) > 0
				end

				if checkSlot(slotA) or checkSlot(slotB) or checkSlot(slotC) then
					return true
				end
			end
		end
		return false
	end

	local function bagLinkDataLooksReady()
		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			if numSlots > 0 then
				local slotA = 1
				local slotB = math.floor(numSlots / 2)
				if slotB < 1 then
					slotB = 1
				end
				local slotC = numSlots

				if getContainerItemLink(bagId, slotA) or getContainerItemLink(bagId, slotB) or getContainerItemLink(bagId, slotC) then
					return true
				end
			end
		end
		return false
	end
	
		local function playerLeftCombat(event)
			return event == "PLAYER_REGEN_ENABLED";
		end


					local function macroNeedsUpdating(event)
						return bagContentChanged(event)
							or bagCooldownChanged(event)
							or forcedUpdate(event)
							or playerAlive(event);
					end
	
	local function playerIsInCombat()
		return InCombatLockdown();
	end
	
	local function markMacroForUpdateLater()
		updateMacroLater = true;
	end

	local function markMacroForUpdateNow()
		updateMacroNow = true;
	end
	
	local function macroWasMarkedForUpdateLater()
		return updateMacroLater;
	end

	local function macroWasMarkedForUpdateNow()
		return updateMacroNow;
	end
	
	local function removeMarkForUpdatingMacroNow()
		updateMacroNow = false;	
	end
	
	local function removeMarkForUpdatingMacroLater()
		updateMacroLater = false;	
	end

	local function determineIfMacroNeedsToBeUpdatedNowOrLater(event)
		removeMarkForUpdatingMacroNow();

		if macroNeedsUpdating(event) then
--				print(string.format("%sUpdate incoming... checking combat", ACADDON_CHAT_TITLE));
			if playerIsInCombat() then
--				print(string.format("%sCannot update macro due to combat lockdown...", ACADDON_CHAT_TITLE));
				markMacroForUpdateLater();
			else
--				print(string.format("%sUpdate confirmed...", ACADDON_CHAT_TITLE));
				markMacroForUpdateNow();
			end
		elseif (playerLeftCombat(event) and macroWasMarkedForUpdateLater()) then  
			markMacroForUpdateNow();
		end	
	end

	local function getAddOnMacroButtonName(macroButtonNumber)
		return macroButtonNames[macroButtonNumber] or (basicMacroButtonName .. macroButtonNumber);
	end

	local function createNewTablesForAddOnMacroButtons()
		tableOfAddOnMacroButtonContentStrings = {};
		tableOfAddOnMacroButtonExistanceStatus = {};
		
		for macroButtonNumber = 1, getNumberOfMacroButtons() do
			local macroButtonName = getAddOnMacroButtonName(macroButtonNumber);
			tableOfAddOnMacroButtonContentStrings[macroButtonName] = "";
			tableOfAddOnMacroButtonExistanceStatus[macroButtonName] = false;
		end
	end

	local function getTotalNumberOfMacros()
		return GetNumMacros();
	end

	local function getMacroName(macroNumber)
		return GetMacroInfo(macroNumber);
	end

	local function getMacroBodyByNameSafe(macroName)
		local macroIndex = 0
		if GetMacroIndexByName then
			macroIndex = GetMacroIndexByName(macroName) or 0
		end
		if macroIndex > 0 then
			local _, _, body = GetMacroInfo(macroIndex)
			return body
		end
		return nil
	end

	getMacroIndexByNameSafe = function(macroName)
		if GetMacroIndexByName then
			return GetMacroIndexByName(macroName)
		end
		return 0
	end
	
	local function indicateThatMacroNameWasFound(addOnMacroName)
		tableOfAddOnMacroButtonExistanceStatus[addOnMacroName] = true;
	end

	local function checkIfMacroNameMatchesAnyOfTheAddOnMacroNames(nameOfMacroToCheck)
		for addOnMacroName, addOnMacroNameFound in pairs(tableOfAddOnMacroButtonExistanceStatus) do
			if nameOfMacroToCheck == addOnMacroName then
				indicateThatMacroNameWasFound(addOnMacroName);
			end
		end
	end

	local function checkIfMacroButtonsAlreadyExist()
		createNewTablesForAddOnMacroButtons();

		for macroNumber=1, getTotalNumberOfMacros() do
			checkIfMacroNameMatchesAnyOfTheAddOnMacroNames(getMacroName(macroNumber));
		end	
	end
	
	local function addStringToMacroButtonString(macroButtonNumber, stringToAdd)
		local macroButtonName = getAddOnMacroButtonName(macroButtonNumber);
		tableOfAddOnMacroButtonContentStrings[macroButtonName] = tableOfAddOnMacroButtonContentStrings[macroButtonName]..stringToAdd;
	end

	local function updateMacroButtonString(macroButtonNumber)
		addStringToMacroButtonString(macroButtonNumber, buildMacroStringForButton(macroButtonNumber));
	end

	local function updateAllMacroStrings()
--		print(string.format("%sUpdating all macro strings", ACADDON_CHAT_TITLE));
		for macrobuttonNumber = 1, getNumberOfMacroButtons() do
			updateMacroButtonString(macrobuttonNumber);
		end

		if AC_DEBUG then
			for macrobuttonNumber = 1, getNumberOfMacroButtons() do
				local macroButtonName = getAddOnMacroButtonName(macrobuttonNumber)
				print(string.format("%s%s body:\n%s", ACADDON_CHAT_TITLE, macroButtonName, tableOfAddOnMacroButtonContentStrings[macroButtonName]))
			end
		end
	end

		local function updateMacro(macroButtonName)
			local macroIndex = getMacroIndexByNameSafe(macroButtonName)
			if macroIndex and macroIndex > 0 then
				local _, _, oldBody = GetMacroInfo(macroIndex)
				local newBody = tableOfAddOnMacroButtonContentStrings[macroButtonName]
				maybePrintMacroUpdate(macroButtonName, oldBody, newBody)
				EditMacro(macroIndex, macroButtonName, nil, tableOfAddOnMacroButtonContentStrings[macroButtonName], nil);
			end
		end

		local function updateOrCreateFoodDrinkBuffMacros()
			local bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID = scanBagsForBestConsumables()
			local itemIDs = { bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID }
			local kinds = { "Food", "Drink", "Buff Food" }
			local foundAny = false

			for macroButtonNumber = 1, 3 do
				local macroButtonName = getAddOnMacroButtonName(macroButtonNumber)
				local itemID = itemIDs[macroButtonNumber]
				local macroBody = nil
				if itemID then
					foundAny = true
					macroBody = initialAddOnMacroString .. string.format("item:%d\n", itemID)
				else
					if AC_DEBUG then
						print(string.format("%sNo usable %s found in bags for %s", ACADDON_CHAT_TITLE, kinds[macroButtonNumber], macroButtonName))
					end
					macroBody = initialAddOnMacroString .. "\n"
				end

				local macroIndex = getMacroIndexByNameSafe(macroButtonName)
				if macroIndex and macroIndex > 0 then
					local _, _, oldBody = GetMacroInfo(macroIndex)
					maybePrintMacroUpdate(macroButtonName, oldBody, macroBody)
					EditMacro(macroIndex, macroButtonName, nil, macroBody, nil)
				else
					local legacyName = legacyFoodDrinkMacroNames[macroButtonNumber]
					if legacyName then
						local legacyIndex = getMacroIndexByNameSafe(legacyName)
						if legacyIndex and legacyIndex > 0 then
							local _, _, oldBody = GetMacroInfo(legacyIndex)
							maybePrintMacroUpdate(macroButtonName, oldBody, macroBody)
							EditMacro(legacyIndex, macroButtonName, nil, macroBody, nil)
						else
							if getTotalNumberOfMacros() < MAX_ACCOUNT_MACROS then
								CreateMacro(macroButtonName, "INV_MISC_QUESTIONMARK", macroBody, nil)
							else
								print(string.format("%sCould not create macro %s. Macro limit reached.", ACADDON_CHAT_TITLE, macroButtonName))
							end
						end
					else
						if getTotalNumberOfMacros() < MAX_ACCOUNT_MACROS then
							CreateMacro(macroButtonName, "INV_MISC_QUESTIONMARK", macroBody, nil)
						else
							print(string.format("%sCould not create macro %s. Macro limit reached.", ACADDON_CHAT_TITLE, macroButtonName))
						end
					end
				end
			end
			return foundAny
		end

	local function createNewMacro(macroButtonName, macrosCreated)
		print(string.format("%sExisting macro ("..macroButtonName..") for Automated-Consumables not found. Creating new one...", ACADDON_CHAT_TITLE));
		if (getTotalNumberOfMacros() + macrosCreated) < MAX_ACCOUNT_MACROS then
			CreateMacro(macroButtonName, "INV_MISC_QUESTIONMARK", tableOfAddOnMacroButtonContentStrings[macroButtonName], nil);
			return true;
		else
			print(string.format("%sCould not create macro "..macroButtonName..". Macro limit reached.", ACADDON_CHAT_TITLE));
			return false;
		end
	end

		local function updateOrCreateSingleMacro(macroButtonNumber)
			local macroButtonName = getAddOnMacroButtonName(macroButtonNumber)
			local macroBody = buildMacroStringForButton(macroButtonNumber)

			local macroIndex = getMacroIndexByNameSafe(macroButtonName)
			if macroIndex and macroIndex > 0 then
				local _, _, oldBody = GetMacroInfo(macroIndex)
				maybePrintMacroUpdate(macroButtonName, oldBody, macroBody)
				EditMacro(macroIndex, macroButtonName, nil, macroBody, nil)
				return
			end

			local legacyName = legacyFoodDrinkMacroNames[macroButtonNumber]
			if legacyName then
				local legacyIndex = getMacroIndexByNameSafe(legacyName)
				if legacyIndex and legacyIndex > 0 then
					local _, _, oldBody = GetMacroInfo(legacyIndex)
					maybePrintMacroUpdate(macroButtonName, oldBody, macroBody)
					EditMacro(legacyIndex, macroButtonName, nil, macroBody, nil)
					return
				end
			end

			if getTotalNumberOfMacros() < MAX_ACCOUNT_MACROS then
				CreateMacro(macroButtonName, "INV_MISC_QUESTIONMARK", macroBody, nil)
			else
				print(string.format("%sCould not create macro %s. Macro limit reached.", ACADDON_CHAT_TITLE, macroButtonName))
			end
		end

		local function migrateLegacyMacroNames()
			for macroButtonNumber = 1, 3 do
				local newName = getAddOnMacroButtonName(macroButtonNumber)
				local legacyName = legacyFoodDrinkMacroNames[macroButtonNumber]
				if legacyName and newName ~= legacyName then
					local newIndex = getMacroIndexByNameSafe(newName) or 0
					if newIndex <= 0 then
						local legacyIndex = getMacroIndexByNameSafe(legacyName) or 0
						if legacyIndex > 0 then
							local legacyBody = getMacroBodyByNameSafe(legacyName) or ""
							EditMacro(legacyIndex, newName, nil, legacyBody, nil)
						end
					end
				end
			end
		end

	local function updateMacrosInGame()
		local macrosCreated = 0;

		for macroButtonName, macroButtonExists in pairs(tableOfAddOnMacroButtonExistanceStatus) do

			if macroButtonExists then
				updateMacro(macroButtonName);
			else
				local macroCreated;
				macroCreated = createNewMacro(macroButtonName, macrosCreated);
				if macroCreated == true then
					macrosCreated = macrosCreated + 1;
				end
			end
		end
		
	end

				local function eventHandlerForAutomatedFoodDrinkMacroScript(self, event, ...)
					local function scheduleInitialMacroRefresh()
						if initialMacroRefreshScheduled then
							return
						end
						initialMacroRefreshScheduled = true

						if not C_Timer or not C_Timer.NewTicker then
							return
						end

						if GetTime and initialMacroRefreshStartedAt == 0 then
							initialMacroRefreshStartedAt = GetTime()
						end

						local function stopTicker()
							if initialMacroRefreshTicker and initialMacroRefreshTicker.Cancel then
								initialMacroRefreshTicker:Cancel()
							end
							initialMacroRefreshTicker = nil
							initialMacroRefreshTicksLeft = 0
						end

							local function kick()
								if didInitialMacroRefresh or initialMacroRefreshTicksLeft <= 0 then
									stopTicker()
									return
								end
								if playerIsInCombat() then
									return
								end
								if not bagLinkDataLooksReady() then
									initialMacroRefreshTicksLeft = initialMacroRefreshTicksLeft - 1
									return
								end
								if AutomatedConsumablesFrame and AutomatedConsumablesFrame.GetScript then
									local handler = AutomatedConsumablesFrame:GetScript("OnEvent")
									if handler then
											handler(AutomatedConsumablesFrame, "AC_INITIAL_UPDATE")
									end
								end
							end

						initialMacroRefreshTicksLeft = 120
						initialMacroRefreshTicker = C_Timer.NewTicker(0.5, kick)
						kick()
					end

						if (event == "PLAYER_LOGIN"
							or event == "PLAYER_ENTERING_WORLD"
							or event == "PLAYER_ALIVE"
							or event == "SPELLS_CHANGED"
							or event == "GET_ITEM_INFO_RECEIVED")
							and not didInitialMacroRefresh
						then
							scheduleInitialMacroRefresh()
						end

				if event == "UNIT_SPELLCAST_SUCCEEDED" then
					local unit = ...
					if unit == "player" and shouldRefreshMacrosOnCast() then
						event = "AC_CAST_UPDATE"
				else
					return
				end
			end

			if event == "PLAYER_LOGIN" then
				initUIOnce()
			elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ALIVE" then
				if uiInitialized then
					updateMinimapButtonVisibility()
				end
			end

		onLogin(event)
		determineIfMacroNeedsToBeUpdatedNowOrLater(event);
		
					if macroWasMarkedForUpdateNow() then
		--				print(string.format("%sUpdating macro", ACADDON_CHAT_TITLE));

						if event == "AC_INITIAL_UPDATE" and not didInitialMacroRefresh then
							migrateLegacyMacroNames()
							local foundAny = updateOrCreateFoodDrinkBuffMacros()
							refreshMacroPanelButtons()
							if acOptionsPanel then
								refreshOptionsMacroButtons(acOptionsPanel)
							end

							local ready = foundAny
							local timedOut = false
							if GetTime and initialMacroRefreshStartedAt and initialMacroRefreshStartedAt > 0 then
								timedOut = (GetTime() - initialMacroRefreshStartedAt) >= initialMacroRefreshMaxSeconds
							end
							if ready or timedOut then
								didInitialMacroRefresh = true
								if initialMacroRefreshTicker and initialMacroRefreshTicker.Cancel then
									initialMacroRefreshTicker:Cancel()
								end
								initialMacroRefreshTicker = nil
								initialMacroRefreshTicksLeft = 0
							end
						elseif bagCooldownChanged(event) and didInitialMacroRefresh then
							updateOrCreateSingleMacro(4)
							else
								migrateLegacyMacroNames()
								checkIfMacroButtonsAlreadyExist();
								updateAllMacroStrings();
								updateMacrosInGame();
									refreshMacroPanelButtons()
									if acOptionsPanel then
										refreshOptionsMacroButtons(acOptionsPanel)
									end
									if not didInitialMacroRefresh then
										local ready = bagTooltipDataLooksReady()
										local timedOut = false
										if GetTime and initialMacroRefreshStartedAt and initialMacroRefreshStartedAt > 0 then
											timedOut = (GetTime() - initialMacroRefreshStartedAt) >= initialMacroRefreshMaxSeconds
										end
										if ready or timedOut then
											didInitialMacroRefresh = true
											if initialMacroRefreshTicker and initialMacroRefreshTicker.Cancel then
												initialMacroRefreshTicker:Cancel()
											end
											initialMacroRefreshTicker = nil
											initialMacroRefreshTicksLeft = 0
										end
									end
								end

							removeMarkForUpdatingMacroLater();
						end
					end

	local function createFrameForAddon()
		AutomatedConsumablesFrame = CreateFrame("Frame");
	end

					local function registerEventsNeededForAddon()
						AutomatedConsumablesFrame:RegisterEvent("PLAYER_LOGIN");
						AutomatedConsumablesFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
						AutomatedConsumablesFrame:RegisterEvent("PLAYER_ALIVE");
						AutomatedConsumablesFrame:RegisterEvent("SPELLS_CHANGED");
						AutomatedConsumablesFrame:RegisterEvent("GET_ITEM_INFO_RECEIVED");
						AutomatedConsumablesFrame:RegisterEvent("BAG_UPDATE");
						AutomatedConsumablesFrame:RegisterEvent("BAG_UPDATE_DELAYED");
						AutomatedConsumablesFrame:RegisterEvent("BAG_UPDATE_COOLDOWN");
						AutomatedConsumablesFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player");
						AutomatedConsumablesFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
					end

	local function connectAddonEventHandlerWithFrameForAddon()
		AutomatedConsumablesFrame:SetScript("OnEvent", eventHandlerForAutomatedFoodDrinkMacroScript)
	end

	local function connectAddOnWithGame()
		createFrameForAddon();
		registerEventsNeededForAddon();
		connectAddonEventHandlerWithFrameForAddon();
	end

	SLASH_ACDEBUG1 = "/acdebug"
	SlashCmdList["ACDEBUG"] = function()
		AC_DEBUG = not AC_DEBUG
		print(string.format("%sDebug %s", ACADDON_CHAT_TITLE, AC_DEBUG and "enabled" or "disabled"))
		markMacroForUpdateNow()
		eventHandlerForAutomatedFoodDrinkMacroScript(nil, "AC_FORCE_UPDATE")
	end

	SLASH_ACSHOW1 = "/acshow"
	SlashCmdList["ACSHOW"] = function()
		for macrobuttonNumber = 1, getNumberOfMacroButtons() do
			local macroButtonName = getAddOnMacroButtonName(macrobuttonNumber)
			local body = getMacroBodyByNameSafe(macroButtonName)
			print(string.format("%s%s current body:\n%s", ACADDON_CHAT_TITLE, macroButtonName, tostring(body)))
		end
	end

	SLASH_ACUPDATE1 = "/acupdate"
	SlashCmdList["ACUPDATE"] = function()
		print(string.format("%sForcing macro update...", ACADDON_CHAT_TITLE))
		markMacroForUpdateNow()
		eventHandlerForAutomatedFoodDrinkMacroScript(nil, "AC_FORCE_UPDATE")
	end

	SLASH_ACPANEL1 = "/acpanel"
	SlashCmdList["ACPANEL"] = function()
		initUIOnce()
		toggleMacroPanel()
	end

		SLASH_ACSCAN1 = "/acscan"
		SlashCmdList["ACSCAN"] = function()
		local totalSlots = 0
		local slotsWithItemID = 0
		local foodDrinkCount = 0
		local consumableCount = 0
		local debugPrinted = 0

		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			for slotIndex = 1, numSlots do
				totalSlots = totalSlots + 1
				local itemID = getContainerItemID(bagId, slotIndex) or getContainerItemIDFallback(bagId, slotIndex)
				if itemID then
					slotsWithItemID = slotsWithItemID + 1
					local restoresHealth, restoresMana, requiresSeated = parseRestoreAmountsFromTooltip(bagId, slotIndex)
					local classID, subClassID = getItemClassInfo(itemID)
					local isConsumable = itemIsConsumable(itemID)
					local isFoodOrDrink = itemIsFoodOrDrink(itemID)
						or ((classID == 0 and subClassID == 0) and requiresSeated)
					if isConsumable then
						consumableCount = consumableCount + 1
					end
					if isFoodOrDrink then
						foodDrinkCount = foodDrinkCount + 1
					end

					if AC_DEBUG and debugPrinted < 8 then
						local seatedNeedle = _G.ITEM_MUST_REMAIN_SEATED
						local cItemClassID, cItemSubClassID = nil, nil
						if C_Item and C_Item.GetItemInfoInstant then
							local _, _, _, _, _, classID, subClassID = C_Item.GetItemInfoInstant(itemID)
							cItemClassID, cItemSubClassID = classID, subClassID
						end

						local giClassID, giSubClassID = nil, nil
						if GetItemInfoInstant then
							local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
							giClassID, giSubClassID = classID, subClassID
						end

						local itemName, _, _, _, _, itemType, itemSubType, _, _, _, _, gClassID, gSubClassID = GetItemInfo(itemID)

						print(string.format(
							"%sitem:%d name=%s isConsumable=%s isFoodDrink=%s seated=%s hp=%d mana=%d C_Item=%s/%s GetItemInfoInstant=%s/%s GetItemInfo=%s/%s type=%s sub=%s seatedNeedle=%s",
							ACADDON_CHAT_TITLE,
							itemID,
							tostring(itemName),
							tostring(isConsumable),
							tostring(isFoodOrDrink),
							tostring(requiresSeated),
							restoresHealth,
							restoresMana,
							tostring(cItemClassID),
							tostring(cItemSubClassID),
							tostring(giClassID),
							tostring(giSubClassID),
							tostring(gClassID),
							tostring(gSubClassID),
							tostring(itemType),
							tostring(itemSubType),
							tostring(seatedNeedle)
						))
						debugPrinted = debugPrinted + 1
					end
				end
			end
		end

		SLASH_ACEXPORTFOODDB1 = "/acexportfooddb"
		SlashCmdList["ACEXPORTFOODDB"] = function()
			if type(ACSettings) ~= "table" or type(ACSettings.foodDrinkItemStats) ~= "table" then
				print(string.format("%sNo cached food/drink stats found yet.", ACADDON_CHAT_TITLE))
				return
			end

			local ids = {}
			for itemID in pairs(ACSettings.foodDrinkItemStats) do
				if type(itemID) == "number" then
					ids[#ids + 1] = itemID
				end
			end
			table.sort(ids)

			print(string.format("%sExporting %d entries. Paste into FoodDrinkDB.lua.", ACADDON_CHAT_TITLE, #ids))
			print("AC_FOOD_ITEMS = AC_FOOD_ITEMS or {}")
			print("AC_DRINK_ITEMS = AC_DRINK_ITEMS or {}")
			print("AC_BUFFFOOD_ITEMS = AC_BUFFFOOD_ITEMS or {}")
			print("AC_BUFFFOOD_ITEMS[\"Stamina\"] = AC_BUFFFOOD_ITEMS[\"Stamina\"] or {}")
			print("AC_BUFFFOOD_ITEMS[\"Spirit\"] = AC_BUFFFOOD_ITEMS[\"Spirit\"] or {}")
			print("AC_BUFFFOOD_ITEMS[\"Strength\"] = AC_BUFFFOOD_ITEMS[\"Strength\"] or {}")
			print("AC_BUFFFOOD_ITEMS[\"Agility\"] = AC_BUFFFOOD_ITEMS[\"Agility\"] or {}")
			print("AC_BUFFFOOD_ITEMS[\"Intellect\"] = AC_BUFFFOOD_ITEMS[\"Intellect\"] or {}")

			for _, itemID in ipairs(ids) do
				local s = ACSettings.foodDrinkItemStats[itemID]
				if type(s) == "table" then
					local h = tonumber(s.h) or 0
					local m = tonumber(s.m) or 0
					local wf = s.wf == true
					local bs = type(s.bs) == "table" and s.bs or nil
					local name = (GetItemInfo and GetItemInfo(itemID)) or nil
					name = name and name:gsub("\"", "'") or ("item:" .. tostring(itemID))

					if wf or (bs and next(bs) ~= nil) then
						local bestStat = nil
						local bestAmt = -1
						if bs then
							for statKey, amt in pairs(bs) do
								if type(statKey) == "string" and type(amt) == "number" and amt > bestAmt then
									bestAmt = amt
									bestStat = statKey
								end
							end
						end
						bestStat = bestStat or "Stamina"
						print(string.format(
							"AC_BUFFFOOD_ITEMS[%q][%d] = { name=%q, h=%d, m=%d, wf=true, bs=%s }",
							bestStat,
							itemID,
							name,
							h,
							m,
							bs and "{" .. table.concat((function()
								local parts = {}
								for statKey, amt in pairs(bs) do
									if type(statKey) == "string" and type(amt) == "number" then
										parts[#parts + 1] = string.format("[%q]=%d", statKey, amt)
									end
								end
								table.sort(parts)
								return parts
							end)(), ",") .. "}" or "nil"
						))
					elseif h > 0 and m == 0 then
						print(string.format("AC_FOOD_ITEMS[%d] = { name=%q, h=%d, m=0 }", itemID, name, h))
					elseif m > 0 and h == 0 then
						print(string.format("AC_DRINK_ITEMS[%d] = { name=%q, h=0, m=%d }", itemID, name, m))
					end
				end
			end
		end

		print(string.format("%sScan: slots=%d, withItemID=%d, consumable=%d, foodDrink=%d", ACADDON_CHAT_TITLE, totalSlots, slotsWithItemID, consumableCount, foodDrinkCount))
	end

	SLASH_ACDUMP1 = "/acdump"
	SlashCmdList["ACDUMP"] = function(message)
		local targetItemID = tonumber(message or "")
		if not targetItemID then
			print(string.format("%sUsage: /acdump <itemID>", ACADDON_CHAT_TITLE))
			return
		end

		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			for slotIndex = 1, numSlots do
				local itemID = getContainerItemID(bagId, slotIndex) or getContainerItemIDFallback(bagId, slotIndex)
				if itemID == targetItemID then
					itemScanTooltip:ClearLines()
					itemScanTooltip:SetBagItem(bagId, slotIndex)
					print(string.format("%sTooltip dump for item:%d", ACADDON_CHAT_TITLE, targetItemID))
					for lineIndex = 1, itemScanTooltip:NumLines() do
						local line = _G["AutomatedConsumablesScanTooltipTextLeft" .. lineIndex]
						local text = line and line:GetText() or nil
						if text and text ~= "" then
							print(text)
						end
					end
					return
				end
			end
		end

		print(string.format("%sItem not found in bags: item:%d", ACADDON_CHAT_TITLE, targetItemID))
	end

	SLASH_ACPROBE1 = "/acprobe"
	SlashCmdList["ACPROBE"] = function()
		print(string.format("%sITEM_MUST_REMAIN_SEATED=%s", ACADDON_CHAT_TITLE, tostring(_G.ITEM_MUST_REMAIN_SEATED)))
		print(string.format("%sHEALTH=%s MANA=%s", ACADDON_CHAT_TITLE, tostring(_G.HEALTH), tostring(_G.MANA)))

		local printed = 0
		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			for slotIndex = 1, numSlots do
				local itemID = getContainerItemID(bagId, slotIndex) or getContainerItemIDFallback(bagId, slotIndex)
				if itemID then
					local classID, subClassID = getItemClassInfo(itemID)
					if classID == 0 then
						local restoresHealth, restoresMana, requiresSeated, _, tooltipLines = parseRestoreAmountsFromTooltip(bagId, slotIndex)
						local usable = true
						if IsUsableItem then
							usable = IsUsableItem(itemID)
						end
						local itemName = GetItemInfo(itemID)
						print(string.format(
							"%sProbe: bag=%d slot=%d item:%d name=%s class=%s/%s usable=%s seated=%s hp=%d mana=%d lines=%d",
							ACADDON_CHAT_TITLE,
							bagId,
							slotIndex,
							itemID,
							tostring(itemName),
							tostring(classID),
							tostring(subClassID),
							tostring(usable),
							tostring(requiresSeated),
							restoresHealth,
							restoresMana,
							tooltipLines
						))
						printed = printed + 1
						if printed >= 15 then
							return
						end
					end
				end
			end
		end
	end

		connectAddOnWithGame();
	

			
