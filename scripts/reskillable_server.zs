// Server-side Reskillable bonuses script (CraftTweaker / ZenScript template)
//
// Place this file on the SERVER at scripts/reskillable_bonuses_server.zs
// Also put the client script (reskillable_bonuses_client.zs) on every client so tooltips are computed locally.
//
// What this script does (server-side):
// - Polls Reskillable skill levels once per second (fallback if no direct event available).
// - Computes per-player skill multipliers per your spec.
// - Keeps a small cache of last-known skill levels and applied modifiers.
// - Runs farming heal every second: heal = maxHealth * (farmingLevel / 100) * 0.02.
// - Hooks break/drops/xp events (placeholders) to apply mining/gathering/building multipliers.
//
// Important placeholders (YOU MAY NEED TO ADAPT)
// 1) getSkillLevel(player, skillName)
//    - Attempts to read the player's Reskillable skill level.
//    - Try the provided default (mods.reskillable API). If your CraftTweaker environment exposes a different path,
//      replace the body accordingly.
// 2) applyPlayerAttribute(player, attributeName, amount, uuidArray)
//    - In many environments CraftTweaker cannot apply attribute modifiers on the player entity directly.
//      If your CT exposes an API (player.addAttributeModifier or similar) use it here. Otherwise, you will need a
//      small helper mod, or implement damage/armor changes in event handlers directly (also marked).
//
// If anything throws "missing" or "undefined", send me the error and I'll adapt the script to your exact CT bindings.

import crafttweaker.item.IItemStack;

print("reskillable_bonuses_server.zs loading...");

//////////////////////////////////////
// Config / Constants
//////////////////////////////////////

val TICKS_PER_SECOND = 20;
val POLL_INTERVAL_TICKS = 20; // once per second

val MAX_LEVEL = 100;

// Skill effect maximums (linear scaling)
val ATTACK_MAX = 0.50;       // +50% final damage
val DEFENSE_ARMOR_MAX = 0.50; // +50% armor
val DEFENSE_TOUGHNESS_MAX = 0.25; // +25% toughness
val AGILITY_MOVE_MAX = 0.30; // +30% movement speed
val AGILITY_ATTACKSPEED_MAX = 0.20; // +20% attack speed
val MINING_BREAK_MAX = 0.30; // +30% break speed
val MINING_XP_PER_LEVEL = 0.04; // +4% per level => ×5 at L100
val MINING_DROPS_MAX = 1.0; // +100% drops at L100 => ×2
val GATHERING_BREAK_MAX = 0.50; // +50% for wood
val FARMING_MAXHEALTH_MAX = 0.25; // +25% max health
val FARMING_REGEN_PER_MAXHP = 0.02; // 2% max HP per second at L100
val BUILDING_DROPS_MAX = 1.0; // +100% drops at L100 => ×2

// Attribute names
val ATTR_ATTACK = "generic.attackDamage";
val ATTR_ARMOR = "generic.armor";
val ATTR_TOUGHNESS = "generic.armorToughness";
val ATTR_MOVE = "generic.movementSpeed";
val ATTR_ATTACKSPEED = "generic.attackSpeed";
val ATTR_MAXHEALTH = "generic.maxHealth";

// Cache maps (player UUID -> skill levels / applied)
var playerSkillCache = {};
var playerAppliedModifiers = {}; // store applied modifier UUID arrays for removal/replace

// Tick counter for polling
var tickCounter = 0;

// Utility: deterministic UUID integer-array generator (simple hash to 4 ints)
// Returns [I; a, b, c, d] style array for AttributeModifier UUID.
// This is deterministic per player UUID + skillName
function makeUUIDInts(playerUUID as String, skillName as String) {
    // Simple hash method - stable across runs in ZenScript
    var full = playerUUID + ":" + skillName;
    var h = 0;
    for (i = 0; i < full.length(); i++) {
        h = (h * 31 + full.charCodeAt(i)) & 0x7fffffff;
    }
    var a = h;
    var b = (h * 1103515245 + 12345) & 0x7fffffff;
    var c = (h ^ 0xdeadbeef) & 0x7fffffff;
    var d = ((h << 5) ^ 0xabcdef01) & 0x7fffffff;
    return [I; a, b, c, d];
}

//////////////////////////////////////
// Environment-adaptive functions
//////////////////////////////////////

// TODO: Replace/adjust this implementation to call the real Reskillable API exposed to CraftTweaker in your runtime.
// Attempt a few common access patterns and fallback to stored player persistent data if present.
// This function must return an integer level 0..MAX_LEVEL.

function getSkillLevel(player, skillName as String) as int {
    // Attempt common mods.reskillable interface (if exposed)
    try {
        if (mods != null && mods.reskillable != null) {
            // NOTE: the actual CT binding may be mods.reskillable.getLevel(player, skillName)
            // Try some known method names — if they do not exist your runtime will throw and we fall back.
            if (mods.reskillable.getSkillLevel != null) {
                return mods.reskillable.getSkillLevel(player, skillName);
            }
            if (mods.reskillable.getLevel != null) {
                return mods.reskillable.getLevel(player, skillName);
            }
            if (mods.reskillable.getSkillValue != null) {
                return mods.reskillable.getSkillValue(player, skillName);
            }
        }
    } catch (e) {
        // ignore, fallback below
    }

    // Fallback: if Reskillable stores skill levels in player persistent NBT (common mods sometimes do),
    // attempt to read a key like "reskillable:<skillName>" or "reskillable_skill_<name>".
    try {
        var pnbt = player.getPersistentData();
        var key1 = "reskillable:" + skillName;
        var key2 = "reskillable_skill_" + skillName;
        if (pnbt.hasKey(key1)) {
            return pnbt.getInteger(key1);
        }
        if (pnbt.hasKey(key2)) {
            return pnbt.getInteger(key2);
        }
    } catch (e) {
        // ignore
    }

    // If all else fails, return 0
    return 0;
}

// TODO: Implement applyPlayerAttribute and removePlayerAttribute via the real API available.
// The functions below are placeholders; adapt to your environment.
//
// If your CraftTweaker binds PlayerEntity.addAttributeModifier(name, modifier) you can call it here.
// Alternatively, implement game-effect in event handlers (modify final damage on hit, adjust armor calc, etc.)

function applyPlayerAttribute(player, attributeName as String, amount as float, uuidArray) {
    // Placeholder implementation:
    // Try common CT call paths, otherwise just record the desired modifier in a cache
    try {
        // Example pseudocode if the API exists:
        // var modifier = new AttributeModifier(UUID_from_uuidArray, "reskillable_" + attributeName, amount, 1); // operation 1
        // player.getAttribute(attributeName).removeModifier(modifier.getID());
        // player.getAttribute(attributeName).applyModifier(modifier);
        if (player.addAttribute != null) {
            // hypothetical API
            player.addAttribute(attributeName, amount, 1, uuidArray);
            return;
        }
    } catch (e) {
        // ignore - fallback
    }
    // Fallback: store in cache; event handlers should consult this cache to apply final multipliers
    var puid = player.getUniqueID().toString();
    if (!playerAppliedModifiers.containsKey(puid)) {
        playerAppliedModifiers.put(puid, {});
    }
    playerAppliedModifiers.get(puid).put(attributeName, { amt: amount, uuid: uuidArray });
}

// Remove attribute modifier placeholder
function removePlayerAttribute(player, attributeName as String, uuidArray) {
    try {
        if (player.removeAttribute != null) {
            player.removeAttribute(attributeName, uuidArray);
            return;
        }
    } catch (e) {
        // ignore fallback
    }
    var puid = player.getUniqueID().toString();
    if (playerAppliedModifiers.containsKey(puid)) {
        playerAppliedModifiers.get(puid).remove(attributeName);
    }
}

//////////////////////////////////////
// Core: compute multipliers from levels
//////////////////////////////////////

function computeMultipliers(levels) {
    // levels: map of skillName -> int
    var attackLevel = (levels.containsKey("attack") ? levels.get("attack") : 0);
    var defenseLevel = (levels.containsKey("defense") ? levels.get("defense") : 0);
    var agilityLevel = (levels.containsKey("agility") ? levels.get("agility") : 0);
    var miningLevel = (levels.containsKey("mining") ? levels.get("mining") : 0);
    var gatheringLevel = (levels.containsKey("gathering") ? levels.get("gathering") : 0);
    var farmingLevel = (levels.containsKey("farming") ? levels.get("farming") : 0);
    var buildingLevel = (levels.containsKey("building") ? levels.get("building") : 0);
    // compute
    var attackPercent = (attackLevel / (float)MAX_LEVEL) * ATTACK_MAX;
    var armorPercent = (defenseLevel / (float)MAX_LEVEL) * DEFENSE_ARMOR_MAX;
    var toughnessPercent = (defenseLevel / (float)MAX_LEVEL) * DEFENSE_TOUGHNESS_MAX;
    var movePercent = (agilityLevel / (float)MAX_LEVEL) * AGILITY_MOVE_MAX;
    var attackSpeedPercent = (agilityLevel / (float)MAX_LEVEL) * AGILITY_ATTACKSPEED_MAX;
    var breakPercent = (miningLevel / (float)MAX_LEVEL) * MINING_BREAK_MAX;
    var miningXPmult = 1.0 + (miningLevel * MINING_XP_PER_LEVEL); // 1 + 0.04 * level
    var miningDropMult = 1.0 + (miningLevel / (float)MAX_LEVEL) * MINING_DROPS_MAX;
    var gatherPercent = (gatheringLevel / (float)MAX_LEVEL) * GATHERING_BREAK_MAX;
    var farmingHealthPercent = (farmingLevel / (float)MAX_LEVEL) * FARMING_MAXHEALTH_MAX;
    var farmingRegenPerSecond = (farmingLevel / (float)MAX_LEVEL) * FARMING_REGEN_PER_MAXHP; // fraction of max HP per second
    var buildingDropMult = 1.0 + (buildingLevel / (float)MAX_LEVEL) * BUILDING_DROPS_MAX;
    return {
        attackPercent: attackPercent,
        armorPercent: armorPercent,
        toughnessPercent: toughnessPercent,
        movePercent: movePercent,
        attackSpeedPercent: attackSpeedPercent,
        breakPercent: breakPercent,
        miningXPmult: miningXPmult,
        miningDropMult: miningDropMult,
        gatherPercent: gatherPercent,
        farmingHealthPercent: farmingHealthPercent,
        farmingRegenPerSecond: farmingRegenPerSecond,
        buildingDropMult: buildingDropMult
    };
}

//////////////////////////////////////
// Update / Apply per-player modifiers
//////////////////////////////////////

function updatePlayerModifiers(player) {
    var puid = player.getUniqueID().toString();
    // read all relevant skill levels
    var levels = {};
    levels.put("attack", getSkillLevel(player, "attack"));
    levels.put("defense", getSkillLevel(player, "defense"));
    levels.put("agility", getSkillLevel(player, "agility"));
    levels.put("mining", getSkillLevel(player, "mining"));
    levels.put("gathering", getSkillLevel(player, "gathering"));
    levels.put("farming", getSkillLevel(player, "farming"));
    levels.put("building", getSkillLevel(player, "building"));

    // compute multipliers
    var mult = computeMultipliers(levels);

    // store in cache
    playerSkillCache.put(puid, levels);

    // Apply attribute modifiers (placeholder or real API)
    // remove old modifiers first
    removePlayerAttribute(player, ATTR_ATTACK, makeUUIDInts(puid, "attack"));
    removePlayerAttribute(player, ATTR_ARMOR, makeUUIDInts(puid, "defense_armor"));
    removePlayerAttribute(player, ATTR_TOUGHNESS, makeUUIDInts(puid, "defense_tough"));
    removePlayerAttribute(player, ATTR_MOVE, makeUUIDInts(puid, "agility_move"));
    removePlayerAttribute(player, ATTR_ATTACKSPEED, makeUUIDInts(puid, "agility_aspeed"));
    removePlayerAttribute(player, ATTR_MAXHEALTH, makeUUIDInts(puid, "farming_maxhp"));

    // apply new modifiers
    applyPlayerAttribute(player, ATTR_ATTACK, mult.attackPercent, makeUUIDInts(puid, "attack"));
    applyPlayerAttribute(player, ATTR_ARMOR, mult.armorPercent, makeUUIDInts(puid, "defense_armor"));
    applyPlayerAttribute(player, ATTR_TOUGHNESS, mult.toughnessPercent, makeUUIDInts(puid, "defense_tough"));
    applyPlayerAttribute(player, ATTR_MOVE, mult.movePercent, makeUUIDInts(puid, "agility_move"));
    applyPlayerAttribute(player, ATTR_ATTACKSPEED, mult.attackSpeedPercent, makeUUIDInts(puid, "agility_aspeed"));
    applyPlayerAttribute(player, ATTR_MAXHEALTH, mult.farmingHealthPercent, makeUUIDInts(puid, "farming_maxhp"));

    // Farming regen stored in cache for server tick heal use
    if (!playerAppliedModifiers.containsKey(puid)) {
        playerAppliedModifiers.put(puid, {});
    }
    playerAppliedModifiers.get(puid).put("farmingRegenPerSec", mult.farmingRegenPerSecond);
    playerAppliedModifiers.get(puid).put("miningXPmult", mult.miningXPmult);
    playerAppliedModifiers.get(puid).put("miningDropMult", mult.miningDropMult);
    playerAppliedModifiers.get(puid).put("gatherPercent", mult.gatherPercent);
    playerAppliedModifiers.get(puid).put("breakPercent", mult.breakPercent);
    playerAppliedModifiers.get(puid).put("buildingDropMult", mult.buildingDropMult);

    // Send optional message to player about update (commented out)
    // player.sendMessage("Reskillable bonuses updated.");
}

//////////////////////////////////////
// Polling loop + skill-change detection
//////////////////////////////////////

events.onServerTick(function(event as crafttweaker.event.ServerTickEvent) {
    if (event.phase != "END") return;
    tickCounter = tickCounter + 1;
    if (tickCounter % POLL_INTERVAL_TICKS != 0) return;

    // iterate all players
    var players = server.getAllPlayers(); // may need to adapt to your CT server API
    for (i = 0; i < players.size(); i++) {
        var player = players.get(i);
        var puid = player.getUniqueID().toString();

        // read current levels
        var currentLevels = {};
        currentLevels.put("attack", getSkillLevel(player, "attack"));
        currentLevels.put("defense", getSkillLevel(player, "defense"));
        currentLevels.put("agility", getSkillLevel(player, "agility"));
        currentLevels.put("mining", getSkillLevel(player, "mining"));
        currentLevels.put("gathering", getSkillLevel(player, "gathering"));
        currentLevels.put("farming", getSkillLevel(player, "farming"));
        currentLevels.put("building", getSkillLevel(player, "building"));

        var known = playerSkillCache.containsKey(puid) ? playerSkillCache.get(puid) : null;
        var changed = false;
        if (known == null) {
            changed = true;
        } else {
            // compare skills
            var keys = ["attack","defense","agility","mining","gathering","farming","building"];
            for (k = 0; k < keys.length; k++) {
                var key = keys[k];
                var prev = (known.containsKey(key) ? known.get(key) : 0);
                var cur = (currentLevels.containsKey(key) ? currentLevels.get(key) : 0);
                if (prev != cur) {
                    changed = true;
                    break;
                }
            }
        }
        if (changed) {
            updatePlayerModifiers(player);
            // Optionally notify clients to refresh tooltips (client script polls same skill values; no network message needed)
        }
    }
});

//////////////////////////////////////
// Farming heal (once per second)
//////////////////////////////////////

events.onServerTick(function(event as crafttweaker.event.ServerTickEvent) {
    if (event.phase != "END") return;
    tickCounter = tickCounter + 1;
    if (tickCounter % POLL_INTERVAL_TICKS != 0) return;

    // Heal each player based on cached farming regen
    var players = server.getAllPlayers();
    for (i = 0; i < players.size(); i++) {
        var player = players.get(i);
        var puid = player.getUniqueID().toString();
        if (!playerAppliedModifiers.containsKey(puid)) continue;
        var data = playerAppliedModifiers.get(puid);
        var regenFrac = (data.containsKey("farmingRegenPerSec") ? data.get("farmingRegenPerSec") : 0.0);
        if (regenFrac <= 0) continue;
        // compute heal amount: regenFrac * currentMaxHealth
        try {
            var maxHp = player.getMaxHealth();
            var healAmt = maxHp * regenFrac; // per second
            // apply healing
            player.heal(healAmt); // CT call; replace with correct method if different
        } catch (e) {
            // ignore if method not available
        }
    }
});

//////////////////////////////////////
// Block break / drops / XP handlers (placeholders)
//
// Implementation note: CraftTweaker's event APIs differ between environments.
// Below are template stubs showing where to implement logic. Replace with the exact event names/fields
// your CT runtime exposes (Forge events: PlayerEvent.BreakSpeed, HarvestDropsEvent, etc.).
//////////////////////////////////////

// Template: Break speed modification
// Replace the following stub with your environment's break-speed event handler.
// In the handler, read the player's breakPercent or gatherPercent from playerAppliedModifiers and multiply speed.
events.onPlayerTick(function(event as crafttweaker.event.PlayerTickEvent) {
    // This is NOT the most efficient spot to do per-break adjustments,
    // but it's a safe fallback location for some CT runtimes that do not expose BreakSpeed events.
    // If your environment exposes BreakSpeed event, implement there instead.
    // (Left empty by default.)
});

// Template: Harvest drops and XP modification
// You need to find the CraftTweaker/CT wrapper for BlockEvent.HarvestDropsEvent / LivingExperienceDropEvent
// and apply the stored multipliers:
// - newCount = floor(oldCount * buildingDropMult or miningDropMult)
// - XP = floor(oldXP * miningXPmult)
//
// Because CT wrapper names differ, I leave a clear TODO for you to replace with the correct handler.
#/* TODO:
events.onHarvestDrops(function(event) {
    var player = event.getHarvester();
    if (player == null) return;
    var puid = player.getUniqueID().toString();
    if (!playerAppliedModifiers.containsKey(puid)) return;
    var data = playerAppliedModifiers.get(puid);
    // Decide whether to use miningDropMult OR buildingDropMult depending on block type and what skill applies
    // Multiply event.getDrops() counts accordingly (use integer rounding + chance for fractional remainder).
    // Multiply event.getXp() by data.miningXPmult if mining.
});
*/#

print("reskillable_bonuses_server.zs loaded (template).");