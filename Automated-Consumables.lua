do
	-- Classic Era: dynamically pick the "best" food/drink you currently have in bags.
	-- This avoids maintaining hardcoded Retail item IDs and automatically supports new/rare foods.

	local BAG_ID_BACKPACK = 0
	local BAG_ID_LAST = 4

	local basicMacroButtonName = "ACbutton";
	
	local tableOfAddOnMacroButtonContentStrings;
	local tableOfAddOnMacroButtonExistanceStatus;
	local tableOfOldMacroButtonNames = {}
	
	local initialAddOnMacroString = "#showtooltip\n/use ";

	-- Setting up string for console output
	local ACADDON_CHAT_TITLE = "|CFF9482C9Automated-Consumables:|r "

	local updateMacroLater = false;
	local updateMacroNow = false;

	local function getNumberOfMacroButtons()
		return 2;
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
		return GetContainerItemID(bagId, slotIndex)
	end

	local itemScanTooltip = CreateFrame("GameTooltip", "AutomatedConsumablesScanTooltip", UIParent, "GameTooltipTemplate")
	itemScanTooltip:SetOwner(UIParent, "ANCHOR_NONE")

	local function parseRestoreAmountsFromTooltip(bagId, slotIndex)
		itemScanTooltip:ClearLines()
		itemScanTooltip:SetBagItem(bagId, slotIndex)

		local restoresHealth = 0
		local restoresMana = 0

		for lineIndex = 2, itemScanTooltip:NumLines() do
			local line = _G["AutomatedConsumablesScanTooltipTextLeft" .. lineIndex]
			local text = line and line:GetText() or nil
			if text then
				local healthText = text:match("Restores ([%d,]+) health")
				if healthText then
					restoresHealth = tonumber((healthText:gsub(",", ""))) or restoresHealth
				end

				local manaText = text:match("Restores ([%d,]+) mana")
				if manaText then
					restoresMana = tonumber((manaText:gsub(",", ""))) or restoresMana
				end

				local bothHealthText, bothManaText = text:match("Restores ([%d,]+) health and ([%d,]+) mana")
				if bothHealthText and bothManaText then
					restoresHealth = tonumber((bothHealthText:gsub(",", ""))) or restoresHealth
					restoresMana = tonumber((bothManaText:gsub(",", ""))) or restoresMana
				end
			end
		end

		return restoresHealth, restoresMana
	end

	local function itemIsFoodOrDrink(itemID)
		if GetItemInfoInstant then
			local _, _, _, _, _, classID, subClassID = GetItemInfoInstant(itemID)
			if classID == 0 and subClassID == 5 then
				return true
			end
		end

		local _, _, _, _, _, itemType, itemSubType = GetItemInfo(itemID)
		return itemType == "Consumable" and itemSubType == "Food & Drink"
	end

	local function scanBagsForBestConsumables()
		local bestFoodItemID = nil
		local bestDrinkItemID = nil
		local bestFoodAndDrinkItemID = nil
		local bestFoodScore = -1
		local bestDrinkScore = -1
		local bestFoodAndDrinkScore = -1

		for bagId = BAG_ID_BACKPACK, BAG_ID_LAST do
			local numSlots = getContainerNumSlots(bagId) or 0
			for slotIndex = 1, numSlots do
				local itemID = getContainerItemID(bagId, slotIndex)
				if itemID and GetItemCount(itemID, false, false) > 0 and itemIsFoodOrDrink(itemID) then
					local restoresHealth, restoresMana = parseRestoreAmountsFromTooltip(bagId, slotIndex)
					local score = restoresHealth + restoresMana

					if restoresHealth > 0 and restoresMana > 0 and score > bestFoodAndDrinkScore then
						bestFoodAndDrinkScore = score
						bestFoodAndDrinkItemID = itemID
					elseif restoresHealth > 0 and restoresHealth > bestFoodScore then
						bestFoodScore = restoresHealth
						bestFoodItemID = itemID
					elseif restoresMana > 0 and restoresMana > bestDrinkScore then
						bestDrinkScore = restoresMana
						bestDrinkItemID = itemID
					end
				end
			end
		end

		return bestFoodItemID, bestDrinkItemID, bestFoodAndDrinkItemID
	end

	local function buildUseLine(clauses)
		local parts = {}
		for _, clause in ipairs(clauses) do
			if clause.itemID then
				table.insert(parts, string.format("%s item:%d", clause.condition, clause.itemID))
			end
		end
		if #parts == 0 then
			return initialAddOnMacroString .. "\n"
		end
		return initialAddOnMacroString .. table.concat(parts, "; ") .. "\n"
	end

	local function buildMacroStringForButton(macroButtonNumber)
		local bestFoodItemID, bestDrinkItemID, bestFoodAndDrinkItemID = scanBagsForBestConsumables()
		local defaultItemID = bestFoodAndDrinkItemID or bestFoodItemID or bestDrinkItemID

		if not defaultItemID then
			return initialAddOnMacroString .. "\n"
		end

		if macroButtonNumber == 1 then
			return buildUseLine({
				{ condition = "[mod:shift]", itemID = bestFoodItemID or defaultItemID },
				{ condition = "[mod:ctrl]", itemID = bestDrinkItemID or defaultItemID },
				{ condition = "[nomod]", itemID = defaultItemID },
			})
		end

		return buildUseLine({
			{ condition = "[mod:shift]", itemID = bestDrinkItemID or defaultItemID },
			{ condition = "[mod:ctrl]", itemID = bestFoodItemID or defaultItemID },
			{ condition = "[nomod]", itemID = defaultItemID },
		})
	end

	local function playerLoggedIn(event)
		return event == "PLAYER_LOGIN";
	end
	
	local function bagContentChanged(event)
		return event == "BAG_UPDATE";
	end
	
	local function playerLeftCombat(event)
		return event == "PLAYER_REGEN_ENABLED";
	end

	local function macroNeedsUpdating(event)
		return playerLoggedIn(event) or bagContentChanged(event);
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
	end

	local function updateMacro(macroButtonName)
		EditMacro(macroButtonName, macroButtonName, nil, tableOfAddOnMacroButtonContentStrings[macroButtonName], 1, nil);
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

	connectAddOnWithGame();
end

			
