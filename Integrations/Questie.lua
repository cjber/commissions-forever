local _, ns = ...

local Questie = {}
ns.Questie = Questie

local function ParseTable(source)
	if type(source) ~= "string" then
		return nil
	end
	local chunk = loadstring(source)
	if not chunk then
		return nil
	end
	setfenv(chunk, {})
	local ok, value = pcall(chunk)
	return ok and type(value) == "table" and value or nil
end

local function Library()
	local db = LibQuestieDB
	if type(db) ~= "table" or type(db.RequireContract) ~= "function" then
		return nil
	end
	local ok, compatible = pcall(db.RequireContract, 2)
	if not ok or not compatible or type(db.Quest) ~= "table" or type(db.Quest.GetAll) ~= "function" then
		return nil
	end
	return db
end

local function Fields(db, entity, wanted)
	local meta = db.Meta and db.Meta[entity .. "Meta"]
	local keys = meta and meta[entity:lower() .. "Keys"]
	if type(keys) ~= "table" then
		return nil
	end
	for _, field in ipairs(wanted) do
		if not keys[field] then
			return nil
		end
	end
	return wanted
end

-- Access one QuestieDB NPC through the documented reader only. The repository stores no Questie data.
---@param npcID integer
---@return {name: string, map: integer?, x: number?, y: number?}?
function Questie.NPC(npcID)
	local db = Library()
	if not (db and type(db.Npc) == "table" and type(db.Npc.GetAll) == "function") then
		return nil
	end
	local fields = Fields(db, "Npc", { "name", "spawns", "zoneID" })
	if not fields then
		return nil
	end
	local ok, values = pcall(db.Npc.GetAll, npcID, fields)
	if not ok or type(values) ~= "table" or type(values[1]) ~= "string" then
		return nil
	end
	local spawns = values[2]
	if type(spawns) ~= "table" then
		return { name = values[1] }
	end
	local area
	for candidate, points in pairs(spawns) do
		if type(candidate) == "number" and type(points) == "table" and (not area or candidate < area) then
			area = candidate
		end
	end
	local spot = area and spawns[area] and spawns[area][1]
	local zoneDB = db.Support and db.Support.Get and db.Support.Get("ZoneDB")
	local private = zoneDB and zoneDB.private
	local areaMaps = private and ParseTable(private.areaIdToUiMapId)
	local parents = private and ParseTable(private.subZoneToParentZone)
	local mapID = area and areaMaps and areaMaps[area]
	if not mapID and area and parents and areaMaps then
		mapID = areaMaps[parents[area]]
	end
	if type(spot) == "table" and type(mapID) == "number" then
		local x, y = tonumber(spot[1]), tonumber(spot[2])
		if x and y and x >= 0 and x <= 100 and y >= 0 and y <= 100 then
			return { name = values[1], map = mapID, x = x / 100, y = y / 100 }
		end
	end
	return { name = values[1] }
end

---@return table[] active quest item objectives and finisher NPC IDs
function Questie.ActiveObjectives()
	local db = Library()
	local fields = db and Fields(db, "Quest", { "name", "objectives", "finishedBy" })
	if not (db and fields and C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then
		return {}
	end
	local shown = C_QuestLog.GetNumQuestLogEntries()
	local rows = {}
	for index = 1, shown do
		local info = C_QuestLog.GetInfo(index)
		local questID = info and not info.isHeader and info.questID
		if questID then
			local ok, values = pcall(db.Quest.GetAll, questID, fields)
			if ok and type(values) == "table" and type(values[2]) == "table" then
				local objectiveGroups = values[2]
				local itemObjectives = objectiveGroups[3] or {}
				local live = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID) or {}
				local liveItems = {}
				for _, objective in ipairs(live) do
					if objective.type == "item" then
						liveItems[#liveItems + 1] = objective
					end
				end
				for _, itemObjective in ipairs(itemObjectives) do
					local itemID = tonumber(itemObjective[1])
					if itemID then
						rows[#rows + 1] = {
							questID = questID,
							questName = values[1] or info.name or ("Quest " .. questID),
							itemID = itemID,
							required = liveItems[_] and liveItems[_].numRequired or 0,
							finished = liveItems[_] and liveItems[_].finished or false,
							npcIDs = type(values[3]) == "table" and values[3][1] or {},
						}
					end
				end
			end
		end
	end
	return rows
end

return Questie
