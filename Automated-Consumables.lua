do
	local BAG_ID_BACKPACK = 0
	local BAG_ID_LAST = 4

	local basicMacroButtonName = "ACbutton";
	
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
		return 3;
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

	local function buildMacroStringForButton(macroButtonNumber)
		local bestSimpleFoodItemID, bestDrinkItemID, bestBuffFoodItemID, bestFoodAndDrinkItemID, bestAnyUsableFoodOrDrinkItemID = scanBagsForBestConsumables()

		if not (bestSimpleFoodItemID or bestDrinkItemID or bestBuffFoodItemID or bestFoodAndDrinkItemID or bestAnyUsableFoodOrDrinkItemID) then
			if AC_DEBUG then
				print(string.format("%sNo usable Food & Drink found in bags for ACbutton%d", ACADDON_CHAT_TITLE, macroButtonNumber))
			end
			return initialAddOnMacroString .. "\n"
		end

		if AC_DEBUG then
			print(string.format(
				"%sACbutton%d best: food=%s drink=%s bufffood=%s both=%s fallback=%s",
				ACADDON_CHAT_TITLE,
				macroButtonNumber,
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
	
	local function bagContentChanged(event)
		return event == "BAG_UPDATE";
	end
	
	local function playerLeftCombat(event)
		return event == "PLAYER_REGEN_ENABLED";
	end

	local function macroNeedsUpdating(event)
		return playerLoggedIn(event) or bagContentChanged(event) or forcedUpdate(event);
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
		return basicMacroButtonName..macroButtonNumber;
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

	local function getMacroIndexByNameSafe(macroName)
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
		onLogin(event)
		determineIfMacroNeedsToBeUpdatedNowOrLater(event);
		
		if macroWasMarkedForUpdateNow() then
--				print(string.format("%sUpdating macro", ACADDON_CHAT_TITLE));
			
			checkIfMacroButtonsAlreadyExist();
			updateAllMacroStrings();
			
			updateMacrosInGame();

			removeMarkForUpdatingMacroLater();
		end
	end

	local function createFrameForAddon()
		AutomatedConsumablesFrame = CreateFrame("Frame");
	end

	local function registerEventsNeededForAddon()
		AutomatedConsumablesFrame:RegisterEvent("PLAYER_LOGIN");
		AutomatedConsumablesFrame:RegisterEvent("BAG_UPDATE");
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

			
