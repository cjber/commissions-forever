-- QuestieDB is read once: the library is fitted once, its zone tables run once per installed library, and a
-- quest's row is read once however many bag and log events ask for it.
local fits, zoneReads, questReads, parses = 0, 0, 0, 0
local loadString = loadstring
rawset(_G, "loadstring", function(source)
	parses = parses + 1
	return loadString(source)
end)

local questKeys = { name = 1, objectives = 2, finishedBy = 3, sourceItemId = 4 }
local npcKeys = { name = 1, spawns = 2, zoneID = 3 }

local function Zones(area, parent, areaOverride, parentOverride)
	return function()
		zoneReads = zoneReads + 1
		return {
			private = {
				areaIdToUiMapId = area,
				subZoneToParentZone = parent,
				areaIdToUiMapIdOverride = areaOverride,
				subZoneToParentZoneOverride = parentOverride,
			},
		}
	end
end

local function Database(options)
	return {
		RequireContract = function(version)
			fits = fits + 1
			return version == 2
		end,
		Meta = { QuestMeta = { questKeys = questKeys }, NpcMeta = { npcKeys = npcKeys } },
		Support = { Get = options.zones },
		Quest = {
			GetAll = function(questID)
				questReads = questReads + 1
				return {
					"Quest " .. questID,
					{ [3] = { { 54321, "Bring feathers" } } },
					{ { 42 }, {} },
					20806,
				}
			end,
		},
		Npc = {
			GetAll = function()
				return { "Quartermaster", options.spawns or { [120] = { { 43, 61 } } }, 120 }
			end,
		},
	}
end

rawset(_G, "C_QuestLog", {
	GetNumQuestLogEntries = function()
		return 2, 2
	end,
	GetInfo = function(index)
		return { questID = 900 + index, title = "Quest " .. (900 + index) }
	end,
	GetQuestObjectives = function()
		return { { type = "item", text = "Feathers: 3/10", numRequired = 10, finished = false } }
	end,
})
rawset(_G, "C_Item", {
	GetItemNameByID = function(itemID)
		return itemID == 54321 and "Feathers" or nil
	end,
})

local ns = {}
assert(loadfile("Integrations/Questie.lua"))("CommissionsForever", ns)
rawset(_G, "LibQuestieDB", Database({ zones = Zones("return {[120] = 1}", "return {}") }))

-- A bag or log event lists the log's quests; the second event reads the same QuestieDB rows again.
local first = ns.Questie.ActiveObjectives()
assert(#first == 2, "every active quest's item objective is listed")
assert(questReads == 2, "one QuestieDB read per log quest")
questReads = 0
local second = ns.Questie.ActiveObjectives()
assert(questReads == 0, "a second bag or log event reads no quest again")
assert(second[1].questName == "Quest 901" and second[1].itemID == 54321, "the cached row still names its quest")
assert(second[1].sourceItemID == 20806, "the cached row keeps the optional source item")
second[1].npcIDs[1] = 999
assert(ns.Questie.ActiveObjectives()[1].npcIDs[1] == 42, "a cached quest still hands out a fresh finisher list")

-- The fit and the zone source are one pass, however often the window, the tracker or a route asks.
assert(fits == 1, "the contract is checked once")
assert(zoneReads == 1, "the zone tables are read once")
parses = 0
assert(ns.Questie.Available(), "the fitted library is available")
assert(ns.Questie.NPC(42).map == 1, "an NPC reads its area's map")
assert(ns.Questie.NPC(43).map == 1, "the next NPC reads the same tables")
assert(fits == 1 and zoneReads == 1, "later reads fit no library again")
assert(parses == 0, "later reads run no zone source again")

-- The map comes from ZoneDB's tables with the overrides QuestieDB applies in front of them.
local function Place(spawns, area, parent, areaOverride, parentOverride)
	local installed = Database({ zones = Zones(area, parent, areaOverride, parentOverride), spawns = spawns })
	rawset(_G, "LibQuestieDB", installed)
	return ns.Questie.NPC(42)
end

local npc = Place({ [209] = { { 43, 61 } } }, "return {[209] = 1}", "return {}")
assert(npc.map == 1 and math.abs(npc.x - 0.43) < 0.001, "an area's own map places the NPC")
npc = Place({ [209] = { { 43, 61 } } }, "return {}", "return {}", "return {[209] = 310}", "return {}")
assert(npc.map == 310 and math.abs(npc.y - 0.61) < 0.001, "an area only its override maps uses that map")
npc = Place({ [209] = { { 43, 61 } } }, "return {[209] = 1}", "return {}", "return {[209] = 0}", "return {}")
assert(npc.map == nil and npc.x == nil, "an area whose map the override suppresses keeps the name only")
npc = Place(
	{ [121] = { { 50, 25 } } },
	"return {[120] = 1, [130] = 2}",
	"return {[121] = 120}",
	nil,
	"return {[121] = 130}"
)
assert(npc.map == 2, "a subzone uses its overridden parent's map")

-- A library that loads after the first call, or replaces the fitted one, is fitted and read again.
local installed = rawget(_G, "LibQuestieDB")
rawset(_G, "LibQuestieDB", nil)
assert(not ns.Questie.Available(), "no library is unavailable")
assert(next(ns.Questie.ActiveObjectives()) == nil, "no library lists no objectives")
rawset(_G, "LibQuestieDB", installed)
questReads = 0
assert(#ns.Questie.ActiveObjectives() == 2 and questReads == 2, "a library that loads later is read again")
print("Commissions Forever Questie read specs passed")
