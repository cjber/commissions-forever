local ns = {
	TurnIns = {
		{ key = "a", items = { 1, 2 }, quest = "Craftsman's Writ" },
		{ key = "b", items = { 3 }, quest = "Logistics Task Briefing", questAliases = { "Un'Goro Soil" } },
	},
}
local chunk = assert(loadfile("Core/Model.lua"))
chunk("CommissionsForever", ns)
local rows = ns.Model.Inventory(function(itemID)
	return itemID == 1 and 4 or 0
end)
assert(#rows == 1 and rows[1].itemID == 1 and rows[1].count == 4, "only held items are returned")
assert(ns.Model.IsCommissionQuest("Craftsman's Writ - Runecloth Robe"), "matches writ quest names")
assert(ns.Model.IsCommissionQuest("Logistics Task Briefing IV"), "matches variable logistics assignments")
assert(ns.Model.IsCommissionQuest("Un'Goro Soil"), "matches Morrowgrain soil deliveries")
assert(not ns.Model.IsCommissionQuest("The Missing Diplomat"), "does not route unrelated quests")
ns.ActiveObjectives = {
	{ questID = 10, questName = "Logistics Task Briefing IV", itemID = 50, required = 8 },
	{ questID = 11, questName = "The Missing Diplomat", itemID = 51, required = 1 },
}
rows = ns.Model.Inventory(function(itemID)
	return itemID == 50 and 3 or 0
end)
assert(#rows == 1 and rows[1].questID == 10 and rows[1].need == 8, "adds active commission requirements only")
print("Commissions Forever model specs passed")
