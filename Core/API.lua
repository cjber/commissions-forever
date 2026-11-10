local _, ns = ...

if ns.broken then
	return
end

-- The shared shape every Forever addon's public API follows (ForeverCore's docs/api-conventions.md): a read with
-- nothing to answer returns nil and a reason from the kit. Core/Require.lua stops the addon before this file on a
-- ForeverCore too old to have the kit, so it is always here.
local APIKit = assert(ForeverCore.APIKit)

-- Public read-only answers and one navigation request for other addons (docs/api.md). `minor` rises with each
-- addition (1: the first three members, 2: Stats and Leaderboard, 3: each read's not-ready reason); a caller checks a
-- member before using it, because an older Commissions Forever may not have it yet.
local API = { version = 1, minor = 3 }

-- A recipe's raw materials, from SkillUp Forever. Nothing to answer ("none") when it is not installed, is too old to
-- read recipes, or does not know the recipe.
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

-- A fresh row per item objective of every quest in the current log that QuestieDB knows, commission or not. QuestieDB
-- absent or unread asks the caller to come back later: an empty list would say there is nothing in the log.
---@return CommissionsAPIObjective[]?, ForeverCoreAPIReason?
function API.ActiveObjectives()
	if not ns.Questie.Available() then
		return APIKit.NotReady("loading")
	end
	return ns.Questie.ActiveObjectives()
end

-- Every active commission's placed finishers, sent to Shortest Path Forever as one route. False when no commission is
-- active, no finisher has a known place, Shortest Path Forever is not installed, or it declined to start.
---@return boolean
function API.NavigateActiveAssignments()
	return ns.NavigateActiveAssignments()
end

-- Fresh local observations and a bounded, current-ruleset guild/group view.
---@return CommissionsAPIStatsRow[]
function API.Stats()
	return ns.Stats.Activity()
end

-- This character, its guild and its group, one row per ranked player. `nil, "invalid"` for a limit that is not a
-- whole number of zero or more: the argument is wrong rather than the data unready.
---@param limit? integer How many top rows, ten unless given, 25 at most.
---@return CommissionsAPILeaderboard?, "invalid"?
function API.Leaderboard(limit)
	return ns.Stats.Leaderboard(limit)
end

_G.CommissionsForever = _G.CommissionsForever or {}
_G.CommissionsForever.API = API --[[@as CommissionsPublicAPI]]
ns.API = API --[[@as CommissionsPublicAPI]]

return API
