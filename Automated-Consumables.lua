	do
		local BAG_ID_BACKPACK = 0
		local BAG_ID_LAST = 4
	
		local basicMacroButtonName = "ACbutton";

		if type(ACSettings) ~= "table" then
			ACSettings = {}
		end
		if ACSettings.showMinimapButton == nil then
			ACSettings.showMinimapButton = true
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

	local function parseRestoreAmountsFromTooltip(bagId, slotIndex)
		itemScanTooltip:ClearLines()
		itemScanTooltip:SetBagItem(bagId, slotIndex)

		local restoresHealth = 0
		local restoresMana = 0
		local requiresSeated = false
		local isWellFed = false
		local tooltipLines = itemScanTooltip:NumLines() or 0

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

			local hasHealthWord = _G.HEALTH and text:find(_G.HEALTH, 1, true)
			local hasManaWord = _G.MANA and text:find(_G.MANA, 1, true)

			if hasHealthWord or hasManaWord then
				local numbers = {}
				for num in text:gmatch("([%d%.,]+)") do
					table.insert(numbers, num)
				end

				local function parseLocalizedNumber(numText)
					if not numText then
						return nil
					end
					local cleaned = numText:gsub("%.", ""):gsub(",", "")
					return tonumber(cleaned)
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

		return restoresHealth, restoresMana, requiresSeated, isWellFed, tooltipLines
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
		local bestSimpleFoodItemID = nil
		local bestDrinkItemID = nil
		local bestBuffFoodItemID = nil
		local bestFoodAndDrinkItemID = nil
		local bestAnyUsableFoodOrDrinkItemID = nil
		local bestSimpleFoodScore = -1
		local bestDrinkScore = -1
		local bestBuffFoodScore = -1
		local bestFoodAndDrinkScore = -1

		local debugCandidatesPrinted = 0
		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			for slotIndex = 1, numSlots do
				local itemID = getContainerItemID(bagId, slotIndex)
				if not itemID then
					itemID = getContainerItemIDFallback(bagId, slotIndex)
				end
				if itemID then
					local restoresHealth, restoresMana, requiresSeated, isWellFed, tooltipLines = parseRestoreAmountsFromTooltip(bagId, slotIndex)
					local classID, subClassID = getItemClassInfo(itemID)
					local isFoodOrDrink = itemIsFoodOrDrink(itemID)
						or ((classID == 0 and subClassID == 0) and requiresSeated)

					if isFoodOrDrink then
						if AC_DEBUG and debugCandidatesPrinted < 10 then
							local itemName = GetItemInfo(itemID)
							print(string.format(
								"%sCandidate: %s (item:%d) seated=%s hp=%d mana=%d lines=%d",
								ACADDON_CHAT_TITLE,
								tostring(itemName),
								itemID,
								tostring(requiresSeated),
								restoresHealth,
								restoresMana,
								tooltipLines
							))
							debugCandidatesPrinted = debugCandidatesPrinted + 1
						end

						local usable = true
						if IsUsableItem then
							usable = IsUsableItem(itemID)
						end

						if usable then
							if not bestAnyUsableFoodOrDrinkItemID then
								bestAnyUsableFoodOrDrinkItemID = itemID
							end

							local forcedDrink = type(_G.AC_DRINK_ITEM_IDS) == "table" and _G.AC_DRINK_ITEM_IDS[itemID]
							local forcedFood = type(_G.AC_FOOD_ITEM_IDS) == "table" and _G.AC_FOOD_ITEM_IDS[itemID]
							local forcedBuffFood = type(_G.AC_BUFFFOOD_ITEM_IDS) == "table" and _G.AC_BUFFFOOD_ITEM_IDS[itemID]

							local isBuffFood = forcedBuffFood or isWellFed
							local treatAsDrink = forcedDrink or (restoresMana > 0 and restoresHealth == 0)
							local treatAsSimpleFood = forcedFood or (restoresHealth > 0 and restoresMana == 0 and not isBuffFood)

							local score = restoresHealth + restoresMana

							if isBuffFood and score > 0 and score > bestBuffFoodScore then
								bestBuffFoodScore = score
								bestBuffFoodItemID = itemID
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
		end

		return bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID, bestFoodAndDrinkItemID, bestAnyUsableFoodOrDrinkItemID
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

		local function buildMacroStringForButton(macroButtonNumber)
			if macroButtonNumber <= 3 then
				local bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID, bestFoodAndDrinkItemID, bestAnyUsableFoodOrDrinkItemID = scanBagsForBestConsumables()

				if not (bestSimpleFoodItemID or bestDrinkItemID or bestBuffFoodItemID or bestFoodAndDrinkItemID or bestAnyUsableFoodOrDrinkItemID) then
					if AC_DEBUG then
						local macroName = macroButtonNames[macroButtonNumber] or (basicMacroButtonName .. macroButtonNumber)
						print(string.format("%sNo usable Food & Drink found in bags for %s", ACADDON_CHAT_TITLE, macroName))
					end
					return initialAddOnMacroString .. "\n"
				end

				if AC_DEBUG then
					print(string.format(
						"%s%s best: food=%s drink=%s bufffood=%s both=%s fallback=%s",
						ACADDON_CHAT_TITLE,
						(macroButtonNames[macroButtonNumber] or (basicMacroButtonName .. macroButtonNumber)),
						tostring(bestSimpleFoodItemID),
						tostring(bestDrinkItemID),
						tostring(bestBuffFoodItemID),
						tostring(bestFoodAndDrinkItemID),
						tostring(bestAnyUsableFoodOrDrinkItemID)
				))
			end

			if macroButtonNumber == 1 then
				local itemID = bestSimpleFoodItemID or bestFoodAndDrinkItemID or bestAnyUsableFoodOrDrinkItemID
				return initialAddOnMacroString .. string.format("item:%d\n", itemID)
			end

			if macroButtonNumber == 2 then
				local itemID = bestDrinkItemID or bestFoodAndDrinkItemID or bestAnyUsableFoodOrDrinkItemID
				return initialAddOnMacroString .. string.format("item:%d\n", itemID)
			end

			if macroButtonNumber == 3 then
				local itemID = bestBuffFoodItemID or bestSimpleFoodItemID or bestFoodAndDrinkItemID or bestAnyUsableFoodOrDrinkItemID
				return initialAddOnMacroString .. string.format("item:%d\n", itemID)
			end

			return initialAddOnMacroString .. "\n"
		end

		if macroButtonNumber == 4 then
			local healthstoneItemID = findBestHealthstoneItemID()
			local healthPotionItemID = findBestUsableItemIDFromSortedList(healthPotionItemIDs)
			return buildHealthstoneOrPotionMacro(healthstoneItemID, healthPotionItemID)
		end

		if macroButtonNumber == 5 then
			return buildUseItemMacro(findBestUsableItemIDFromSortedList(manaPotionItemIDs), false)
		end

		if macroButtonNumber == 6 then
			return buildUseItemMacro(findBestUsableItemIDFromSortedList(bandageItemIDs), true)
		end

		return initialAddOnMacroString .. "\n"
	end

	local function playerLoggedIn(event)
		return event == "PLAYER_LOGIN";
	end

	local function forcedUpdate(event)
		return event == "AC_FORCE_UPDATE"
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
		local createMinimapButton

	local function parseFirstItemIDFromMacroBody(body)
		if not body or body == "" then
			return nil
		end
		local itemIDText = body:match("item:(%d+)")
		return itemIDText and tonumber(itemIDText) or nil
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
				{ macroName = "ACFood", label = "Food", tooltip = "Food", choices = "Uses the best food available. Fallback: if no food is found, uses food+drink items; if still none, uses any usable food/drink (including drink)." },
				{ macroName = "ACDrink", label = "Drink", tooltip = "Drink", choices = "Uses the best drink available. Fallback: if no drink is found, uses food+drink items; if still none, uses any usable food/drink (including food)." },
				{ macroName = "ACBuff", label = "Buff", tooltip = "Buff Food", choices = "Uses the best buff food (Well Fed) available. Fallback: if none, uses normal food; then food+drink; then any usable food/drink." },
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
			button:RegisterForClicks("LeftButtonUp")
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

			button:SetScript("OnClick", function()
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

			local minimapCheckbox = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
			minimapCheckbox:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -12)
			minimapCheckbox.Text:SetText("Show minimap button")
			minimapCheckbox:SetChecked(ACSettings.showMinimapButton and true or false)
			minimapCheckbox:SetScript("OnClick", function(self)
				ACSettings.showMinimapButton = self:GetChecked() and true or false
				updateMinimapButtonVisibility()
			end)

			local help = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
			help:SetPoint("TOPLEFT", minimapCheckbox, "BOTTOMLEFT", 0, -16)
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

			panel:SetScript("OnShow", function()
				minimapCheckbox:SetChecked(ACSettings.showMinimapButton and true or false)
				refreshOptionsMacroButtons(panel)
			end)

			if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
				local category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
				Settings.RegisterAddOnCategory(category)
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
		end
	
	local function bagContentChanged(event)
		return event == "BAG_UPDATE";
	end

	local function bagCooldownChanged(event)
		return event == "BAG_UPDATE_COOLDOWN";
	end
	
	local function playerLeftCombat(event)
		return event == "PLAYER_REGEN_ENABLED";
	end

	local function macroNeedsUpdating(event)
		return playerLoggedIn(event) or bagContentChanged(event) or bagCooldownChanged(event) or forcedUpdate(event);
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
			EditMacro(macroIndex, macroButtonName, nil, tableOfAddOnMacroButtonContentStrings[macroButtonName], nil);
		end
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
				EditMacro(macroIndex, macroButtonName, nil, macroBody, nil)
				return
			end

			local legacyName = legacyFoodDrinkMacroNames[macroButtonNumber]
			if legacyName then
				local legacyIndex = getMacroIndexByNameSafe(legacyName)
				if legacyIndex and legacyIndex > 0 then
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
		if event == "PLAYER_LOGIN" then
			initUIOnce()
		end

		onLogin(event)
		determineIfMacroNeedsToBeUpdatedNowOrLater(event);
		
		if macroWasMarkedForUpdateNow() then
--				print(string.format("%sUpdating macro", ACADDON_CHAT_TITLE));

			if bagCooldownChanged(event) then
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
				end

			removeMarkForUpdatingMacroLater();
		end
	end

	local function createFrameForAddon()
		AutomatedConsumablesFrame = CreateFrame("Frame");
	end

	local function registerEventsNeededForAddon()
		AutomatedConsumablesFrame:RegisterEvent("PLAYER_LOGIN");
		AutomatedConsumablesFrame:RegisterEvent("BAG_UPDATE");
		AutomatedConsumablesFrame:RegisterEvent("BAG_UPDATE_COOLDOWN");
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
						local restoresHealth, restoresMana, requiresSeated, tooltipLines = parseRestoreAmountsFromTooltip(bagId, slotIndex)
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
end

			
