rawset(_G, "LibQuestieDB", {
	RequireContract = function(version)
		return version == 2
	end,
	Meta = {
		QuestMeta = { questKeys = { name = 1, objectives = 2, finishedBy = 3 } },
		NpcMeta = { npcKeys = { name = 1, spawns = 2, zoneID = 3 } },
	},
	Support = {
		Get = function()
			return {
				private = {
					areaIdToUiMapId = "return {[120] = 1}",
					subZoneToParentZone = "return {}",
				},
			}
		end,
	},
	Quest = {
		GetAll = function()
			return {
				"Logistics Task Briefing IV",
				{ [3] = { { 54321, "Bring material" }, { 54322 }, { 54323 } } },
				{ { 42 }, {} },
			}
		end,
	},
	Npc = {
		GetAll = function()
			return { "Quartermaster", { [120] = { { 43, 61 } } }, 120 }
		end,
	},
})
rawset(_G, "C_QuestLog", {
	GetNumQuestLogEntries = function()
		return 1, 1
	end,
	GetInfo = function()
		return { questID = 123, title = "Logistics Task Briefing IV (log)" }
	end,
	GetQuestObjectives = function()
		-- The quest log lists its objectives in its own order, not QuestieDB's, and the third item is not cached yet.
		return {
			{ type = "item", text = "Thorium Bar: 20/20", numRequired = 20, finished = true },
			{ type = "monster", text = "Quartermaster slain: 0/1", numRequired = 1, finished = false },
			{ type = "item", text = "Runecloth: 3/10", numRequired = 10, finished = false },
		}
	end,
})
local names = { [54321] = "Runecloth", [54322] = "Thorium Bar" }
rawset(_G, "C_Item", {
	GetItemNameByID = function(itemID)
		return names[itemID]
	end,
})

local ns = {}
assert(loadfile("Integrations/Questie.lua"))("CommissionsForever", ns)
local rows = ns.Questie.ActiveObjectives()
assert(#rows == 3, "reads every item objective of an active quest")
assert(rows[1].questID == 123 and rows[1].itemID == 54321 and rows[1].required == 10, "returns quest and count")
assert(not rows[1].finished, "Runecloth is paired with its own objective, not the first in the log")
assert(rows[2].itemID == 54322 and rows[2].required == 20 and rows[2].finished, "Thorium Bar keeps its own progress")
assert(rows[3].required == nil and not rows[3].finished, "an item the client has not named yet claims no progress")
assert(rows[1].questName == "Logistics Task Briefing IV", "QuestieDB names the quest")
local questDB = rawget(_G, "LibQuestieDB").Quest
local questieGetAll = questDB.GetAll
questDB.GetAll = function()
	local values = questieGetAll()
	values[1] = nil
	return values
end
assert(
	ns.Questie.ActiveObjectives()[1].questName == "Logistics Task Briefing IV (log)",
	"the quest log's title fills a name QuestieDB lacks"
)
questDB.GetAll = questieGetAll
assert(ns.Questie.Available(), "QuestieDB is available")
local npc = ns.Questie.NPC(42)
assert(npc and npc.name == "Quartermaster" and npc.map == 1, "reads a finisher's map from QuestieDB")
assert(math.abs(npc.x - 0.43) < 0.001 and math.abs(npc.y - 0.61) < 0.001, "converts QuestieDB coordinates")
print("Commissions Forever Questie specs passed")
