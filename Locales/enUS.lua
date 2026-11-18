local _, ns = ...

---@type table<string, string | boolean>
ns.L = {
	["Commissions Forever"] = true,
	["No tracked materials found"] = true,
	["Open turn-in route"] = true,
	["Install QuestieDB to find where your commissions are handed in."] = true,
	["QuestieDB cannot tell which of your quests are commissions. Update QuestieDB."] = true,
	["No quest in your log is a commission. Accept one, then try again."] = true,
	["QuestieDB does not know where your commissions are handed in."] = true,
	["Install Shortest Path Forever to get a turn-in route."] = true,
	["Shortest Path Forever could not start the route."] = true,
	["Install QuestieDB to see your active turn-ins."] = true,
	["Commissions opens when combat ends."] = true,
	["Commissions opens in the Professions window. Learn a profession to use it."] = true,
	["Commissions opens in the Professions window. Open it from your spellbook."] = true,
	["Material"] = true,
	["Turn-in"] = true,
	["Have"] = true,
	["Need"] = true,
	["Item %d"] = true,

	-- The shared report window's title; ForeverCore owns its other phrases.
	["Commissions Forever report"] = true,

	-- The shared out-of-date warning (Core/ForeverRequire.lua).
	["%s needs ForeverCore. Install it from CurseForge, or choose Reinstall on ForeverCore in the CurseForge app."] = true,
	["%s: ForeverCore is turned off. Enable it in the AddOns list to fix this."] = true,
	["%s: the installed ForeverCore is another addon (%s). Remove it and install ForeverCore from CurseForge."] = true,
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
