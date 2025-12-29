// Client-side Reskillable tooltip script (CraftTweaker / ZenScript template)
//
// Place this file on EVERY CLIENT at scripts/reskillable_bonuses_client.zs
//
// What this script does (client-side):
// - Polls Reskillable skill levels once per second (fallback) or listens to client-side Reskillable change event if available.
// - When the held item changes or skill changes, computes the final absolute number for the relevant stat for the local player
//   and injects a tooltip line (local-only display).
//
// Important placeholders (YOU MAY NEED TO ADAPT):
// - getSkillLevel(player, skillName): same approach as server script. Try the mods.reskillable API; otherwise fallback to persistent NBT.
// - readItemBaseAttack(itemStack): attempts to read generic.attackDamage base attribute from ItemStack. If not available for some mod items,
//   the tooltip will show nothing (or you can extend the mapping manually).
// - setItemTooltipLocal(itemStack, line): attempts to add a dynamic tooltip line without modifying server ItemStack lore persistently.
//   If your CT doesn't provide a direct client tooltip API, we emulate by temporarily setting the ItemStack display.Lore on the client only
//   while held (be cautious: in multiplayer inventories this may sync to server; to avoid that, prefer an actual client tooltip hook if present).
//
// This script is deliberately cautious and heavily commented. Test it and tell me any missing CT functions and I'll adapt.

print("reskillable_bonuses_client.zs loading...");

// Polling interval
val TICKS_PER_SECOND = 20;
val POLL_INTERVAL_TICKS = 20;

var tickCounter = 0;
var lastHeldItemId = "";
var lastSkillSnapshot = {}; // map skill->level

// Attempt the same getSkillLevel routine as server script (client adaptation)
function getSkillLevel(player, skillName as String) as int {
    try {
        if (mods != null && mods.reskillable != null) {
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
        // ignore
    }
    try {
        var pnbt = player.getPersistentData();
        var key1 = "reskillable:" + skillName;
        var key2 = "reskillable_skill_" + skillName;
        if (pnbt.hasKey(key1)) return pnbt.getInteger(key1);
        if (pnbt.hasKey(key2)) return pnbt.getInteger(key2);
    } catch (e) {
        // ignore
    }
    return 0;
}

// Read base attack of an ItemStack if available
function readItemBaseAttack(itemStack as IItemStack) as float {
    try {
        // Attempt to read attribute modifier on the item stack
        if (itemStack.getAttributeModifiers != null) {
            var map = itemStack.getAttributeModifiers(); // may return a map
            if (map.containsKey(ATTR_ATTACK)) {
                // If map value is an array of modifiers, try to get base
                var modifiers = map.get(ATTR_ATTACK);
                if (modifiers.size() > 0) {
                    // Many modifiers include Amount; but base damage may be in item definition. We'll best-effort return the first amount
                    return modifiers.get(0).getAmount();
                }
            }
        }
    } catch (e) {
        // ignore
    }
    // Fallback: try well-known CT field
    try {
        if (itemStack.getDamageVsEntity != null) {
            return itemStack.getDamageVsEntity();
        }
    } catch (e) {
        // ignore
    }
    return 0.0;
}

// Compute final attack for a held item and local player
function computeAndShowTooltipForHeldItem(player) {
    var held = player.getHeldItemMainhand();
    if (held == null || held.isEmpty()) {
        return;
    }
    var baseAttack = readItemBaseAttack(held);
    if (baseAttack <= 0) {
        // we cannot compute meaningful absolute; skip quietly
        return;
    }
    var attackLevel = getSkillLevel(player, "attack");
    var attackPercent = (attackLevel / (float)100) * 0.50; // ATTACK_MAX
    var finalAttack = Math.round(baseAttack * (1.0 + attackPercent));
    var line = "Attack +" + finalAttack; // final absolute only as requested
    // Attempt to show this line in tooltip. The best approach is to register a tooltip hook if CT supports it.
    // If not, we temporarily set client-side display Lore while the item is held (be careful: this might sync in multiplayer).
    try {
        // If client supports a tooltip injection event:
        if (events.onTooltip != null) {
            // Example usage (pseudocode)
            // events.onTooltip(function(e) { if (e.getItem() == held) e.add(line); });
            // But API differs; so fallback below
        }
    } catch (e) {
        // ignore
    }

    // Fallback: modify the item stack display.Lore locally while held (client-only)
    try {
        var newStack = held.withTag({display: {Lore: [line]}});
        player.setHeldItemMainhand(newStack);
        // Note: if this syncs to the server it may overwrite. If that happens we should switch to a real tooltip hook.
    } catch (e) {
        // ignore - if we can't set it, the environment lacks the calls
    }
}

// Polling + held item change detection
events.onPlayerTick(function(event as crafttweaker.event.PlayerTickEvent) {
    var player = event.player;
    if (player == null) return;
    tickCounter = tickCounter + 1;
    // Update on held item change immediately
    try {
        var held = player.getHeldItemMainhand();
        var id = held == null || held.isEmpty() ? "" : held.getItem().getRegistryName().toString();
        if (id != lastHeldItemId) {
            lastHeldItemId = id;
            computeAndShowTooltipForHeldItem(player);
        }
    } catch (e) {
        // ignore
    }

    if (tickCounter % POLL_INTERVAL_TICKS != 0) return;

    // Poll skill changes (client-side)
    var keys = ["attack","defense","agility","mining","gathering","farming","building"];
    var changed = false;
    for (i = 0; i < keys.length; i++) {
        var k = keys[i];
        var cur = getSkillLevel(player, k);
        var prev = (lastSkillSnapshot.containsKey(k) ? lastSkillSnapshot.get(k) : -1);
        if (cur != prev) {
            changed = true;
            lastSkillSnapshot.put(k, cur);
        }
    }
    if (changed) {
        // recompute tooltip for held item and armor
        computeAndShowTooltipForHeldItem(player);
    }
});

print("reskillable_bonuses_client.zs loaded (template).");