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

-- What the route reads: QuestieDB, the log's commissions with their finishers, and Shortest Path Forever.
local questie, commissions, installed, accepts = true, {}, true, true
ns.Questie.Available = function()
	return questie
end
ns.Questie.ActiveCommissions = function()
	return commissions
end
ns.ShortestPath.Installed = function()
	return installed
end
ns.ShortestPath.Navigate = function(_, stops)
	sent = stops
	return accepts
end

local function Route(list)
	sent, commissions = nil, list
	return ns.NavigateActiveAssignments()
end

assert(Route({ { questID = 7, npcIDs = { 7 } } }) and #sent == 1, "a commission routes to its finisher")
-- The route never reads the window's item rows: a commission with no item objective has none and still routes
-- (cjber/commissions-forever#350).
ns.ActiveObjectives = {}
assert(Route({ { questID = 7, npcIDs = { 7 } } }) and #sent == 1, "a commission with no item row routes")
assert(
	Route({ { questID = 7, npcIDs = { 7 } }, { questID = 9, npcIDs = { 7, 9 } } }) and #sent == 2,
	"a finisher shared by two commissions is one stop"
)

-- Each way the route cannot start names its own reason, so the window can tell the player what to do.
local function Refused(list, want, name)
	local ok, reason = Route(list)
	assert(ok == false and reason == want, name .. ": got " .. tostring(ok) .. ", " .. tostring(reason))
end
questie = false
Refused({ { questID = 7, npcIDs = { 7 } } }, "questie", "no QuestieDB")
questie = true
Refused({}, "none", "no commission in the log")
assert(sent == nil, "no commission sends nothing")
local npc = ns.Questie.NPC
ns.Questie.NPC = function(npcID)
	return { name = "NPC " .. npcID }
end
Refused({ { questID = 7, npcIDs = { 7 } } }, "unplaced", "no finisher has a place")
Refused({ { questID = 7, npcIDs = {} } }, "unplaced", "no finisher at all")
ns.Questie.NPC = npc
installed = false
Refused({ { questID = 7, npcIDs = { 7 } } }, "shortestPath", "no Shortest Path Forever")
assert(sent == nil, "nothing is sent without Shortest Path Forever")
installed = true
accepts = false
Refused({ { questID = 7, npcIDs = { 7 } } }, "declined", "Shortest Path Forever declined")
accepts = true

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
assert(attached == CommissionsForeverDB, "PLAYER_LOGIN hands the saved table to ForeverCore")
for _, command in ipairs({ "leaderboard", "stats", "share off" }) do
	toggled = false
	SlashCmdList.COMMISSIONSFOREVER(command)
	assert(toggled, command .. " falls through to opening the Commissions page")
end
print("Commissions Forever specs passed")
