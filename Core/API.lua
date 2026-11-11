local _, ns = ...

if ns.broken then
	return
end

-- The shared shape every Forever addon's public API follows (ForeverCore's docs/api-conventions.md): a read with
-- nothing to answer returns nil and a reason from the kit. Core/Require.lua stops the addon before this file on a
-- ForeverCore too old to have the kit, so it is always here.
local APIKit = assert(ForeverCore.APIKit)

-- Public read-only answers and one navigation request for other addons (docs/api.md). `version` rises when a member
-- breaks (2: Leaderboard removed) and `minor` with each addition (1: the first three members, 2: Stats and
-- Leaderboard, 3: each read's not-ready reason, 4: the category classifier, the window's rows and the change
-- subscription); a caller checks a member before using it, because an older Commissions Forever may not have it yet.
local API = { version = 2, minor = 0 }

-- A recipe's raw materials, from SkillUp Forever, the source of truth for a recipe's reagents. Nothing to answer
-- ("none") when it is not installed, is too old to read recipes, or does not know the recipe.
---@param recipeID integer SkillUp Forever recipe ID.
---@param crafts? integer Number of outputs to plan for.
---@return CommissionsAPIMaterial[]?, ForeverCoreAPIReason?
function API.RequiredMaterials(recipeID, crafts)
	local materials = ns.SkillUp.RequiredMaterials(recipeID, crafts)
	if materials == nil then
		return APIKit.NotReady("none")
	end
	return materials
end

-- The category name QuestieDB's own classifier gives a quest, the same answer the window, the route and the
-- completion record use. Its names are the turn-in categories in Data/TurnIns.lua. A quest that is not a commission
-- is not an unready read, so "none" says there is nothing to answer, while "loading" says QuestieDB cannot be read
-- yet. `nil, "invalid"` is an argument that is not a positive whole quest ID, which asking again cannot fix.
---@param questID integer
---@return string?, CommissionsAPIReason|"invalid"?
function API.CommissionCategory(questID)
	if type(questID) ~= "number" or questID <= 0 or questID % 1 ~= 0 then
		return nil, "invalid"
	end
	if not ns.Questie.Available() then
		return APIKit.NotReady("loading")
	end
	local category = ns.Questie.CommissionCategory(questID)
	if category == nil then
		return APIKit.NotReady("none")
	end
	return category
end

-- A fresh row per item objective of every quest in the current log that QuestieDB knows, commission or not. QuestieDB
-- absent or unread asks the caller to come back later: an empty list would say there is nothing in the log.
---@return CommissionsAPIObjective[]?, ForeverCoreAPIReason?
function API.ActiveObjectives()
	if not ns.Questie.Available() then
		return APIKit.NotReady("loading")
	end
	return ns.Questie.ActiveObjectives()
end

-- The window's have-versus-need rows as fresh rows; the internal turnIn table never leaves the addon. Before the first
-- refresh there is nothing to answer, and without QuestieDB the active quest rows would wrongly say no commission is
-- in the log, so both ask the caller to come back.
---@return CommissionsAPIMaterialsRow[]?, ForeverCoreAPIReason?
function API.Materials()
	if not ns.Refreshed or not ns.Questie.Available() then
		return APIKit.NotReady("loading")
	end
	return ns.Model.Materials(ns.Rows)
end

-- Every active commission's placed finishers, sent to Shortest Path Forever as one route. False when no commission is
-- active, no finisher has a known place, Shortest Path Forever is not installed, or it declined to start.
---@return boolean
function API.NavigateActiveAssignments()
	return ns.NavigateActiveAssignments()
end

-- Fresh local observations of this character's own completion record.
---@return CommissionsAPIStatsRow[]
function API.Stats()
	return ns.Stats.Activity()
end

-- Subscribe's hub (ForeverCore.APIKit): "materials" and "objectives" compare a key of what the last refresh built, so
-- the bag and quest log events that change nothing send nothing; "turnin" counts the completions Core/Stats.lua
-- records. Ready is the first refresh: until then neither list exists.
local turnIns = 0

-- One comparable key for the refresh's have-versus-need rows. Everything a caller reads there is in it, so an
-- unchanged refresh stays quiet.
---@return string|false
local function MaterialsKey()
	if not ns.Refreshed then
		return false
	end
	local parts = {}
	for index, row in ipairs(ns.Rows or {}) do
		parts[index] = table.concat({
			row.category or "",
			tostring(row.itemID),
			tostring(row.count),
			tostring(row.need),
			tostring(row.questID),
		}, "\1")
	end
	return table.concat(parts, "\2")
end

-- One comparable key for the refresh's active objectives, every published field included.
---@return string|false
local function ObjectivesKey()
	if not ns.Refreshed then
		return false
	end
	local parts = {}
	for index, row in ipairs(ns.ActiveObjectives or {}) do
		parts[index] = table.concat({
			tostring(row.questID),
			tostring(row.itemID),
			tostring(row.required),
			tostring(row.finished),
			row.questName or "",
			tostring(row.sourceItemID),
			table.concat(row.npcIDs or {}, " "),
		}, "\1")
	end
	return table.concat(parts, "\2")
end

local hub = APIKit.Hub("CommissionsForever", {
	materials = MaterialsKey,
	objectives = ObjectivesKey,
	turnin = function()
		return turnIns ~= 0 and turnIns or false
	end,
}, function()
	return ns.Refreshed == true
end)

-- Core/Core.lua's refresh and Core/Stats.lua's recorded completion say that a frame may have something to report. The
-- hub compares its keys and sends nothing when the refresh changed none of them.
---@param kind "refresh"|"turnin"
function ns.APIChanged(kind)
	if kind == "turnin" then
		turnIns = turnIns + 1
	end
	hub.Queue()
end

-- Calls `callback(changes)` on the frame after the rows or completions it names changed, and returns a function that
-- unsubscribes.
API.Subscribe = hub.Subscribe

_G.CommissionsForever = _G.CommissionsForever or {}
_G.CommissionsForever.API = API --[[@as CommissionsPublicAPI]]
ns.API = API --[[@as CommissionsPublicAPI]]

-- The suite lists every Forever addon's API through ForeverCore.APIKit.Addons() (docs/api.md). The kit gained Publish
-- in minor 2, so an older core has no member to call and the addon still loads without publishing.
if (ForeverCore.APIKit.minor or 1) >= 2 then
	ForeverCore.APIKit.Publish("CommissionsForever", API)
end

return API
