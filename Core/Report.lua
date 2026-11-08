local _, ns = ...

-- Commissions Forever's own lines in /cf report: whether each optional addon answered, what the ledger holds and
-- whether progress is shared, so a bug report says what state the addon was in. English throughout, like the other
-- shared report lines.

ns.ReportTitle = ns.L["Commissions Forever report"]

---@param available boolean?
---@return string
local function Loaded(available)
	return available and "loaded" or "not loaded"
end

---@param addon table?
---@param method string
---@return boolean
local function HasAPI(addon, method)
	return type(addon) == "table" and type(addon.API) == "table" and type(addon.API[method]) == "function"
end

---@return string[]
function ns.ReportLines()
	local objectives = 0
	for _, row in ipairs(ns.ActiveObjectives or {}) do
		if ns.Model.IsCommissionQuest(row.questName, row.sourceItemID) then
			objectives = objectives + 1
		end
	end
	local sharing = ns.Stats and ns.Stats.Participating and ns.Stats.Participating() == true
	return {
		("QuestieDB: %s"):format(Loaded(ns.Questie and ns.Questie.Available and ns.Questie.Available())),
		("Shortest Path Forever: %s"):format(Loaded(HasAPI(ShortestPathForever, "NavigateRoute"))),
		("SkillUp Forever: %s"):format(Loaded(HasAPI(SkillUpForever, "RequiredMaterials"))),
		("%d active commission objectives, %d inventory rows"):format(objectives, #(ns.Rows or {})),
		("Progress sharing: %s"):format(sharing and "on" or "off"),
	}
end
