local _, ns = ...

---@type table<string, string | boolean>
ns.L = {
	["Commissions Forever"] = true,
	["No tracked materials found"] = true,
	["Open turn-in route"] = true,
	["No active commission route is available."] = true,
	["Install QuestieDB to see your active turn-ins."] = true,
	["Commissions opens when combat ends."] = true,
	["Commissions opens in the Professions window. Learn a profession to use it."] = true,
	["Commissions opens in the Professions window. Open it from your spellbook."] = true,
	["Material"] = true,
	["Turn-in"] = true,
	["Have"] = true,
	["Need"] = true,
	["Item %d"] = true,
	["Leaderboard"] = true,
	["Share my progress"] = true,
	["On unless you turn it off. Shares commission totals and puts you on Forever Leaderboards."] = true,
	["Already shared totals cannot be recalled."] = true,
	["Commission turn-ins"] = true,
	["total"] = true,

	-- The shared report window's title; Forever Core owns its other phrases.
	["Commissions Forever report"] = true,

	-- The shared out-of-date warning (Core/ForeverRequire.lua).
	["%s: %s is out of date. Update it to fix this."] = true,
	["%s: %s are out of date. Update them to fix this."] = true,
	["%s could not start. Reinstall %s to fix this."] = true,
}

-- `true` marks a phrase that reads as its own English key.
for key, value in pairs(ns.L) do
	if value == true then
		ns.L[key] = key
	end
end
