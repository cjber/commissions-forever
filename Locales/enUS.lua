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
	["Leaderboard"] = true,
	["Share my progress"] = true,
	["On unless you turn it off. Shares commission totals and puts you on Forever Leaderboards."] = true,
	["Already shared totals cannot be recalled."] = true,
	["Commission turn-ins"] = true,
	["total"] = true,

	-- Forever Leaderboards (Forever Core's shared window).
	["Forever Leaderboards"] = true,
	["Overall"] = true,
	["Forever standing"] = true,
	["Your guild and group"] = true,
	["This week"] = true,
	["All time"] = true,
	["Rank"] = true,
	["Player"] = true,
	["No one has reported yet."] = true,
	["Others' values are player-reported."] = true,
	["Points for placing on each addon's board."] = true,
	["(you)"] = true,
	["board"] = true,
	["boards"] = true,
	["Uses Forever addons"] = true,
	["Forever: %s overall this week"] = true,
	["Forever: %s overall"] = true,
	["1st"] = true,
	["2nd"] = true,
	["3rd"] = true,
	["4th"] = true,
	["5th"] = true,
	["6th"] = true,
	["7th"] = true,
	["8th"] = true,
	[", "] = true,
}

-- `true` marks a phrase that reads as its own English key.
for key, value in pairs(ns.L) do
	if value == true then
		ns.L[key] = key
	end
end
