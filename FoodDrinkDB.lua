-- Food/Drink database (Classic Era)
-- Generated from a wowhead-derived export (source XML not stored in the addon folder).
--
-- Structured tables:
-- - AC_FOOD_ITEMS[itemID]  = { name="...", h=<health>, m=<mana> }         -- typically m=0
-- - AC_DRINK_ITEMS[itemID] = { name="...", h=<health>, m=<mana> }         -- typically h=0
-- - AC_FOODDRINK_BOTH_ITEMS[itemID] = { name="...", h=<health>, m=<mana> } -- restores both
-- - AC_BUFFFOOD_ITEMS[statKey][itemID] = { name="...", h=<health>, m=<mana>, wf=true, bs={...} }
--
-- `h`/`m` are total restored amounts from the tooltip (not per tick).
AC_FOOD_ITEMS = AC_FOOD_ITEMS or {}
AC_DRINK_ITEMS = AC_DRINK_ITEMS or {}
AC_BUFFFOOD_ITEMS = AC_BUFFFOOD_ITEMS or {}

AC_FOOD_ITEMS[117] = { name="Tough Jerky", h=61.2, m=0 }
AC_FOOD_ITEMS[414] = { name="Dalaran Sharp", h=243.6, m=0 }
AC_FOOD_ITEMS[422] = { name="Dwarven Mild", h=552, m=0 }
AC_FOOD_ITEMS[733] = { name="Westfall Stew", h=552, m=0 }
AC_FOOD_ITEMS[787] = { name="Slitherskin Mackerel", h=61.2, m=0 }
AC_FOOD_ITEMS[961] = { name="Healing Herb", h=61.2, m=0 }
AC_FOOD_ITEMS[1113] = { name="Conjured Bread", h=243.6, m=0 }
AC_FOOD_ITEMS[1114] = { name="Conjured Rye", h=552, m=0 }
AC_FOOD_ITEMS[1119] = { name="Bottled Spirits", h=552, m=0 }
AC_FOOD_ITEMS[1326] = { name="Sauteed Sunfish", h=243.6, m=0 }
AC_FOOD_ITEMS[1487] = { name="Conjured Pumpernickel", h=874.8, m=0 }
AC_FOOD_ITEMS[1707] = { name="Stormwind Brie", h=874.8, m=0 }
AC_FOOD_ITEMS[2070] = { name="Darnassian Bleu", h=61.2, m=0 }
AC_FOOD_ITEMS[2287] = { name="Haunch of Meat", h=243.6, m=0 }
AC_FOOD_ITEMS[2679] = { name="Charred Wolf Meat", h=61.2, m=0 }
AC_FOOD_ITEMS[2681] = { name="Roasted Boar Meat", h=61.2, m=0 }
AC_FOOD_ITEMS[2685] = { name="Succulent Pork Ribs", h=552, m=0 }
AC_FOOD_ITEMS[3770] = { name="Mutton Chop", h=552, m=0 }
AC_FOOD_ITEMS[3771] = { name="Wild Hog Shank", h=874.8, m=0 }
AC_FOOD_ITEMS[3927] = { name="Fine Aged Cheddar", h=1392, m=0 }
AC_FOOD_ITEMS[4536] = { name="Shiny Red Apple", h=61.2, m=0 }
AC_FOOD_ITEMS[4537] = { name="Tel'Abim Banana", h=243.6, m=0 }
AC_FOOD_ITEMS[4538] = { name="Snapvine Watermelon", h=552, m=0 }
AC_FOOD_ITEMS[4539] = { name="Goldenbark Apple", h=874.8, m=0 }
AC_FOOD_ITEMS[4540] = { name="Tough Hunk of Bread", h=61.2, m=0 }
AC_FOOD_ITEMS[4541] = { name="Freshly Baked Bread", h=243.6, m=0 }
AC_FOOD_ITEMS[4542] = { name="Moist Cornbread", h=552, m=0 }
AC_FOOD_ITEMS[4544] = { name="Mulgore Spice Bread", h=874.8, m=0 }
AC_FOOD_ITEMS[4592] = { name="Longjaw Mud Snapper", h=243.6, m=0 }
AC_FOOD_ITEMS[4593] = { name="Bristle Whisker Catfish", h=552, m=0 }
AC_FOOD_ITEMS[4594] = { name="Rockscale Cod", h=874.8, m=0 }
AC_FOOD_ITEMS[4599] = { name="Cured Ham Steak", h=1392, m=0 }
AC_FOOD_ITEMS[4601] = { name="Soft Banana Bread", h=1392, m=0 }
AC_FOOD_ITEMS[4602] = { name="Moon Harvest Pumpkin", h=1392, m=0 }
AC_FOOD_ITEMS[4604] = { name="Forest Mushroom Cap", h=61.2, m=0 }
AC_FOOD_ITEMS[4605] = { name="Red-speckled Mushroom", h=243.6, m=0 }
AC_FOOD_ITEMS[4606] = { name="Spongy Morel", h=552, m=0 }
AC_FOOD_ITEMS[4607] = { name="Delicious Cave Mold", h=874.8, m=0 }
AC_FOOD_ITEMS[4608] = { name="Raw Black Truffle", h=1392, m=0 }
AC_FOOD_ITEMS[4656] = { name="Small Pumpkin", h=61.2, m=0 }
AC_FOOD_ITEMS[5057] = { name="Ripe Watermelon", h=61.2, m=0 }
AC_FOOD_ITEMS[5066] = { name="Fissure Plant", h=243.6, m=0 }
AC_FOOD_ITEMS[5095] = { name="Rainbow Fin Albacore", h=243.6, m=0 }
AC_FOOD_ITEMS[5349] = { name="Conjured Muffin", h=61.2, m=0 }
AC_FOOD_ITEMS[5473] = { name="Scorpid Surprise", h=294, m=0 }
AC_FOOD_ITEMS[5478] = { name="Dig Rat Stew", h=552, m=0 }
AC_FOOD_ITEMS[5526] = { name="Clam Chowder", h=552, m=0 }
AC_FOOD_ITEMS[6290] = { name="Brilliant Smallfish", h=61.2, m=0 }
AC_FOOD_ITEMS[6299] = { name="Sickly Looking Fish", h=30, m=0 }
AC_FOOD_ITEMS[6316] = { name="Loch Frenzy Delight", h=243.6, m=0 }
AC_FOOD_ITEMS[6807] = { name="Frog Leg Stew", h=874.8, m=0 }
AC_FOOD_ITEMS[6887] = { name="Spotted Yellowtail", h=1392, m=0 }
AC_FOOD_ITEMS[6888] = { name="Herb Baked Egg", h=61.2, m=0 }
AC_FOOD_ITEMS[6890] = { name="Smoked Bear Meat", h=243.6, m=0 }
AC_FOOD_ITEMS[7097] = { name="Leg Meat", h=61.2, m=0 }
AC_FOOD_ITEMS[8075] = { name="Conjured Sourdough", h=1392, m=0 }
AC_FOOD_ITEMS[8076] = { name="Conjured Sweet Roll", h=2148, m=0 }
AC_FOOD_ITEMS[8077] = { name="Conjured Mineral Water", h=1992, m=0 }
AC_FOOD_ITEMS[8364] = { name="Mithril Head Trout", h=874.8, m=0 }
AC_FOOD_ITEMS[8932] = { name="Alterac Swiss", h=2148, m=0 }
AC_FOOD_ITEMS[8948] = { name="Dried King Bolete", h=2148, m=0 }
AC_FOOD_ITEMS[8950] = { name="Homemade Cherry Pie", h=2148, m=0 }
AC_FOOD_ITEMS[8952] = { name="Roasted Quail", h=2148, m=0 }
AC_FOOD_ITEMS[8953] = { name="Deep Fried Plantains", h=2148, m=0 }
AC_FOOD_ITEMS[8957] = { name="Spinefin Halibut", h=2148, m=0 }
AC_FOOD_ITEMS[9681] = { name="Grilled King Crawler Legs", h=1392, m=0 }
AC_FOOD_ITEMS[11109] = { name="Special Chicken Feed", h=30, m=0 }
AC_FOOD_ITEMS[11415] = { name="Mixed Berries", h=2148, m=0 }
AC_FOOD_ITEMS[11444] = { name="Grim Guzzler Boar", h=2148, m=0 }
AC_FOOD_ITEMS[12238] = { name="Darkshore Grouper", h=243.6, m=0 }
AC_FOOD_ITEMS[13546] = { name="Bloodbelly Fish", h=1392, m=0 }
AC_FOOD_ITEMS[13755] = { name="Winter Squid", h=874.8, m=0 }
AC_FOOD_ITEMS[13893] = { name="Large Raw Mightfish", h=1392, m=0 }
AC_FOOD_ITEMS[13930] = { name="Filet of Redgill", h=1392, m=0 }
AC_FOOD_ITEMS[13933] = { name="Lobster Stew", h=2148, m=0 }
AC_FOOD_ITEMS[13935] = { name="Baked Salmon", h=2148, m=0 }
AC_FOOD_ITEMS[16166] = { name="Bean Soup", h=61.2, m=0 }
AC_FOOD_ITEMS[16167] = { name="Versicolor Treat", h=243.6, m=0 }
AC_FOOD_ITEMS[16168] = { name="Heaven Peach", h=1392, m=0 }
AC_FOOD_ITEMS[16169] = { name="Wild Ricecake", h=874.8, m=0 }
AC_FOOD_ITEMS[16170] = { name="Steamed Mandu", h=552, m=0 }
AC_FOOD_ITEMS[16171] = { name="Shinsollo", h=2148, m=0 }
AC_FOOD_ITEMS[16766] = { name="Undermine Clam Chowder", h=1392, m=0 }
AC_FOOD_ITEMS[17119] = { name="Deeprun Rat Kabob", h=243.6, m=0 }
AC_FOOD_ITEMS[17344] = { name="Candy Cane", h=61.2, m=0 }
AC_FOOD_ITEMS[17406] = { name="Holiday Cheesewheel", h=243.6, m=0 }
AC_FOOD_ITEMS[17407] = { name="Graccu's Homemade Meat Pie", h=874.8, m=0 }
AC_FOOD_ITEMS[17408] = { name="Spicy Beefstick", h=1392, m=0 }
AC_FOOD_ITEMS[18255] = { name="Runn Tum Tuber", h=1392, m=0 }
AC_FOOD_ITEMS[18632] = { name="Moonbrook Riot Taffy", h=874.8, m=0 }
AC_FOOD_ITEMS[18635] = { name="Bellara's Nutterbar", h=1392, m=0 }
AC_FOOD_ITEMS[19223] = { name="Darkmoon Dog", h=61.2, m=0 }
AC_FOOD_ITEMS[19224] = { name="Red Hot Wings", h=874.8, m=0 }
AC_FOOD_ITEMS[19225] = { name="Deep Fried Candybar", h=2148, m=0 }
AC_FOOD_ITEMS[19304] = { name="Spiced Beef Jerky", h=243.6, m=0 }
AC_FOOD_ITEMS[19305] = { name="Pickled Kodo Foot", h=552, m=0 }
AC_FOOD_ITEMS[19306] = { name="Crunchy Frog", h=1392, m=0 }
AC_FOOD_ITEMS[21030] = { name="Darnassus Kimchi Pie", h=1392, m=0 }
AC_FOOD_ITEMS[21031] = { name="Cabbage Kimchi", h=2148, m=0 }
AC_FOOD_ITEMS[21033] = { name="Radish Kimchi", h=2148, m=0 }
AC_FOOD_ITEMS[21552] = { name="Striped Yellowtail", h=1392, m=0 }
AC_FOOD_ITEMS[22324] = { name="Winter Kimchi", h=2148, m=0 }
AC_FOOD_ITEMS[22895] = { name="Conjured Cinnamon Roll", h=3180, m=0 }
AC_FOOD_ITEMS[23160] = { name="Friendship Bread", h=2148, m=0 }

-- Pending additions from FoodDrinkDB-Pending.csv
AC_FOOD_ITEMS[8543] = { name="Underwater Mushroom Cap", h=874.8, m=0 }
AC_FOOD_ITEMS[11951] = { name="Whipper Root Tuber", h=700, m=0 }
AC_FOOD_ITEMS[12763] = { name="Un'Goro Etherfruit", h=2148, m=0 }
AC_FOOD_ITEMS[18633] = { name="Styleen's Sour Suckerpop", h=243.6, m=0 }
AC_FOOD_ITEMS[19696] = { name="Harvest Bread", h=2, m=0 }
AC_FOOD_ITEMS[19994] = { name="Harvest Fruit", h=2, m=0 }
AC_FOOD_ITEMS[19995] = { name="Harvest Boar", h=2, m=0 }
AC_FOOD_ITEMS[19996] = { name="Harvest Fish", h=2, m=0 }
AC_FOOD_ITEMS[20857] = { name="Honey Bread", h=61, m=0 }
AC_FOOD_ITEMS[21215] = { name="Graccu's Mince Meat Fruitcake", h=5, m=0 }
AC_FOOD_ITEMS[21235] = { name="Winter Veil Roast", h=2, m=0 }
AC_FOOD_ITEMS[21236] = { name="Winter Veil Loaf", h=2, m=0 }
AC_FOOD_ITEMS[21240] = { name="Winter Veil Candy", h=2, m=0 }
AC_FOOD_ITEMS[22019] = { name="Conjured Croissant", h=7500, m=0 }
AC_FOOD_ITEMS[23495] = { name="Springpaw Appetizer", h=61.2, m=0 }
AC_FOOD_ITEMS[24009] = { name="Dried Fruit Rations", h=4320, m=0 }
AC_FOOD_ITEMS[24072] = { name="Sand Pear Pie", h=243.6, m=0 }
AC_FOOD_ITEMS[24338] = { name="Hellfire Spineleaf", h=2148, m=0 }
AC_FOOD_ITEMS[27855] = { name="Mag'har Grainbread", h=4320, m=0 }
AC_FOOD_ITEMS[27857] = { name="Garadar Sharp", h=4320, m=0 }
AC_FOOD_ITEMS[27858] = { name="Sunspring Carp", h=4320, m=0 }
AC_FOOD_ITEMS[27859] = { name="Zangar Caps", h=4320, m=0 }
AC_FOOD_ITEMS[28486] = { name="Moser's Magnificent Muffin", h=4320, m=0 }
AC_FOOD_ITEMS[29393] = { name="Diamond Berries", h=4320, m=0 }
AC_FOOD_ITEMS[29402] = { name="Jessen's Special Slop OLD", h=4320, m=0 }
AC_FOOD_ITEMS[29412] = { name="Jessen's Special Slop", h=4320, m=0 }
AC_FOOD_ITEMS[29448] = { name="Mag'har Mild Cheese", h=7500, m=0 }
AC_FOOD_ITEMS[29449] = { name="Bladespire Bagel", h=7500, m=0 }
AC_FOOD_ITEMS[29451] = { name="Clefthoof Ribs", h=7500, m=0 }
AC_FOOD_ITEMS[29452] = { name="Zangar Trout", h=7500, m=0 }
AC_FOOD_ITEMS[29453] = { name="Sporeggar Mushroom", h=7500, m=0 }
AC_FOOD_ITEMS[30355] = { name="Grilled Shadowmoon Tuber", h=7500, m=0 }
AC_FOOD_ITEMS[30458] = { name="Stromgarde Muenster", h=4320, m=0 }
AC_FOOD_ITEMS[30610] = { name="Smoked Black Bear Meat", h=4320, m=0 }
AC_FOOD_ITEMS[30816] = { name="Spice Bread", h=61.2, m=0 }
AC_FOOD_ITEMS[32685] = { name="Ogri'la Chicken Fingers", h=7500, m=0 }
AC_FOOD_ITEMS[33048] = { name="Stewed Trout", h=7500, m=0 }
AC_FOOD_ITEMS[35710] = { name="Delicious Baked Ham", h=7800, m=0 }
AC_FOOD_ITEMS[38427] = { name="Pickled Egg", h=4320, m=0 }
AC_FOOD_ITEMS[38428] = { name="Rock-Salted Pretzel", h=7500, m=0 }

AC_DRINK_ITEMS[159] = { name="Refreshing Spring Water", h=0, m=151.2 }
AC_DRINK_ITEMS[1179] = { name="Ice Cold Milk", h=0, m=436.8 }
AC_DRINK_ITEMS[1205] = { name="Melon Juice", h=0, m=835.2 }
AC_DRINK_ITEMS[1645] = { name="Moonberry Juice", h=0, m=1992 }
AC_DRINK_ITEMS[1708] = { name="Sweet Nectar", h=0, m=1344.6 }
AC_DRINK_ITEMS[2136] = { name="Conjured Purified Water", h=0, m=835.2 }
AC_DRINK_ITEMS[2288] = { name="Conjured Fresh Water", h=0, m=436.8 }
AC_DRINK_ITEMS[3772] = { name="Conjured Spring Water", h=0, m=1344.6 }
AC_DRINK_ITEMS[4791] = { name="Enchanted Water", h=0, m=1344.6 }
AC_DRINK_ITEMS[5350] = { name="Conjured Water", h=0, m=151.2 }
AC_DRINK_ITEMS[8078] = { name="Conjured Sparkling Water", h=0, m=2934 }
AC_DRINK_ITEMS[8079] = { name="Conjured Crystal Water", h=0, m=4200 }
AC_DRINK_ITEMS[8766] = { name="Morning Glory Dew", h=0, m=2934 }
AC_DRINK_ITEMS[9451] = { name="Bubbling Water", h=0, m=835.2 }
AC_DRINK_ITEMS[10841] = { name="Goldthorn Tea", h=0, m=1344.6 }
AC_DRINK_ITEMS[17404] = { name="Blended Bean Brew", h=0, m=436.8 }
AC_DRINK_ITEMS[18300] = { name="Hyjal Nectar", h=0, m=4200 }
AC_DRINK_ITEMS[19299] = { name="Fizzy Faire Drink", h=0, m=835.2 }
AC_DRINK_ITEMS[19300] = { name="Bottled Winterspring Water", h=0, m=1992 }

-- Pending additions from FoodDrinkDB-Pending.csv
AC_DRINK_ITEMS[22018] = { name="Conjured Glacier Water", h=0, m=7200 }
AC_DRINK_ITEMS[29395] = { name="Ethermead", h=0, m=7200 }
AC_DRINK_ITEMS[29401] = { name="Sparkling Southshore Cider", h=0, m=7200 }
AC_DRINK_ITEMS[29454] = { name="Silverwine", h=0, m=5100 }
AC_DRINK_ITEMS[30457] = { name="Gilneas Sparkling Water", h=0, m=7200 }
AC_DRINK_ITEMS[30703] = { name="Conjured Mountain Spring Water", h=0, m=5100 }
AC_DRINK_ITEMS[32668] = { name="Dos Ogris", h=0, m=7200 }
AC_DRINK_ITEMS[33042] = { name="Black Coffee", h=0, m=7200 }
AC_DRINK_ITEMS[38429] = { name="Blackrock Spring Water", h=0, m=2934 }
AC_DRINK_ITEMS[38430] = { name="Blackrock Mineral Water", h=0, m=5100 }
AC_DRINK_ITEMS[38431] = { name="Blackrock Fortified Water", h=0, m=7200 }

AC_FOODDRINK_BOTH_ITEMS = AC_FOODDRINK_BOTH_ITEMS or {}
AC_FOODDRINK_BOTH_ITEMS[2682] = { name="Cooked Crab Claw", h=294, m=294 }
AC_FOODDRINK_BOTH_ITEMS[3448] = { name="Senggin Root", h=294, m=294 }
AC_FOODDRINK_BOTH_ITEMS[13724] = { name="Enriched Manna Biscuit", h=2148, m=4410 }
AC_FOODDRINK_BOTH_ITEMS[19301] = { name="Alterac Manna Biscuit", h=4410, m=4410 }
AC_FOODDRINK_BOTH_ITEMS[20031] = { name="Essence Mango", h=2550, m=4410 }
AC_FOODDRINK_BOTH_ITEMS[21072] = { name="Smoked Sagefish", h=378, m=567 }
AC_FOODDRINK_BOTH_ITEMS[21217] = { name="Sagefish Delight", h=840, m=1260 }

-- Pending additions from FoodDrinkDB-Pending.csv
AC_FOODDRINK_BOTH_ITEMS[13931] = { name="Nightfin Soup", h=874.8, m=8 }
AC_FOODDRINK_BOTH_ITEMS[13932] = { name="Poached Sunscale Salmon", h=874.8, m=6 }
AC_FOODDRINK_BOTH_ITEMS[23172] = { name="Refreshing Red Apple", h=4, m=4 }
AC_FOODDRINK_BOTH_ITEMS[28112] = { name="Underspore Pod", h=4410, m=4410 }
AC_FOODDRINK_BOTH_ITEMS[33053] = { name="Hot Buttered Trout", h=7500, m=7200 }

AC_BUFFFOOD_ITEMS["Agility"] = AC_BUFFFOOD_ITEMS["Agility"] or {}
AC_BUFFFOOD_ITEMS["Spirit"] = AC_BUFFFOOD_ITEMS["Spirit"] or {}
AC_BUFFFOOD_ITEMS["Spirit"][33825] = { name="Skullfish Soup", h=0, m=7200, wf=true, bs={ Spirit=20, SpellCrit=20 } }
AC_BUFFFOOD_ITEMS["Agility"][13928] = { name="Grilled Squid", h=874.8, m=0, wf=true, bs={["Agility"]=10} }
AC_BUFFFOOD_ITEMS["Agility"][30358] = { name="Oronok's Tuber of Agility", h=7500, m=0, wf=true, bs={["Agility"]=20,["Spirit"]=20} }

AC_BUFFFOOD_ITEMS["Intellect"] = AC_BUFFFOOD_ITEMS["Intellect"] or {}
AC_BUFFFOOD_ITEMS["Intellect"][18254] = { name="Runn Tum Tuber Surprise", h=1933.2, m=0, wf=true, bs={["Intellect"]=10} }

AC_BUFFFOOD_ITEMS["Spirit"] = AC_BUFFFOOD_ITEMS["Spirit"] or {}
AC_BUFFFOOD_ITEMS["Spirit"][724] = { name="Goretusk Liver Pie", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][1017] = { name="Seasoned Wolf Kabob", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][1082] = { name="Redridge Goulash", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][2680] = { name="Spiced Wolf Meat", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][2683] = { name="Crab Cake", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][2684] = { name="Coyote Steak", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][2687] = { name="Dry Pork Ribs", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][2888] = { name="Beer Basted Boar Ribs", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][3220] = { name="Blood Sausage", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][3662] = { name="Crocolisk Steak", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][3663] = { name="Murloc Fin Soup", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][3664] = { name="Crocolisk Gumbo", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][3665] = { name="Curiously Tasty Omelet", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][3666] = { name="Gooey Spider Cake", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][3726] = { name="Big Bear Steak", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][3727] = { name="Hot Lion Chops", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][3728] = { name="Tasty Lion Steak", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][3729] = { name="Soothing Turtle Bisque", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][4457] = { name="Barbecued Buzzard Wing", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][5472] = { name="Kaldorei Spider Kabob", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][5474] = { name="Roasted Kodo Meat", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][5476] = { name="Fillet of Frenzy", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][5477] = { name="Strider Stew", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][5479] = { name="Crispy Lizard Tail", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][5480] = { name="Lean Venison", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][5525] = { name="Boiled Clams", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][5527] = { name="Goblin Deviled Clams", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][6038] = { name="Giant Clam Scorcho", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][7228] = { name="Tigule's Strawberry Ice Cream", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][7806] = { name="Lollipop", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][7807] = { name="Candy Bar", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][7808] = { name="Chocolate Square", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][11584] = { name="Cactus Apple Surprise", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][12209] = { name="Lean Wolf Steak", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Spirit"][12210] = { name="Roast Raptor", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][12211] = { name="Spiced Wolf Ribs", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][12212] = { name="Jungle Stew", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][12213] = { name="Carrion Surprise", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][12214] = { name="Mystery Stew", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][12215] = { name="Heavy Kodo Stew", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Spirit"][12216] = { name="Spiced Chili Crab", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Spirit"][12218] = { name="Monster Omelet", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Spirit"][12224] = { name="Crispy Bat Wing", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][13851] = { name="Hot Wolf Ribs", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Spirit"][13929] = { name="Hot Smoked Bass", h=874.8, m=0, wf=true, bs={["Spirit"]=10} }
AC_BUFFFOOD_ITEMS["Spirit"][16971] = { name="Clamlette Surprise", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Spirit"][17197] = { name="Gingerbread Cookie", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][17198] = { name="Egg Nog", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][17199] = { name="Bad Egg Nog", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][17222] = { name="Spider Sausage", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Spirit"][18045] = { name="Tender Wolf Steak", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Spirit"][20074] = { name="Heavy Crocolisk Stew", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }

-- Pending additions from FoodDrinkDB-Pending.csv
AC_BUFFFOOD_ITEMS["Spirit"][20516] = { name="Bobbing Apple", h=2, m=0, wf=true, bs={["Stamina"]=15,["Spirit"]=15} }
AC_BUFFFOOD_ITEMS["Spirit"][21254] = { name="Winter Veil Cookie", h=2, m=0, wf=true, bs={["Stamina"]=15,["Spirit"]=15} }
AC_BUFFFOOD_ITEMS["Spirit"][22645] = { name="Crunchy Spider Surprise", h=243.6, m=0, wf=true, bs={["Stamina"]=4,["Spirit"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][23756] = { name="Cookie's Jumbo Gumbo", h=61.2, m=0, wf=true, bs={["Stamina"]=2,["Spirit"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][24105] = { name="Roasted Moongraze Tenderloin", h=61.2, m=0, wf=true, bs={["Stamina"]=2,["Spirit"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][24539] = { name="Marsh Lichen", h=4320, m=0, wf=true, bs={["Spirit"]=10} }
AC_BUFFFOOD_ITEMS["Spirit"][27635] = { name="Lynx Steak", h=61.2, m=0, wf=true, bs={["Stamina"]=2,["Spirit"]=2} }
AC_BUFFFOOD_ITEMS["Spirit"][27636] = { name="Bat Bites", h=243.6, m=0, wf=true, bs={["Stamina"]=4,["Spirit"]=4} }
AC_BUFFFOOD_ITEMS["Spirit"][27651] = { name="Buzzard Bites", h=4300, m=0, wf=true, bs={["Stamina"]=20,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Spirit"][27665] = { name="Poached Bluefish", h=7500, m=0, wf=true, bs={["SpellPower"]=23,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Spirit"][29293] = { name="Bonestripper Buzzard Hotwings", h=2148, m=0, wf=true, bs={["Stamina"]=14,["Spirit"]=14} }
AC_BUFFFOOD_ITEMS["Spirit"][30155] = { name="Clam Bar", h=4320, m=0, wf=true, bs={["Stamina"]=20,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Spirit"][30357] = { name="Oronok's Tuber of Healing", h=7500, m=0, wf=true, bs={["Healing"]=44,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Spirit"][30358] = { name="Oronok's Tuber of Agility", h=7500, m=0, wf=true, bs={["Agility"]=20,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Spirit"][30359] = { name="Oronok's Tuber of Strength", h=7500, m=0, wf=true, bs={["Strength"]=20,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Spirit"][30361] = { name="Oronok's Tuber of Spell Power", h=7500, m=0, wf=true, bs={["SpellPower"]=23,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Spirit"][33004] = { name="Clamlette Surprise", h=1392, m=0, wf=true, bs={["Stamina"]=12,["Spirit"]=12} }
AC_BUFFFOOD_ITEMS["Spirit"][34411] = { name="Hot Apple Cider", h=0, m=7200, wf=true, bs={["Stamina"]=20,["Spirit"]=30} }

AC_BUFFFOOD_ITEMS["Stamina"] = AC_BUFFFOOD_ITEMS["Stamina"] or {}
AC_BUFFFOOD_ITEMS["Stamina"][724] = { name="Goretusk Liver Pie", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][1017] = { name="Seasoned Wolf Kabob", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][1082] = { name="Redridge Goulash", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][2680] = { name="Spiced Wolf Meat", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][2683] = { name="Crab Cake", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][2684] = { name="Coyote Steak", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][2687] = { name="Dry Pork Ribs", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][2888] = { name="Beer Basted Boar Ribs", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][3220] = { name="Blood Sausage", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][3662] = { name="Crocolisk Steak", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][3663] = { name="Murloc Fin Soup", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][3664] = { name="Crocolisk Gumbo", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][3665] = { name="Curiously Tasty Omelet", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][3666] = { name="Gooey Spider Cake", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][3726] = { name="Big Bear Steak", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][3727] = { name="Hot Lion Chops", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][3728] = { name="Tasty Lion Steak", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][3729] = { name="Soothing Turtle Bisque", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][4457] = { name="Barbecued Buzzard Wing", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][5472] = { name="Kaldorei Spider Kabob", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][5474] = { name="Roasted Kodo Meat", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][5476] = { name="Fillet of Frenzy", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][5477] = { name="Strider Stew", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][5479] = { name="Crispy Lizard Tail", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][5480] = { name="Lean Venison", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][5525] = { name="Boiled Clams", h=243.6, m=0, wf=true, bs={["Spirit"]=4,["Stamina"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][5527] = { name="Goblin Deviled Clams", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][6038] = { name="Giant Clam Scorcho", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][7228] = { name="Tigule's Strawberry Ice Cream", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][7806] = { name="Lollipop", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][7807] = { name="Candy Bar", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][7808] = { name="Chocolate Square", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][11584] = { name="Cactus Apple Surprise", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][12209] = { name="Lean Wolf Steak", h=552, m=0, wf=true, bs={["Spirit"]=6,["Stamina"]=6} }
AC_BUFFFOOD_ITEMS["Stamina"][12210] = { name="Roast Raptor", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][12211] = { name="Spiced Wolf Ribs", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][12212] = { name="Jungle Stew", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][12213] = { name="Carrion Surprise", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][12214] = { name="Mystery Stew", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][12215] = { name="Heavy Kodo Stew", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Stamina"][12216] = { name="Spiced Chili Crab", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Stamina"][12218] = { name="Monster Omelet", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Stamina"][12224] = { name="Crispy Bat Wing", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][13851] = { name="Hot Wolf Ribs", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][13927] = { name="Cooked Glossy Mightfish", h=874.8, m=0, wf=true, bs={["Stamina"]=10} }
AC_BUFFFOOD_ITEMS["Stamina"][13934] = { name="Mightfish Steak", h=1933.2, m=0, wf=true, bs={["Stamina"]=10} }
AC_BUFFFOOD_ITEMS["Stamina"][16971] = { name="Clamlette Surprise", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Stamina"][17197] = { name="Gingerbread Cookie", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][17198] = { name="Egg Nog", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][17199] = { name="Bad Egg Nog", h=61.2, m=0, wf=true, bs={["Spirit"]=2,["Stamina"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][17222] = { name="Spider Sausage", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Stamina"][18045] = { name="Tender Wolf Steak", h=1392, m=0, wf=true, bs={["Spirit"]=12,["Stamina"]=12} }
AC_BUFFFOOD_ITEMS["Stamina"][20074] = { name="Heavy Crocolisk Stew", h=874.8, m=0, wf=true, bs={["Spirit"]=8,["Stamina"]=8} }
AC_BUFFFOOD_ITEMS["Stamina"][21023] = { name="Dirge's Kickin' Chimaerok Chops", h=2550, m=0, wf=true, bs={["Stamina"]=25} }

-- Pending additions from FoodDrinkDB-Pending.csv
AC_BUFFFOOD_ITEMS["Stamina"][20516] = { name="Bobbing Apple", h=2, m=0, wf=true, bs={["Stamina"]=15,["Spirit"]=15} }
AC_BUFFFOOD_ITEMS["Stamina"][21254] = { name="Winter Veil Cookie", h=2, m=0, wf=true, bs={["Stamina"]=15,["Spirit"]=15} }
AC_BUFFFOOD_ITEMS["Stamina"][22645] = { name="Crunchy Spider Surprise", h=243.6, m=0, wf=true, bs={["Stamina"]=4,["Spirit"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][23756] = { name="Cookie's Jumbo Gumbo", h=61.2, m=0, wf=true, bs={["Stamina"]=2,["Spirit"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][24008] = { name="Dried Mushroom Rations", h=4320, m=0, wf=true, bs={["Stamina"]=10} }
AC_BUFFFOOD_ITEMS["Stamina"][24105] = { name="Roasted Moongraze Tenderloin", h=61.2, m=0, wf=true, bs={["Stamina"]=2,["Spirit"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][27635] = { name="Lynx Steak", h=61.2, m=0, wf=true, bs={["Stamina"]=2,["Spirit"]=2} }
AC_BUFFFOOD_ITEMS["Stamina"][27636] = { name="Bat Bites", h=243.6, m=0, wf=true, bs={["Stamina"]=4,["Spirit"]=4} }
AC_BUFFFOOD_ITEMS["Stamina"][27651] = { name="Buzzard Bites", h=4300, m=0, wf=true, bs={["Stamina"]=20,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Stamina"][28501] = { name="Ravager Egg Omelet", h=4320, m=0, wf=true, bs={["Stamina"]=10} }
AC_BUFFFOOD_ITEMS["Stamina"][29293] = { name="Bonestripper Buzzard Hotwings", h=2148, m=0, wf=true, bs={["Stamina"]=14,["Spirit"]=14} }
AC_BUFFFOOD_ITEMS["Stamina"][30155] = { name="Clam Bar", h=4320, m=0, wf=true, bs={["Stamina"]=20,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["Stamina"][33004] = { name="Clamlette Surprise", h=1392, m=0, wf=true, bs={["Stamina"]=12,["Spirit"]=12} }
AC_BUFFFOOD_ITEMS["Stamina"][34411] = { name="Hot Apple Cider", h=0, m=7200, wf=true, bs={["Stamina"]=20,["Spirit"]=30} }

AC_BUFFFOOD_ITEMS["Strength"] = AC_BUFFFOOD_ITEMS["Strength"] or {}
AC_BUFFFOOD_ITEMS["Strength"][13810] = { name="Blessed Sunfruit", h=1933.2, m=0, wf=true, bs={["Strength"]=10} }
AC_BUFFFOOD_ITEMS["Strength"][20452] = { name="Smoked Desert Dumplings", h=2148, m=0, wf=true, bs={["Strength"]=20} }
-- Pending additions from FoodDrinkDB-Pending.csv
AC_BUFFFOOD_ITEMS["Strength"][29292] = { name="Helboar Bacon", h=2148, m=0, wf=true, bs={["Strength"]=20} }
AC_BUFFFOOD_ITEMS["Strength"][30359] = { name="Oronok's Tuber of Strength", h=7500, m=0, wf=true, bs={["Strength"]=20,["Spirit"]=20} }

AC_BUFFFOOD_ITEMS["Healing"] = AC_BUFFFOOD_ITEMS["Healing"] or {}
AC_BUFFFOOD_ITEMS["Healing"][30357] = { name="Oronok's Tuber of Healing", h=7500, m=0, wf=true, bs={["Healing"]=44,["Spirit"]=20} }

AC_BUFFFOOD_ITEMS["SpellPower"] = AC_BUFFFOOD_ITEMS["SpellPower"] or {}
AC_BUFFFOOD_ITEMS["SpellPower"][27665] = { name="Poached Bluefish", h=7500, m=0, wf=true, bs={["SpellPower"]=23,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["SpellPower"][30361] = { name="Oronok's Tuber of Spell Power", h=7500, m=0, wf=true, bs={["SpellPower"]=23,["Spirit"]=20} }
AC_BUFFFOOD_ITEMS["SpellPower"][35565] = { name="Juicy Bear Burger", h=1933.2, m=0, wf=true, bs={["SpellPower"]=14} }

AC_BUFFFOOD_ITEMS["AttackPower"] = AC_BUFFFOOD_ITEMS["AttackPower"] or {}
AC_BUFFFOOD_ITEMS["AttackPower"][35563] = { name="Charred Bear Kabobs", h=1933.2, m=0, wf=true, bs={["AttackPower"]=24} }

AC_BUFFFOOD_ITEMS["Random"] = AC_BUFFFOOD_ITEMS["Random"] or {}
AC_BUFFFOOD_ITEMS["Random"][32686] = { name="Mingo's Fortune Giblets", h=7500, m=0, wf=true, bs={["Random"]="buff"} }

-- Derived legacy compatibility tables (used by the addon code)
-- ------------------------------------------------------------
-- TBC additions (The Burning Crusade)
-- ------------------------------------------------------------

-- Basic/vendor foods
AC_FOOD_ITEMS[27854] = { name="Smoked Talbuk Venison", h=4320, m=0 }
AC_FOOD_ITEMS[27856] = { name="Skethyl Berries", h=4320, m=0 }
AC_FOOD_ITEMS[29394] = { name="Lyribread", h=7500, m=0 }
AC_FOOD_ITEMS[29450] = { name="Telaari Grapes", h=7500, m=0 }
AC_FOOD_ITEMS[27661] = { name="Blackened Trout", h=4320, m=0 }

-- Basic/vendor drinks
AC_DRINK_ITEMS[28399] = { name="Filtered Draenic Water", h=0, m=5100 }
AC_DRINK_ITEMS[27860] = { name="Purified Draenic Water", h=0, m=7200 }
AC_DRINK_ITEMS[32455] = { name="Star's Lament", h=0, m=4200 }
AC_DRINK_ITEMS[32453] = { name="Star's Tears", h=0, m=7200 } 

-- Restores both health + mana
AC_FOODDRINK_BOTH_ITEMS[32722] = { name="Enriched Terocone Juice", h=4320, m=5100 }
AC_FOODDRINK_BOTH_ITEMS[34780] = { name="Naaru Ration", h=7500, m=7200 }
AC_FOODDRINK_BOTH_ITEMS[34062] = { name="Conjured Mana Biscuit", h=7500, m=7200 } -- mage table, already present in some clients; keep here for TBC safety

-- Outland cooking well-fed foods (IDs 27655-27667)
-- Note: These are all well-fed items; we place them into their relevant stat buckets so "Prefer stat" can pick them.
AC_BUFFFOOD_ITEMS["Spirit"] = AC_BUFFFOOD_ITEMS["Spirit"] or {}
AC_BUFFFOOD_ITEMS["Stamina"] = AC_BUFFFOOD_ITEMS["Stamina"] or {}
AC_BUFFFOOD_ITEMS["Strength"] = AC_BUFFFOOD_ITEMS["Strength"] or {}
AC_BUFFFOOD_ITEMS["Agility"] = AC_BUFFFOOD_ITEMS["Agility"] or {}

AC_BUFFFOOD_ITEMS["Spirit"][27657] = { name="Blackened Basilisk", h=7500, m=0, wf=true, bs={ Spirit=20, SpellPower=23 } }
AC_BUFFFOOD_ITEMS["Spirit"][31673] = { name="Crunchy Serpent", h=7500, m=0, wf=true, bs={ Spirit=20, SpellPower=23 } }
AC_BUFFFOOD_ITEMS["Spirit"][27666] = { name="Golden Fish Sticks", h=7500, m=0, wf=true, bs={ Spirit=20, Healing=44 } }
AC_BUFFFOOD_ITEMS["Agility"][27664] = { name="Grilled Mudfish", h=7500, m=0, wf=true, bs={ Agility=20, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Spirit"][31672] = { name="Mok'Nathal Shortribs", h=7500, m=0, wf=true, bs={ Stamina=20, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Strength"][27658] = { name="Roasted Clefthoof", h=7500, m=0, wf=true, bs={ Strength=20, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Spirit"][27662] = { name="Feltail Delight", h=4320, m=0, wf=true, bs={ Stamina=20, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Spirit"][27655] = { name="Ravager Dog", h=4320, m=0, wf=true, bs={ Spirit=20, AttackPower=40 } }
AC_BUFFFOOD_ITEMS["Stamina"][27663] = { name="Blackened Sporefish", h=4320, m=0, wf=true, bs={ Stamina=20, MP5=8 } }
AC_BUFFFOOD_ITEMS["Spirit"][33867] = { name="Broiled Bloodfin", h=4320, m=0, wf=true, bs={ ResistAll=8 } }
AC_BUFFFOOD_ITEMS["Strength"][27660] = { name="Talbuk Steak", h=7500, m=0, wf=true, bs={ Stamina=20, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Agility"][27659] = { name="Warp Burger", h=7500, m=0, wf=true, bs={ Agility=20, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Stamina"][32721] = { name="Skyguard Rations", h=6000, m=0, wf=true, bs={ Stamina=15, Spirit=15 } }
AC_BUFFFOOD_ITEMS["Stamina"][33052] = { name="Fisherman's Feast", h=7500, m=0, wf=true, bs={ Stamina=30, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Stamina"][33872] = { name="Spicy Hot Talbuk", h=7500, m=0, wf=true, bs={ Hit=20, Spirit=20 } }
AC_BUFFFOOD_ITEMS["Stamina"][27667] = { name="Spicy Crawdad", h=7500, m=0, wf=true, bs={ Stamina=30, Spirit=20 } }


AC_FOOD_ITEM_IDS = AC_FOOD_ITEM_IDS or {}
AC_DRINK_ITEM_IDS = AC_DRINK_ITEM_IDS or {}
AC_BUFFFOOD_ITEM_IDS = AC_BUFFFOOD_ITEM_IDS or {}
AC_FOOD_DRINK_ITEM_IDS = AC_FOOD_DRINK_ITEM_IDS or {}
AC_FOODDRINK_ITEM_STATS = AC_FOODDRINK_ITEM_STATS or {}

local function _ac_add_stat(itemID, stats)
	AC_FOODDRINK_ITEM_STATS[itemID] = stats
	AC_FOOD_DRINK_ITEM_IDS[itemID] = true
end

for itemID, s in pairs(AC_FOOD_ITEMS) do
	if type(itemID) == "number" and type(s) == "table" then
		AC_FOOD_ITEM_IDS[itemID] = true
		_ac_add_stat(itemID, { h = s.h or 0, m = s.m or 0, wf = false, bs = nil, kind = "food" })
	end
end
for itemID, s in pairs(AC_DRINK_ITEMS) do
	if type(itemID) == "number" and type(s) == "table" then
		AC_DRINK_ITEM_IDS[itemID] = true
		_ac_add_stat(itemID, { h = s.h or 0, m = s.m or 0, wf = false, bs = nil, kind = "drink" })
	end
end
for itemID, s in pairs(AC_FOODDRINK_BOTH_ITEMS) do
	if type(itemID) == "number" and type(s) == "table" then
		_ac_add_stat(itemID, { h = s.h or 0, m = s.m or 0, wf = false, bs = nil, kind = "both" })
	end
end
for statKey, bucket in pairs(AC_BUFFFOOD_ITEMS) do
	if type(statKey) == "string" and type(bucket) == "table" then
		for itemID, s in pairs(bucket) do
			if type(itemID) == "number" and type(s) == "table" then
				AC_BUFFFOOD_ITEM_IDS[itemID] = true
				_ac_add_stat(itemID, { h = s.h or 0, m = s.m or 0, wf = true, bs = s.bs, kind = "buff" })
			end
		end
	end
end
