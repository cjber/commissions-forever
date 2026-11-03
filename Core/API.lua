local _, ns = ...

local API = { version = 1, minor = 2 }

---@param recipeID integer SkillUp Forever recipe ID.
---@param crafts? integer Number of outputs to plan for.
---@return {itemID: integer, count: number}[]?
function API.RequiredMaterials(recipeID, crafts)
	return ns.SkillUp.RequiredMaterials(recipeID, crafts)
end

---@return table[]
function API.ActiveObjectives()
	return ns.Questie.ActiveObjectives()
end

---@return boolean
function API.NavigateActiveAssignments()
	return ns.NavigateActiveAssignments()
end

-- Fresh local observations and a bounded, current-ruleset guild/group view.
function API.Stats()
	return ns.Stats.Activity()
end

function API.Leaderboard(limit)
	return ns.Stats.Leaderboard(limit)
end

_G.CommissionsForever = _G.CommissionsForever or {}
_G.CommissionsForever.API = API
ns.API = API

return API
