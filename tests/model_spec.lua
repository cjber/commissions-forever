local ns = {
	TurnIns = {
		{ key = "a", items = { 1, 2 } },
		{ key = "b", items = { 3 } },
	},
}
-- QuestieDB's classifier answers per quest ID. A title is never consulted.
local categories = {}
ns.Questie = {
	CommissionCategory = function(questID)
		return categories[questID]
	end,
}
local chunk = assert(loadfile("Core/Model.lua"))
chunk("CommissionsForever", ns)
local rows = ns.Model.Inventory(function(itemID)
	return itemID == 1 and 4 or 0
end, {})
assert(#rows == 1 and rows[1].itemID == 1 and rows[1].count == 4, "only held items are returned")
assert(rows[1].category == "a", "an inventory row names its turn-in category")

-- A quest whose title contains a turn-in's name but whose QuestieDB row is not a commission is not shown; a commission
-- whose title matches nothing is shown. Only the quest ID decides (cjber/commissions-forever#200).
categories[10] = "b"
rows = ns.Model.Inventory(function(itemID)
	return itemID == 50 and 3 or 0
end, {
	{ questID = 11, questName = "Craftsman's Writ - Runecloth Robe", itemID = 50, required = 8 },
	{ questID = 10, questName = "Grandma's Cookie Recipe", itemID = 51, required = 2 },
})
assert(#rows == 1 and rows[1].questID == 10, "only the classified quest is shown, whatever its title")
assert(rows[1].category == "b" and rows[1].need == 2, "the active row keeps its category and live requirement")
-- A starter item that belongs to a turn-in does not classify a quest by itself either.
rows = ns.Model.Inventory(function()
	return 0
end, { { questID = 12, questName = "Bandages for the Field", sourceItemID = 20806, itemID = 52, required = 30 } })
assert(#rows == 0, "an unclassified quest is not shown even with a turn-in's starter item")

-- The objectives come from the caller; a namespace field of the same name is never read.
ns.ActiveObjectives = { { questID = 10, questName = "Grandma's Cookie Recipe", itemID = 52, required = 2 } }
rows = ns.Model.Inventory(function(itemID)
	return itemID == 50 and 3 or 0
end, { { questID = 10, itemID = 50, required = 8 } })
assert(#rows == 1 and rows[1].questID == 10 and rows[1].need == 8, "adds the given active commission requirements only")
categories[13] = "b"
rows = ns.Model.Inventory(function(itemID)
	return itemID == 3 and 3 or 0
end, { { questID = 13, questName = "Logistics Task Briefing V", itemID = 3, required = 6 } })
assert(
	#rows == 1 and rows[1].questID == 13 and rows[1].count == 3 and rows[1].need == 6,
	"an item an active commission asks for is listed once, on its Have / Need row"
)

-- Materials: fresh rows in the published shape, never the internal turnIn table.
local materials = ns.Model.Materials(rows)
assert(materials[1] ~= rows[1] and materials[1].turnIn == nil, "materials are fresh rows without the internal turn-in")
assert(
	materials[1].category == "b"
		and materials[1].itemID == 3
		and materials[1].have == 3
		and materials[1].need == 6
		and materials[1].questID == 13,
	"materials carry the fields the API publishes"
)
materials[1].have = 99
assert(rows[1].count == 3, "changing a material row does not change the window's rows")

-- The shipped catalogue no longer carries titles: a turn-in names its category, faction, place and items only.
local catalogue = {}
assert(loadfile("Data/TurnIns.lua"))("CommissionsForever", catalogue)
for _, turnIn in ipairs(catalogue.TurnIns) do
	assert(turnIn.quest == nil and turnIn.questAliases == nil, "turn-in " .. turnIn.key .. " carries no title matcher")
end
catalogue.Questie = {
	CommissionCategory = function(questID)
		return questID == 8496 and "cenarionCircle" or nil
	end,
}
assert(loadfile("Core/Model.lua"))("CommissionsForever", catalogue)
rows = catalogue.Model.Inventory(function()
	return 0
end, {
	{ questID = 8496, questName = "Bandages for the Field", sourceItemID = 20806, itemID = 14529, required = 30 },
})
assert(
	#rows == 1 and rows[1].category == "cenarionCircle" and rows[1].need == 30,
	"a Logistics assignment counts as its classified category"
)
print("Commissions Forever model specs passed")
