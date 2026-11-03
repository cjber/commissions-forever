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
end, {})
assert(#rows == 1 and rows[1].itemID == 1 and rows[1].count == 4, "only held items are returned")
assert(ns.Model.IsCommissionQuest("Craftsman's Writ - Runecloth Robe"), "matches writ quest names")
assert(ns.Model.IsCommissionQuest("Logistics Task Briefing IV"), "matches variable logistics assignments")
assert(ns.Model.IsCommissionQuest("Un'Goro Soil"), "matches Morrowgrain soil deliveries")
assert(not ns.Model.IsCommissionQuest("The Missing Diplomat"), "does not route unrelated quests")
local objectives = {
	{ questID = 10, questName = "Logistics Task Briefing IV", itemID = 50, required = 8 },
	{ questID = 11, questName = "The Missing Diplomat", itemID = 51, required = 1 },
}
-- The objectives come from the caller; a namespace field of the same name is never read.
ns.ActiveObjectives = { { questID = 12, questName = "Craftsman's Writ - Runecloth Robe", itemID = 52, required = 2 } }
rows = ns.Model.Inventory(function(itemID)
	return itemID == 50 and 3 or 0
end, objectives)
assert(#rows == 1 and rows[1].questID == 10 and rows[1].need == 8, "adds the given active commission requirements only")
rows = ns.Model.Inventory(function(itemID)
	return itemID == 3 and 3 or 0
end, { { questID = 13, questName = "Logistics Task Briefing V", itemID = 3, required = 6 } })
assert(
	#rows == 1 and rows[1].questID == 13 and rows[1].count == 3 and rows[1].need == 6,
	"an item an active commission asks for is listed once, on its Have / Need row"
)
-- Real catalogue matching: briefings identify Logistics quests with different titles.
local catalogue = {}
assert(loadfile("Data/TurnIns.lua"))("CommissionsForever", catalogue)
assert(loadfile("Core/Model.lua"))("CommissionsForever", catalogue)
assert(catalogue.Model.IsCommissionQuest("Bandages for the Field", 20806), "briefing identifies Logistics quest")
assert(catalogue.Model.IsCommissionQuest("Beads for Salfa"), "Timbermaw matches the quest rather than its item name")
assert(catalogue.Model.IsCommissionQuest("Feathers for Grazle"), "both feather delivery NPCs are supported")
assert(not catalogue.Model.IsCommissionQuest("The Missing Diplomat", 21105), "Draconic for Dummies is not a briefing")
rows = catalogue.Model.Inventory(function()
	return 0
end, {
	{ questID = 8496, questName = "Bandages for the Field", sourceItemID = 20806, itemID = 14529, required = 30 },
})
assert(#rows == 1 and rows[1].need == 30, "Logistics objectives retain their live requirements")
print("Commissions Forever model specs passed")
