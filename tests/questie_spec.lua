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
local questKeys = rawget(_G, "LibQuestieDB").Meta.QuestMeta.questKeys
questKeys.sourceItemId = 11
questDB.GetAll = function(_, fields)
	assert(fields[4] == "sourceItemId", "requests optional source item through the public reader")
	local values = questieGetAll()
	values[4] = 20806
	return values
end
assert(ns.Questie.ActiveObjectives()[1].sourceItemID == 20806, "briefing source reaches the model")
questKeys.sourceItemId = nil
questDB.GetAll = questieGetAll
assert(ns.Questie.Available(), "QuestieDB is available")
local npc = ns.Questie.NPC(42)
assert(npc and npc.name == "Quartermaster" and npc.map == 1, "reads a finisher's map from QuestieDB")
assert(math.abs(npc.x - 0.43) < 0.001 and math.abs(npc.y - 0.61) < 0.001, "converts QuestieDB coordinates")

local db = rawget(_G, "LibQuestieDB")
local function ZoneDB(areaMaps, parents)
	return function()
		return { private = { areaIdToUiMapId = areaMaps, subZoneToParentZone = parents } }
	end
end
local function Npc(spawns)
	return function()
		return { "Quartermaster", spawns, 120 }
	end
end
local NAME_ONLY = { name = "Quartermaster" }
local npcCases = {
	{
		name = "the lowest numeric area wins",
		getAll = Npc({ [130] = { { 10, 20 } }, [120] = { { 43, 61 } } }),
		support = ZoneDB("return {[120] = 1, [130] = 2}", "return {}"),
		want = { name = "Quartermaster", map = 1, x = 0.43, y = 0.61 },
	},
	{
		name = "a subzone falls back to its parent zone's map",
		getAll = Npc({ [121] = { { 50, 25 } } }),
		support = ZoneDB("return {[120] = 1}", "return {[121] = 120}"),
		want = { name = "Quartermaster", map = 1, x = 0.5, y = 0.25 },
	},
	{
		name = "a coordinate above 100 keeps the name only",
		getAll = Npc({ [120] = { { 101, 50 } } }),
		want = NAME_ONLY,
	},
	{ name = "a negative coordinate keeps the name only", getAll = Npc({ [120] = { { 50, -1 } } }), want = NAME_ONLY },
	{ name = "no spawns keeps the name only", getAll = Npc(nil), want = NAME_ONLY },
	{
		name = "an unparsable area map keeps the name only",
		getAll = Npc({ [120] = { { 43, 61 } } }),
		support = ZoneDB("not lua", "return {}"),
		want = NAME_ONLY,
	},
	{
		name = "a non-string name is no NPC",
		getAll = function()
			return { 7, { [120] = { { 43, 61 } } }, 120 }
		end,
	},
	{
		name = "an erroring reader is no NPC",
		getAll = function()
			error("broken")
		end,
	},
	{ name = "a contract without the spawns field is no NPC", npcKeys = { name = 1, zoneID = 3 } },
}
for _, case in ipairs(npcCases) do
	local getAll, support, npcKeys = db.Npc.GetAll, db.Support.Get, db.Meta.NpcMeta.npcKeys
	db.Npc.GetAll = case.getAll or getAll
	db.Support.Get = case.support or support
	db.Meta.NpcMeta.npcKeys = case.npcKeys or npcKeys
	local got = ns.Questie.NPC(42)
	db.Npc.GetAll, db.Support.Get, db.Meta.NpcMeta.npcKeys = getAll, support, npcKeys
	local want = case.want
	if want == nil then
		assert(got == nil, case.name)
	else
		assert(got and got.name == want.name and got.map == want.map, case.name)
		assert((got.x == nil) == (want.x == nil) and (got.y == nil) == (want.y == nil), case.name)
		if want.x then
			assert(math.abs(got.x - want.x) < 0.001 and math.abs(got.y - want.y) < 0.001, case.name)
		end
	end
end

rawset(_G, "LibQuestieDB", nil)
assert(not ns.Questie.Available(), "QuestieDB is unavailable without the library")
assert(next(ns.Questie.ActiveObjectives()) == nil, "no library lists no objectives")
assert(ns.Questie.NPC(42) == nil, "no library finds no NPC")
rawset(_G, "LibQuestieDB", db)
print("Commissions Forever Questie specs passed")
