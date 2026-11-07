-- The turn-in route: Core/Core.lua against stubbed client frames, Questie and Shortest Path.
local frame = {
	RegisterEvent = function() end,
	SetScript = function(self, event, handler)
		self[event] = handler
	end,
}
_G.CreateFrame = function()
	return frame
end
local sent
local ns = {
	Model = {
		IsCommissionQuest = function(name)
			return name == "Feathers for Nafien"
		end,
		Inventory = function()
			return {}
		end,
	},
	Questie = {
		ActiveObjectives = function()
			return {}
		end,
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

-- The leaderboard command opens the shared window on this addon's tab and writes nothing to chat.
_G.SlashCmdList = {}
local opened, shared
ns.Stats = {
	Open = function()
		opened = true
	end,
	SetEnabled = function(enabled)
		shared = enabled
	end,
}
frame.OnEvent(frame, "PLAYER_LOGIN")
SlashCmdList.COMMISSIONSFOREVER("leaderboard")
assert(opened, "leaderboard opens Forever Leaderboards")
opened = false
SlashCmdList.COMMISSIONSFOREVER("stats")
assert(opened, "stats is an alias")
opened = false
SlashCmdList.COMMISSIONSFOREVER("share off")
assert(shared == false and not opened, "share off turns sharing off without opening the window")
SlashCmdList.COMMISSIONSFOREVER("share on")
assert(shared == true, "share on turns sharing back on")
print("Commissions Forever core specs passed")
