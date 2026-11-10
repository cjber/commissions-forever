-- Run from the repository root: luajit tests/api_spec.lua
-- CommissionsForever.API against stubbed internals. The not-ready answers come from ForeverCore's own kit, loaded from
-- the checkout FOREVER_CORE names (tests/forever_core.lua finds it), as the client loads it before this addon.
local core = dofile("tests/forever_core.lua")

-- ForeverCore as Core/API.lua sees it at load. The kit is loaded from its own file into a namespace of its own: this
-- phase publishes no hub, so SafeCallFor only keeps the kit whole, and NotReady is the member the reads use.
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
rawset(_G, "ForeverCore", { APIKit = kit })

-- Fresh rows every call, as the modules under the API hand them out.
local materials
local objectives
local questieAvailable = true
local routed = false
local ns = {
	Stats = {
		Activity = function()
			return { { addon = "CommissionsForever", metric = "commission_turnin", subject = "all", value = 3 } }
		end,
		Leaderboard = function(limit)
			if limit == "bad" then
				return nil, "invalid"
			end
			assert(limit == 5, "forwards the limit")
			return { metric = "commission_turnin", scope = "guild_group", sharing = true, total = 1, rows = {} }
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
	},
	NavigateActiveAssignments = function()
		return routed
	end,
}
local chunk = assert(loadfile("Core/API.lua"))
local API = chunk("CommissionsForever", ns)

assert(API.version == 1 and API.minor == 3, "publishes version 1, minor 3")
assert(_G.CommissionsForever.API == API and ns.API == API, "publishes the table on the addon's global")

-- A read with an answer is unchanged: the kit is only read when there is nothing to answer.
materials = { { itemID = 17203, count = 2 } }
assert(API.RequiredMaterials(1234, 2) == materials, "returns SkillUp Forever's fresh materials")
objectives = { { questID = 99, itemID = 7, finished = false, npcIDs = {} } }
assert(API.ActiveObjectives()[1].questID == 99, "returns the log's live item objectives")
routed = true
assert(API.NavigateActiveAssignments(), "forwards turn-in routes to Shortest Path Forever")
assert(API.Stats()[1].value == 3, "exposes local completion observations")
assert(API.Leaderboard(5).total == 1, "forwards bounded leaderboard requests")
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

-- Leaderboard's bad limit is an argument error, not a not-ready reason: the existing reason stays as it was.
local badLimit, badLimitReason = API.Leaderboard("bad")
same(badLimit, nil, "a limit that is not a number has no board")
same(badLimitReason, "invalid", "and keeps its own reason")

assert(kit.minor >= 1, "the kit's own minor is readable")
print("Commissions Forever API specs passed")
