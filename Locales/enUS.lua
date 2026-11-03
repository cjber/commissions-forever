local _, ns = ...

---@type table<string, string | boolean>
ns.L = {
	["Commissions Forever"] = true,
	["No tracked materials found"] = true,
	["Open turn-in route"] = true,
	["No active commission route is available."] = true,
	["Install QuestieDB to see your active turn-ins."] = true,
	["Material"] = true,
	["Turn-in"] = true,
	["Have"] = true,
	["Need"] = true,
	["Item %d"] = true,
	["Observed commission turn-ins: guild and group"] = true,
	["Current client ruleset only. Other players' totals are player-reported."] = true,
	["%d. %s: %d (you)"] = true,
	["%d. %s: %d (player-reported)"] = true,
	["Ruleset unavailable. Only your personal record is shown."] = true,
	["Sharing is off. Only your personal record is shown."] = true,
	["Install QuestieDB to record supported commission turn-ins."] = true,
	["Leaderboard"] = true,
	["Share totals with guild and group"] = true,
	["Stop sending and receiving totals. Keep your history. Already shared totals cannot be recalled."] = true,
}

-- `true` marks a phrase that reads as its own English key.
for key, value in pairs(ns.L) do
	if value == true then
		ns.L[key] = key
	end
end
