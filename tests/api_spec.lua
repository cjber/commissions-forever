-- Run from the repository root: luajit tests/api_spec.lua
-- CommissionsForever.API against stubbed internals, with the addon's own refresh and hub. The not-ready answers come
-- from ForeverCore's own kit, loaded from the checkout FOREVER_CORE names (tests/forever_core.lua finds it), as the
-- client loads it before this addon.
local core = dofile("tests/forever_core.lua")

-- ForeverCore as Core/API.lua sees it at load. The kit is loaded from its own file into a namespace of its own:
-- SafeCallFor keeps the kit whole, NotReady is the member the reads use, and Hub is the subscription the API
-- publishes.
local kitNamespace = {
	SafeCallFor = function()
		return {
			SafeCall = function(_, _, callback, ...)
				return callback(...)
			end,
		}
	end,
}
local kitEnvironment = setmetatable({}, { __index = _G })
local kitChunk = assert(loadfile(core.directory() .. "/Core/APIKit.lua"))
setfenv(kitChunk, kitEnvironment)
kitChunk("ForeverCore", kitNamespace)
local kit = assert(kitNamespace.APIKit, "ForeverCore's API kit loads")
local foreverCore = { APIKit = kit }
rawset(_G, "ForeverCore", foreverCore)

-- The hub asks for one dispatch on the next frame; this stands in for the client's timer.
local timers = {}
rawset(_G, "C_Timer", {
	After = function(_, callback)
		timers[#timers + 1] = callback
	end,
})
local function nextFrame()
	local due = timers
	timers = {}
	for _, callback in ipairs(due) do
		callback()
	end
end

-- Core/Core.lua and Core/Stats.lua each build their own event frame; the client creates a frame per call.
local frames = {}
rawset(_G, "CreateFrame", function()
	local frame = {
		RegisterEvent = function() end,
		SetScript = function(self, _, handler)
			self.handler = handler
		end,
	}
	frames[#frames + 1] = frame
	return frame
end)
local function fire(event, ...)
	for _, frame in ipairs(frames) do
		if frame.handler then
			frame.handler(frame, event, ...)
		end
	end
end
local counts = {}
rawset(_G, "C_Item", {
	GetItemCount = function(itemID)
		return counts[itemID] or 0
	end,
})

-- Core/Core.lua reads the TOC's identity icon and hands the saved table to Forever Core.
local Toc = dofile("tests/toc.lua")
Toc.install(_G, "CommissionsForever")

-- Fresh rows every call, as the modules under the API hand them out.
local materials
local objectives = {}
local categories = {}
local questieAvailable = true
local routed = false
local ns = {
	TurnIns = {
		{ key = "thoriumBrotherhood", faction = "Thorium Brotherhood", items = { 11370 } },
	},
	Stats = {
		Activity = function()
			return { { addon = "CommissionsForever", metric = "commission_turnin", subject = "all", value = 3 } }
		end,
	},
	SkillUp = {
		RequiredMaterials = function(recipeID, crafts)
			assert(recipeID == 1234 and crafts == 2, "forwards the recipe and craft count")
			return materials
		end,
	},
	Questie = {
		Available = function()
			return questieAvailable
		end,
		ActiveObjectives = function()
			return objectives
		end,
		CommissionCategory = function(questID)
			return categories[questID]
		end,
	},
}
foreverCore.Register = function(name)
	assert(name == "CommissionsForever", "registers under the addon's folder name")
	return {
		Attach = function() end,
		SafeCall = function(_, _, callback, ...)
			return callback(...)
		end,
		Report = {
			Command = function()
				return false
			end,
		},
	}
end
-- The real model classifies by quest ID, as the window does.
assert(loadfile("Core/Model.lua"))("CommissionsForever", ns)
-- The real refresh wires the game's bag and quest log events to the rows the API reads.
assert(loadfile("Core/Core.lua"))("CommissionsForever", ns)
-- The route belongs to Core/Core.lua and has its own spec; here only the API's forward is checked.
ns.NavigateActiveAssignments = function()
	return routed
end
local chunk = assert(loadfile("Core/API.lua"))
local API = chunk("CommissionsForever", ns)

assert(API.version == 2 and API.minor == 0, "publishes version 2, minor 0")
assert(API.Leaderboard == nil, "the board member is removed")
assert(_G.CommissionsForever.API == API and ns.API == API, "publishes the table on the addon's global")

-- The kit's own list finds this addon through the real kit, with the API's own version, minor and table.
local listed
for _, entry in ipairs(kit.Addons()) do
	if entry.name == "CommissionsForever" then
		listed = entry
	end
end
assert(listed ~= nil, "ForeverCore.APIKit.Addons() lists CommissionsForever")
assert(listed.version == API.version and listed.minor == API.minor, "with the API's own version and minor")
assert(listed.api == API, "and the API's own table, not a copy")

-- A read with an answer is unchanged: the kit is only read when there is nothing to answer.
materials = { { itemID = 17203, count = 2 } }
assert(API.RequiredMaterials(1234, 2) == materials, "returns SkillUp Forever's fresh materials")
objectives = { { questID = 99, itemID = 7, finished = false, npcIDs = {} } }
assert(API.ActiveObjectives()[1].questID == 99, "returns the log's live item objectives")
routed = true
assert(API.NavigateActiveAssignments(), "forwards turn-in routes to Shortest Path Forever")
assert(API.Stats()[1].value == 3, "exposes local completion observations")
routed = false
assert(API.NavigateActiveAssignments() == false, "no route is false, never nil")

-- Each not-ready reason goes through ForeverCore.APIKit.NotReady, so a caller reads it exactly as the suite's kit
-- publishes it. An older caller that reads only the first value still sees nil.
local function same(actual, expected, label)
	assert(actual == expected, ("%s: expected %s, got %s"):format(label, tostring(expected), tostring(actual)))
end
local kitNil, kitNone = kit.NotReady("none")
materials = nil
local noMaterials, noMaterialsReason = API.RequiredMaterials(1234, 2)
same(noMaterials, kitNil, "SkillUp Forever with nothing: the kit's nil")
same(noMaterialsReason, kitNone, "SkillUp Forever with nothing: the kit's reason")
same(noMaterialsReason, "none", "SkillUp Forever with nothing: nothing to answer")
questieAvailable = false
local _, kitLoading = kit.NotReady("loading")
local noObjectives, noObjectivesReason = API.ActiveObjectives()
same(noObjectives, nil, "QuestieDB unavailable: no rows")
same(noObjectivesReason, kitLoading, "QuestieDB unavailable: the kit's loading reason")
same(noObjectivesReason, "loading", "QuestieDB unavailable: ask again after it loads")
questieAvailable = true
objectives = {}
local empty = API.ActiveObjectives()
assert(type(empty) == "table" and #empty == 0, "QuestieDB present with nothing asked: an empty list, not a reason")

-- Materials: loading before the first refresh, then the window's rows as fresh rows. The internal turn-in table never
-- leaves the addon.
local beforeRefresh, beforeRefreshReason = API.Materials()
same(beforeRefresh, nil, "nothing before the first refresh")
same(beforeRefreshReason, "loading", "before the first refresh asks to come back")
counts[11370] = 4
fire("BAG_UPDATE_DELAYED")
local rows = API.Materials()
assert(#rows == 1 and rows[1].category == "thoriumBrotherhood", "a held turn-in material names its category")
assert(rows[1].itemID == 11370 and rows[1].have == 4, "and the bag count is the have value")
assert(
	rows[1].turnIn == nil and rows[1].need == nil and rows[1].questID == nil,
	"no internal table and no invented need"
)
assert(rows[1] ~= ns.Rows[1], "materials are fresh rows")
rows[1].have = 99
assert(ns.Rows[1].count == 4, "changing a material row does not change the window's rows")
questieAvailable = false
local unreadableMaterials, unreadableReason = API.Materials()
same(unreadableMaterials, nil, "QuestieDB unavailable: no material rows")
same(unreadableReason, "loading", "QuestieDB unavailable: ask again after it loads")
questieAvailable = true

-- CommissionCategory answers by quest ID through QuestieDB's own classifier, with its own reasons.
categories[123] = "thoriumBrotherhood"
assert(API.CommissionCategory(123) == "thoriumBrotherhood", "names the category a quest belongs to")
local unclassified, unclassifiedReason = API.CommissionCategory(124)
same(unclassified, nil, "a quest that is not a commission has no category")
same(unclassifiedReason, "none", "and says there is nothing to answer")
for _, wrong in ipairs({ "123", 0, -1, 1.5, 2.25 }) do
	local value, reason = API.CommissionCategory(wrong)
	same(value, nil, ("a wrong quest ID (%s) has no category"):format(tostring(wrong)))
	same(reason, "invalid", "and says the argument is wrong")
end
questieAvailable = false
local loadingCategory, loadingCategoryReason = API.CommissionCategory(123)
same(loadingCategory, nil, "QuestieDB unavailable: no category")
same(loadingCategoryReason, "loading", "QuestieDB unavailable: ask again after it loads")
questieAvailable = true

-- Subscribe reports the frame after a change, once, and only the channels whose rows changed.
local heard = {}
local unsubscribe = API.Subscribe(function(changes)
	heard[#heard + 1] = changes
end)
assert(type(unsubscribe) == "function", "Subscribe returns an unsubscribe function")
counts[11370] = 5
fire("BAG_UPDATE_DELAYED")
assert(#heard == 0, "nothing is reported in the same frame as the change")
nextFrame()
assert(#heard == 1 and heard[1].materials == true, "a bag change that changes a row reports materials once")
assert(heard[1].objectives == nil and heard[1].turnin == nil, "and only that channel")
fire("BAG_UPDATE_DELAYED")
nextFrame()
assert(#heard == 1, "a refresh that changes no row stays quiet")

-- A quest whose title contains a turn-in's name but whose QuestieDB row is not a commission adds no material row
-- (cjber/commissions-forever#200); it is still an objective change.
objectives = {
	{
		questID = 200,
		questName = "Craftsman's Writ - Runecloth Robe",
		itemID = 8,
		required = 1,
		finished = false,
		npcIDs = {},
	},
}
fire("QUEST_LOG_UPDATE")
nextFrame()
assert(#heard == 2 and heard[2].objectives == true, "a changed quest log reports objectives")
assert(heard[2].materials == nil, "an unclassified quest is no material change")
assert(#API.Materials() == 1, "an unclassified quest adds no material row")

-- A commission whose title matches no turn-in is shown with the category QuestieDB gives its ID.
categories[201] = "thoriumBrotherhood"
objectives = {
	{ questID = 201, questName = "Grandma's Cookie Recipe", itemID = 7, required = 10, finished = false, npcIDs = {} },
}
fire("QUEST_LOG_UPDATE")
nextFrame()
assert(
	#heard == 3 and heard[3].materials == true and heard[3].objectives == true,
	"the new commission changes both lists"
)
local active
for _, row in ipairs(API.Materials()) do
	if row.itemID == 7 then
		active = row
	end
end
assert(active and active.category == "thoriumBrotherhood", "an active quest row carries the quest's own category")
assert(active.have == 0 and active.need == 10 and active.questID == 201, "with the bag count and the log's need")
assert(active.turnIn == nil, "the internal turn-in table never leaves the addon")

-- Core/Stats.lua records a completion where it increments the total, and that record is what the hub's "turnin"
-- channel counts. Load the real module and fire its event: the completion comes from the code that records one.
ns.L = setmetatable({}, {
	__index = function(_, key)
		return key
	end,
})
ns.ICON = Toc.get("CommissionsForever", "X-Forever-Icon")
rawset(_G, "UnitGUID", function()
	return "Player-1"
end)
rawset(_G, "GetServerTime", function()
	return 1000
end)
local forwardedStats = ns.Stats
assert(loadfile("Core/Stats.lua"))("CommissionsForever", ns)
ns.Stats = forwardedStats
categories[999] = "thoriumBrotherhood"
fire("QUEST_TURNED_IN", 999)
assert(#heard == 3, "recording a completion reports nothing in the same frame")
nextFrame()
assert(#heard == 4 and heard[4].turnin == true, "a recorded completion reports turnin")
fire("QUEST_TURNED_IN", 999)
nextFrame()
assert(#heard == 5 and heard[5].turnin == true, "each recorded completion is reported")

unsubscribe()
unsubscribe()
counts[11370] = 6
fire("BAG_UPDATE_DELAYED")
nextFrame()
assert(#heard == 5, "an unsubscribed caller hears nothing")

-- A core whose kit is older than minor 2 has no Publish: the addon still loads and publishes nothing. The stub records
-- any call, so an unguarded Publish would fail here rather than on a player's older ForeverCore.
local published = {}
local olderKit = {
	minor = 1,
	Hub = function()
		return {
			Subscribe = function() end,
			Queue = function() end,
		}
	end,
	NotReady = kit.NotReady,
	Publish = function(addonName)
		published[#published + 1] = addonName
	end,
}
foreverCore.APIKit = olderKit
local olderChunk = assert(loadfile("Core/API.lua"))
local olderAPI = olderChunk("CommissionsForever", ns)
assert(#published == 0, "a kit at minor 1 is never asked to publish")
assert(olderAPI.version == 2 and olderAPI.minor == 0, "and the API loads unchanged")
foreverCore.APIKit = kit
_G.CommissionsForever.API = API

assert(kit.minor >= 1, "the kit's own minor is readable")
print("Commissions Forever API specs passed")
