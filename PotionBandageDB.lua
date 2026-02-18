-- Optional database.
-- You can add known itemIDs to better categorize consumables:
-- - AC_HEALTH_POTION_ITEM_IDS: healing potions
-- - AC_HEALTHSTONE_ITEM_IDS: warlock healthstones
-- - AC_MANA_POTION_ITEM_IDS: mana potions
-- - AC_BANDAGE_ITEM_IDS: First Aid bandages
--
-- These tables are intended as fast lookups (set tables) and can be used by
-- other addon code without relying on tooltip parsing/localization.
AC_HEALTH_POTION_ITEM_IDS = AC_HEALTH_POTION_ITEM_IDS or {
	[118] = true, -- Minor Healing Potion
	[858] = true, -- Lesser Healing Potion
	[929] = true, -- Healing Potion
	[1710] = true, -- Greater Healing Potion
	[3928] = true, -- Superior Healing Potion
	[13446] = true, -- Major Healing Potion
	[22829] = true, -- Super Healing Potion
	[31676] = true, -- Fel Regeneration Potion
	[33092] = true, -- Healing Potion Injector
}

AC_HEALTHSTONE_ITEM_IDS = AC_HEALTHSTONE_ITEM_IDS or {
	[5512] = true, -- Minor Healthstone
	[5511] = true, -- Lesser Healthstone
	[5509] = true, -- Healthstone
	[5510] = true, -- Greater Healthstone
	[9421] = true, -- Major Healthstone
	-- Improved Healthstones (Improved Healthstone talent variants)
	[19004] = true, -- Minor Healthstone (Improved)
	[19005] = true, -- Lesser Healthstone (Improved)
	[19006] = true, -- Healthstone (Improved)
	[19007] = true, -- Greater Healthstone (Improved)
	[19008] = true, -- Major Healthstone (Improved)
	[19009] = true, -- Minor Healthstone (Improved II)
	[19010] = true, -- Lesser Healthstone (Improved II)
	[19011] = true, -- Healthstone (Improved II)
	[19012] = true, -- Greater Healthstone (Improved II)
	[19013] = true, -- Major Healthstone (Improved II)
	[22103] = true, -- Master Healthstone
	[22104] = true, -- Master Healthstone
	[22105] = true, -- Master Healthstone
}

AC_MANA_POTION_ITEM_IDS = AC_MANA_POTION_ITEM_IDS or {
	[2455] = true, -- Minor Mana Potion
	[3385] = true, -- Lesser Mana Potion
	[3827] = true, -- Mana Potion
	[6149] = true, -- Greater Mana Potion
	[13443] = true, -- Superior Mana Potion
	[13444] = true, -- Major Mana Potion
	[22832] = true, -- Super Mana Potion
	[31677] = true, -- Fel Mana Potion
	[33093] = true, -- Mana Potion Injector
}

AC_MANAAGATE_ITEM_IDS = AC_MANAAGATE_ITEM_IDS or {
	[5514] = true, -- Mana Agate
	[5513] = true, -- Mana Jade
	[8007] = true, -- Mana Citrine
	[8008] = true, -- Mana Ruby
}

AC_BANDAGE_ITEM_IDS = AC_BANDAGE_ITEM_IDS or {
	[1251] = true, -- Linen Bandage
	[2581] = true, -- Heavy Linen Bandage
	[3530] = true, -- Wool Bandage
	[3531] = true, -- Heavy Wool Bandage
	[6450] = true, -- Silk Bandage
	[6451] = true, -- Heavy Silk Bandage
	[8544] = true, -- Mageweave Bandage
	[8545] = true, -- Heavy Mageweave Bandage
	[14529] = true, -- Runecloth Bandage
	[14530] = true, -- Heavy Runecloth Bandage
	[21990] = true, -- Netherweave Bandage
	[21991] = true, -- Heavy Netherweave Bandage
}

-- Broad fallback union list (fast candidate check).
AC_POTION_BANDAGE_ITEM_IDS = AC_POTION_BANDAGE_ITEM_IDS or {
	[118] = true,
	[858] = true,
	[929] = true,
	[1710] = true,
	[3928] = true,
	[13446] = true,
	[22829] = true,
	[31676] = true,
	[33092] = true,
	[5512] = true,
	[5511] = true,
	[5509] = true,
	[5510] = true,
	[9421] = true,
	[19004] = true,
	[19005] = true,
	[19006] = true,
	[19007] = true,
	[19008] = true,
	[19009] = true,
	[19010] = true,
	[19011] = true,
	[19012] = true,
	[19013] = true,
	[22103] = true,
	[22104] = true,
	[22105] = true,
	[2455] = true,
	[3385] = true,
	[3827] = true,
	[6149] = true,
	[13443] = true,
	[13444] = true,
	[22832] = true,
	[31677] = true,
	[33093] = true,
	[1251] = true,
	[2581] = true,
	[3530] = true,
	[3531] = true,
	[6450] = true,
	[6451] = true,
	[8544] = true,
	[8545] = true,
	[14529] = true,
	[14530] = true,
	[21990] = true,
	[21991] = true,
}
