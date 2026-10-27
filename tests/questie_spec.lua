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
			return { "Logistics Task Briefing IV", { [3] = { { 54321, "Bring material" } } }, { { 42 }, {} } }
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
		return { questID = 123, name = "Logistics Task Briefing IV" }
	end,
	GetQuestObjectives = function()
		return { { type = "item", numRequired = 10, finished = false } }
	end,
})

local ns = {}
assert(loadfile("Integrations/Questie.lua"))("CommissionsForever", ns)
local rows = ns.Questie.ActiveObjectives()
assert(#rows == 1, "reads an active quest's item objective")
assert(rows[1].questID == 123 and rows[1].itemID == 54321 and rows[1].required == 10, "returns quest and count")
local npc = ns.Questie.NPC(42)
assert(npc and npc.name == "Quartermaster" and npc.map == 1, "reads a finisher's map from QuestieDB")
assert(math.abs(npc.x - 0.43) < 0.001 and math.abs(npc.y - 0.61) < 0.001, "converts QuestieDB coordinates")
print("Commissions Forever Questie specs passed")
