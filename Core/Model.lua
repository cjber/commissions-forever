local _, ns = ...

if ns.broken then
	return
end

local Model = {}
ns.Model = Model

-- The window's have-versus-need rows as fresh rows: a caller may keep or change them, and the internal turnIn table
-- never leaves the addon.
---@param rows {turnIn: table, category: string, itemID: integer, count: integer, need: integer?, questID: integer?}[]
---@return {category: string, itemID: integer, have: integer, need: integer?, questID: integer?}[]
function Model.Materials(rows)
	local materials = {}
	for index, row in ipairs(rows) do
		materials[index] = {
			category = row.category,
			itemID = row.itemID,
			have = row.count,
			need = row.need,
			questID = row.questID,
		}
	end
	return materials
end

---@param getCount fun(itemID: integer): integer
---@param objectives table[] the active quest item objectives (ns.Questie.ActiveObjectives)
---@return {turnIn: table, category: string, itemID: integer, count: integer, need: integer?, questID: integer?}[]
function Model.Inventory(getCount, objectives)
	local rows, active = {}, {}
	for _, objective in ipairs(objectives) do
		-- QuestieDB's classifier owns the answer: a quest's own ID decides whether it is a commission, never its title.
		local category = ns.Questie.CommissionCategory(objective.questID)
		if category then
			active[objective.itemID] = true
			rows[#rows + 1] = {
				-- The quest's own name stands in the window's turn-in column; its category is what it counts as.
				turnIn = { key = "active:" .. objective.questID, faction = objective.questName },
				category = category,
				itemID = objective.itemID,
				count = getCount(objective.itemID) or 0,
				need = objective.required,
				questID = objective.questID,
			}
		end
	end
	-- An item an active commission asks for shows once, on its Have / Need row.
	for _, turnIn in ipairs(ns.TurnIns) do
		for _, itemID in ipairs(turnIn.items) do
			local count = not active[itemID] and getCount(itemID) or 0
			if count > 0 then
				rows[#rows + 1] = { turnIn = turnIn, category = turnIn.key, itemID = itemID, count = count }
			end
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
