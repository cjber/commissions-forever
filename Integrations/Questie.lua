local _, ns = ...

if ns.broken then
	return
end

local Questie = {}
ns.Questie = Questie

-- The contract this file was written against. QuestieDB checks a range, so a newer additive release works.
local CONTRACT = 2

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

-- QuestieDB's ZoneDB as this file reads it: the area and parent tables, and the overrides every Forever addon
-- applies over them, each run once from the Lua source QuestieDB keeps them as.
---@class CommissionsQuestieZones
---@field area table<integer, integer>
---@field areaOverride table<integer, integer>
---@field parent table<integer, integer>
---@field parentOverride table<integer, integer>

---@param db table
---@return CommissionsQuestieZones?
local function Zones(db)
	local support = type(db.Support) == "table" and db.Support
	local get = support and support.Get
	local zoneDB = type(get) == "function" and get("ZoneDB")
	local private = type(zoneDB) == "table" and zoneDB.private
	if type(private) ~= "table" then
		return nil
	end
	local area, parent = ParseTable(private.areaIdToUiMapId), ParseTable(private.subZoneToParentZone)
	if not (area and parent) then
		return nil
	end
	return {
		area = area,
		areaOverride = ParseTable(private.areaIdToUiMapIdOverride) or {},
		parent = parent,
		parentOverride = ParseTable(private.subZoneToParentZoneOverride) or {},
	}
end

-- Each quest's row as QuestieDB holds it, kept per quest ID; false is a quest QuestieDB does not have. The
-- bag and log events re-ask for the same quests, and QuestieDB hands out fresh table copies on every read.
---@class CommissionsQuestieQuest
---@field name string?
---@field objectives table[]
---@field finishers integer[]
---@field sourceItemID integer?
---@type table<integer, CommissionsQuestieQuest|false>
local quests = {}

-- Each quest's commission category, and "not a commission", kept per quest ID for the session like its row: the bag
-- and log events re-ask about the same quests, and classification does not change while the library stays installed.
-- false is the answer "not a commission", so only a library that is fitted again clears it.
---@type table<integer, string|false>
local categories = {}

-- QuestieDB as this file reads it, fitted once so the contract check and its zone tables cost one pass. A
-- library that replaces the one held is fitted again, so one that loads later is picked up.
---@type table?
local fitted
---@type table?
local library
---@type CommissionsQuestieZones?
local libraryZones

---@return table?, CommissionsQuestieZones?
local function Library()
	local lib = LibQuestieDB
	if lib ~= fitted then
		fitted, library, libraryZones, quests, categories = lib, nil, nil, {}, {}
		if type(lib) == "table" and type(lib.RequireContract) == "function" then
			local ok, compatible = pcall(lib.RequireContract, CONTRACT)
			if ok and compatible and type(lib.Quest) == "table" and type(lib.Quest.GetAll) == "function" then
				library, libraryZones = lib, Zones(lib)
			end
		end
	end
	return library, libraryZones
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

-- An area's zone map, or its parent zone's, with the overrides QuestieDB applies over both. An override of 0
-- suppresses the area's map, so the NPC keeps its name and no place.
---@param zones CommissionsQuestieZones?
---@param area integer?
---@return integer?
local function Map(zones, area)
	if not (zones and area) then
		return nil
	end
	local map = zones.areaOverride[area] or zones.area[area]
	if map == nil then
		local parent = zones.parentOverride[area] or zones.parent[area]
		map = parent and (zones.areaOverride[parent] or zones.area[parent])
	end
	return type(map) == "number" and map > 0 and map or nil
end

-- Access one QuestieDB NPC through the documented reader only. The repository stores no Questie data.
---@param npcID integer
---@return {name: string, map: integer?, x: number?, y: number?}?
function Questie.NPC(npcID)
	local db, zones = Library()
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
	local mapID = Map(zones, area)
	if type(spot) == "table" and mapID then
		local x, y = tonumber(spot[1]), tonumber(spot[2])
		if x and y and x >= 0 and x <= 100 and y >= 0 and y <= 100 then
			return { name = values[1], map = mapID, x = x / 100, y = y / 100 }
		end
	end
	return { name = values[1] }
end

-- QuestieDB is the only source of quest requirements and NPC places, so the window says when it is missing.
---@return boolean
function Questie.Available()
	return Library() ~= nil
end

-- An item objective's words without its count ("Runecloth: 3/10" reads "Runecloth"), so it can be matched by name.
---@param text string
---@return string
local function ObjectiveLabel(text)
	return (text:gsub("%s*:?%s*%d+%s*/%s*%d+%s*", ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- The quest log's item objectives keyed by the item they ask for, so a QuestieDB objective finds its own entry
-- whatever order either list is in. An item the client has not cached yet has no name and stays unmatched.
---@param live table[]
---@return table<string, table>
local function LiveItemsByName(live)
	local byName = {}
	for _, objective in ipairs(live) do
		if objective.type == "item" and type(objective.text) == "string" then
			byName[ObjectiveLabel(objective.text)] = objective
		end
	end
	return byName
end

-- QuestieDB's row for one quest, read once per ID: what a quest needs does not change while its library stays
-- installed, and GetAll hands out fresh table copies on every call.
---@param db table
---@param fields string[]
---@param questID integer
---@return CommissionsQuestieQuest?
local function QuestRow(db, fields, questID)
	local quest = quests[questID]
	if quest == nil then
		local ok, values = pcall(db.Quest.GetAll, questID, fields)
		if ok and type(values) == "table" and type(values[2]) == "table" then
			quest = {
				name = values[1],
				objectives = values[2][3] or {},
				finishers = type(values[3]) == "table" and values[3][1] or {},
				sourceItemID = values[4],
			}
		end
		quests[questID] = quest or false
	end
	return quest or nil
end

-- The cached finisher IDs as a fresh list, so no caller can change what a later refresh reads.
---@param ids integer[]
---@return integer[]
local function Finishers(ids)
	local copy = {}
	for index, id in ipairs(ids) do
		copy[index] = id
	end
	return copy
end

---@return table[] active quest item objectives and finisher NPC IDs
function Questie.ActiveObjectives()
	local db = Library()
	local fields = db and Fields(db, "Quest", { "name", "objectives", "finishedBy" })
	if not (db and fields and C_QuestLog and C_QuestLog.GetNumQuestLogEntries and C_QuestLog.GetInfo) then
		return {}
	end
	-- Older compatible contracts may omit this optional field.
	local questMeta = db.Meta and db.Meta.QuestMeta
	if questMeta and questMeta.questKeys and questMeta.questKeys.sourceItemId then
		fields[#fields + 1] = "sourceItemId"
	end
	local shown = C_QuestLog.GetNumQuestLogEntries()
	local rows = {}
	for index = 1, shown do
		local info = C_QuestLog.GetInfo(index)
		if info and not info.isHeader and info.questID then
			local questID = info.questID
			local quest = QuestRow(db, fields, questID)
			if quest then
				local live = C_QuestLog.GetQuestObjectives and C_QuestLog.GetQuestObjectives(questID) or {}
				local liveItems = LiveItemsByName(live)
				for _, itemObjective in ipairs(quest.objectives) do
					local itemID = tonumber(itemObjective[1])
					if itemID then
						local name = C_Item.GetItemNameByID(itemID)
						local objective = name and liveItems[name]
						rows[#rows + 1] = {
							questID = questID,
							sourceItemID = quest.sourceItemID,
							questName = quest.name or info.title or ("Quest " .. questID),
							itemID = itemID,
							required = objective and objective.numRequired,
							finished = objective and objective.finished or false,
							npcIDs = Finishers(quest.finishers),
						}
					end
				end
			end
		end
	end
	return rows
end

-- Classify the completed ID after it has left the quest log. Titles never establish a completion.
local function Contains(values, wanted)
	for _, value in ipairs(type(values) == "table" and values or {}) do
		if value == wanted then
			return true
		end
	end
	return false
end

local function PositiveReputation(db, category, rewards)
	local factions = db.Enum and db.Enum.factionIDs
	if type(factions) ~= "table" or type(rewards) ~= "table" then
		return false
	end
	for _, name in ipairs(category.reputationFactions or {}) do
		local factionID = factions[name]
		for _, reward in ipairs(rewards) do
			if
				type(reward) == "table"
				and factionID
				and reward[1] == factionID
				and type(reward[2]) == "number"
				and reward[2] > 0
			then
				return true
			end
		end
	end
	return false
end

-- The category a quest belongs to, read from QuestieDB now. false is a quest that is not a commission; nil is a
-- library that cannot answer yet, so the answer is not cached and the caller can ask again.
---@param questID integer
---@return string|false|nil
local function Classify(questID)
	local db = Library()
	local fields = db
		and Fields(db, "Quest", {
			"specialFlags",
			"finishedBy",
			"reputationReward",
			"objectives",
			"sourceItemId",
			"startedBy",
		})
	if not db or not fields then
		return nil
	end
	local ok, values = pcall(db.Quest.GetAll, questID, fields)
	if not ok then
		return nil
	end
	if type(values) ~= "table" then
		return false
	end
	local flags, finishers = values[1], values[2]
	if type(flags) ~= "number" or flags < 0 or flags % 2 ~= 1 or type(finishers) ~= "table" then
		return false
	end
	local hasFinisher = false
	for _, ids in pairs(finishers) do
		if type(ids) == "table" and #ids > 0 then
			hasFinisher = true
		end
	end
	if not hasFinisher then
		return false
	end
	local objectives = type(values[4]) == "table" and values[4][3]
	local starters = type(values[6]) == "table" and values[6][3]
	local matched
	for _, category in ipairs(ns.TurnIns) do
		if PositiveReputation(db, category, values[3]) then
			local starterMatch = false
			if
				Contains(category.sourceItems, values[5])
				and Contains(starters, values[5])
				and db.Item
				and type(db.Item.startQuest) == "function"
			then
				local itemOK, startedQuest = pcall(db.Item.startQuest, values[5])
				starterMatch = itemOK and startedQuest == questID
			end
			local objectiveMatch = type(objectives) == "table" and #objectives > 0
			for _, objective in ipairs(type(objectives) == "table" and objectives or {}) do
				if type(objective) ~= "table" or not Contains(category.items, objective[1]) then
					objectiveMatch = false
				end
			end
			if starterMatch or objectiveMatch then
				if matched then
					return false
				end
				matched = category.key
			end
		end
	end
	return matched or false
end

-- The commission category a quest ID belongs to, the same answer the window, the route and the completion record
-- use. Titles never classify a quest. The answer is kept per ID for the session.
---@param questID integer
---@return string? category
function Questie.CommissionCategory(questID)
	if type(questID) ~= "number" or questID <= 0 or questID % 1 ~= 0 then
		return nil
	end
	-- Fit the library first: a library that replaced the one read before clears the session's answers, not just the
	-- next refresh's.
	local db = Library()
	if not db then
		return nil
	end
	---@type string|false|nil
	local category = categories[questID]
	if category == nil then
		category = Classify(questID)
		if category == nil then
			return nil
		end
		categories[questID] = category
	end
	return category or nil
end

return Questie
