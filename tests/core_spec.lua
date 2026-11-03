-- The turn-in route: Core/Core.lua against stubbed client frames, Questie and Shortest Path.
local frame = { RegisterEvent = function() end, SetScript = function() end }
_G.CreateFrame = function()
	return frame
end
local sent
local ns = {
	Model = {
		IsCommissionQuest = function(name)
			return name == "Feathers for Nafien"
		end,
	},
	Questie = {
		NPC = function(npcID)
			return { name = "NPC " .. npcID, map = 1, x = 0.5, y = 0.5 }
		end,
	},
	ShortestPath = {
		Navigate = function(_, stops)
			sent = stops
			return true
		end,
	},
}
assert(loadfile("Core/Core.lua"))("CommissionsForever", ns)

local function Route(objectives)
	sent = nil
	ns.ActiveObjectives = objectives
	return ns.NavigateActiveAssignments()
end

assert(
	Route({ { questName = "Feathers for Nafien", finished = true, npcIDs = { 7 } } }) and #sent == 1,
	"a commission ready to hand in routes to its finisher"
)
assert(
	Route({ { questName = "Feathers for Nafien", finished = false, npcIDs = { 7 } } }) and #sent == 1,
	"a commission still being collected routes to its finisher"
)
assert(Route({
	{ questName = "Feathers for Nafien", finished = true, npcIDs = { 7 } },
	{ questName = "Feathers for Nafien", finished = false, npcIDs = { 7 } },
}) and #sent == 1, "a finisher shared by two objectives is one stop")
assert(
	not Route({ { questName = "The Missing Diplomat", finished = true, npcIDs = { 8 } } }) and sent == nil,
	"an unrelated quest sends no route"
)
print("Commissions Forever core specs passed")
