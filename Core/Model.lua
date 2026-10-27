local _, ns = ...

local Model = {}
ns.Model = Model

---@param questName string
---@return boolean
function Model.IsCommissionQuest(questName)
	local lowerName = string.lower(questName)
	for _, turnIn in ipairs(ns.TurnIns) do
		if string.find(lowerName, string.lower(turnIn.quest), 1, true) then
			return true
		end
		for _, alias in ipairs(turnIn.questAliases or {}) do
			if string.find(lowerName, string.lower(alias), 1, true) then
				return true
			end
		end
	end
	return false
end

---@param getCount fun(itemID: integer): integer
---@return {turnIn: table, itemID: integer, count: integer}[]
function Model.Inventory(getCount)
	local rows = {}
	for _, turnIn in ipairs(ns.TurnIns) do
		for _, itemID in ipairs(turnIn.items) do
			local count = getCount(itemID) or 0
			if count > 0 then
				rows[#rows + 1] = { turnIn = turnIn, itemID = itemID, count = count }
			end
		end
	end
	for _, objective in ipairs(ns.ActiveObjectives or {}) do
		if Model.IsCommissionQuest(objective.questName) then
			rows[#rows + 1] = {
				turnIn = { key = "active:" .. objective.questID, faction = objective.questName },
				itemID = objective.itemID,
				count = getCount(objective.itemID) or 0,
				need = objective.required,
				questID = objective.questID,
			}
		end
	end
	table.sort(rows, function(a, b)
		if a.turnIn.key == b.turnIn.key then
			return a.itemID < b.itemID
		end
		return a.turnIn.key < b.turnIn.key
	end)
	return rows
end

return Model
