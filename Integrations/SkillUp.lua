local _, ns = ...

local SkillUp = {}
ns.SkillUp = SkillUp

---@param recipeID integer
---@param crafts? integer
---@return {itemID: integer, count: number}[]?
function SkillUp.RequiredMaterials(recipeID, crafts)
	local api = SkillUpForever and SkillUpForever.API
	if type(api) ~= "table" or type(api.RequiredMaterials) ~= "function" then
		return nil
	end
	local ok, result = pcall(api.RequiredMaterials, recipeID, crafts or 1)
	return ok and type(result) == "table" and result or nil
end

return SkillUp
