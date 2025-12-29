import somanyenchantments.UpgradeEnchantments;

//Tier Upgrades

val normalTierUpgrade = <iceandfire:amethyst_gem>*8;
val supremeTierUpgrade = <variedcommodities:heart>*2;

//To Normal
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:lessersharpness>, <enchantment:minecraft:sharpness>, normalTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:lessersmite>, <enchantment:minecraft:smite>, normalTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:lesserbaneofarthropods>, <enchantment:minecraft:bane_of_arthropods>, normalTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:lesserfireaspect>, <enchantment:minecraft:fire_aspect>, normalTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:lesserflame>, <enchantment:minecraft:flame>, normalTierUpgrade);

//To Supreme
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:advancedsharpness>, <enchantment:somanyenchantments:supremesharpness>, supremeTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:advancedsmite>, <enchantment:somanyenchantments:supremesmite>, supremeTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:advancedbaneofarthropods>, <enchantment:somanyenchantments:supremebaneofarthropods>, supremeTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:advancedfireaspect>, <enchantment:somanyenchantments:supremefireaspect>, supremeTierUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:advancedflame>, <enchantment:somanyenchantments:supremeflame>, supremeTierUpgrade);

UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:minecraft:protection>, <enchantment:somanyenchantments:advancedprotection>, supremeTierUpgrade);

//Special
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:minecraft:mending>, <enchantment:somanyenchantments:advancedmending>, <defiledlands:book_wyrm_scale_golden>*2);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:advancedprotection>, <enchantment:somanyenchantments:supremeprotection>, <minecraft:dragon_egg>*2);


//Level Upgrades

val supremeLevelUpgrade = <quark:biotite>*4;

//Supremes
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:supremesharpness>, <enchantment:somanyenchantments:supremesharpness>, supremeLevelUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:supremesmite>, <enchantment:somanyenchantments:supremesmite>, supremeLevelUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:supremebaneofarthropods>, <enchantment:somanyenchantments:supremebaneofarthropods>, supremeLevelUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:supremefireaspect>, <enchantment:somanyenchantments:supremefireaspect>, supremeLevelUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:supremeflame>, <enchantment:somanyenchantments:supremeflame>, supremeLevelUpgrade);
UpgradeEnchantments.setUpgradeTokenForRecipe(<enchantment:somanyenchantments:advancedprotection>, <enchantment:somanyenchantments:advancedprotection>, supremeLevelUpgrade);