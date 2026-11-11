-- The turn-in route: Core/Core.lua against stubbed client frames, Questie and Shortest Path.
local Toc = dofile("tests/toc.lua")
Toc.install(_G, "CommissionsForever")
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
	L = setmetatable({}, {
		__index = function(_, key)
			return key
		end,
	}),
	Model = {
		Inventory = function()
			return {}
		end,
	},
	Questie = {
		CommissionCategory = function(questID)
			return questID == 7 and "timbermawHold" or nil
		end,
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
-- The one ForeverCore service Core/Core.lua registers: its report window and the saved table Attach takes.
local attached
_G.ForeverCore = {
	Register = function(name, spec)
		assert(name == "CommissionsForever", "registers under the addon's folder name")
		assert(spec.title == "Commissions Forever report", "registers the addon's report title")
		assert(spec.lines == ns.ReportLines, "registers the addon's own report lines")
		return {
			Attach = function(db)
				attached = db
			end,
			Report = {
				Command = function(command)
					return command == "report"
				end,
			},
		}
	end,
}
assert(loadfile("Core/Report.lua"))("CommissionsForever", ns)
assert(loadfile("Core/Core.lua"))("CommissionsForever", ns)
local identity = Toc.get("CommissionsForever", "X-Forever-Icon")
assert(identity and identity ~= "", "the TOC declares the addon's identity icon")
assert(ns.ICON == identity, "Core reads the TOC's identity icon once onto the namespace")

local function Route(objectives)
	sent = nil
	ns.ActiveObjectives = objectives
	return ns.NavigateActiveAssignments()
end

assert(
	Route({ { questID = 7, finished = true, npcIDs = { 7 } } }) and #sent == 1,
	"a commission ready to hand in routes to its finisher"
)
assert(
	Route({ { questID = 7, finished = false, npcIDs = { 7 } } }) and #sent == 1,
	"a commission still being collected routes to its finisher"
)
assert(Route({
	{ questID = 7, finished = true, npcIDs = { 7 } },
	{ questID = 7, finished = false, npcIDs = { 7 } },
}) and #sent == 1, "a finisher shared by two objectives is one stop")
-- A title never routes a quest: only QuestieDB's classification of its ID does (cjber/commissions-forever#200).
assert(
	not Route({ { questID = 8, questName = "Feathers for Nafien", finished = true, npcIDs = { 8 } } }) and sent == nil,
	"a quest whose title matches a turn-in but is not classified sends no route"
)
assert(
	Route({ { questID = 7, questName = "The Missing Diplomat", finished = true, npcIDs = { 7 } } }) and #sent == 1,
	"a classified commission routes whatever its title"
)
assert(
	not Route({ { questID = 8, finished = true, npcIDs = { 8 } } }) and sent == nil,
	"an unrelated quest sends no route"
)

-- Every refresh tells the API's hub that the rows may have changed; the hub compares them itself.
local announced
ns.APIChanged = function(kind)
	announced = kind
end
frame.OnEvent(frame, "BAG_UPDATE_DELAYED")
assert(announced == "refresh" and ns.Refreshed == true, "a refresh is announced to the API's hub")

-- Any command the shared report does not claim opens the Commissions page, including the commands Forever
-- Leaderboards used to have.
_G.SlashCmdList = {}
local toggled
ns.Window = {
	Toggle = function()
		toggled = true
	end,
}
frame.OnEvent(frame, "PLAYER_LOGIN")
assert(attached == CommissionsForeverDB, "PLAYER_LOGIN hands the saved table to Forever Core")
for _, command in ipairs({ "leaderboard", "stats", "share off" }) do
	toggled = false
	SlashCmdList.COMMISSIONSFOREVER(command)
	assert(toggled, command .. " falls through to opening the Commissions page")
end
print("Commissions Forever core specs passed")
