local _, ns = ...

local API = { version = 1, minor = 1 }

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

_G.CommissionsForever = _G.CommissionsForever or {}
_G.CommissionsForever.API = API
ns.API = API

return API
