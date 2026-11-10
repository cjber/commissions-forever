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

	-- Forever Core's shared report and debug log.
	["Commissions Forever report"] = true,
	["Bug"] = true,
	["Bug: "] = true,
	["Copy issue link"] = true,
	["Copy report"] = true,
	["Feature request"] = true,
	["Feature request: "] = true,
	["Report a bug or request a feature"] = true,
	["Title"] = true,
	["What happened, or what you would like"] = true,
	["The link is selected. Press Ctrl+C (Cmd+C on a Mac), then paste into a browser; GitHub opens a filled-in issue."] = true,
	["The text is selected. Press Ctrl+C (Cmd+C on a Mac) to copy it, then paste it into your bug report."] = true,
	["Debug log is off."] = true,
	["Debug log is on for this session."] = true,
	["Debug log is on and pinned for this character."] = true,
	["Debug log is already on and pinned for this character."] = true,
	["Debug log is off for this session; it is still pinned."] = true,
	["Debug log is off and unpinned."] = true,
	["No addon has attached its log yet."] = true,
	["%s (last %d):"] = true,
	["%s: no lines yet."] = true,
	["Usage: /forever debug, /forever debug pin, /forever debug off, /forever debug show"] = true,

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
