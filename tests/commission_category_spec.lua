-- Synthetic public-contract rows, not a copy of the companion database.
local ns = {}
assert(loadfile("Data/TurnIns.lua"))("CommissionsForever", ns)
local row, reverseID
local fields = { "specialFlags", "finishedBy", "reputationReward", "objectives", "sourceItemId", "startedBy" }
local keys = {}
for index, field in ipairs(fields) do
	keys[field] = index
end
local db = {
	RequireContract = function()
		return true
	end,
	Meta = { QuestMeta = { questKeys = keys } },
	Enum = {
		factionIDs = {
			ARGENT_DAWN = 529,
			CENARION_CIRCLE = 609,
			THORIUM_BROTHERHOOD = 59,
			TIMBERMAW_HOLD = 576,
			DARNASSUS = 69,
			THUNDER_BLUFF = 81,
		},
	},
	Quest = {
		GetAll = function(_, requested)
			for index, field in ipairs(fields) do
				assert(requested[index] == field)
			end
			return row
		end,
	},
	Item = {
		startQuest = function()
			return reverseID
		end,
	},
}
rawset(_G, "LibQuestieDB", db)
assert(loadfile("Integrations/Questie.lua"))("CommissionsForever", ns)
-- A classification is kept per quest ID for the session, so each check asks about its own quest.
local nextID = 100
local function NewID()
	nextID = nextID + 1
	return nextID
end
local function Check(expected, message, id)
	id = id or NewID()
	assert(ns.Questie.CommissionCategory(id) == expected, message)
	return id
end
local function Objective(faction, item)
	return { 1, { { 42 } }, { { faction, 10 } }, { [3] = { { item, "Material", 5 } } } }
end
for _, case in ipairs({
	{ 59, 11370, "thoriumBrotherhood" },
	{ 576, 21377, "timbermawHold" },
	{ 69, 11040, "morrowgrain" },
	{ 81, 11040, "morrowgrain" },
}) do
	row = Objective(case[1], case[2])
	Check(case[3], "objective materials and reputation classify each category")
end
for _, case in ipairs({ { 529, 22600, "argentDawn" }, { 609, 20807, "cenarionCircle" } }) do
	row = Objective(case[1], 99999)
	row[5], row[6] = case[2], { [3] = { case[2] } }
	local id = NewID()
	reverseID = id
	Check(case[3], "variable-material commissions require both directions of the starter relation", id)
	reverseID = id + 1000
	Check(nil, "a shared provided item alone is not a commission", NewID())
	reverseID, row[1] = id, 0
	Check(nil, "a one-time quest never qualifies", NewID())
end
row = Objective(59, 11370)
row[4][3][1][3] = 0
Check("thoriumBrotherhood", "zero metadata quantities cannot silently exclude valid repeatable categories")
row[1] = 3
Check("thoriumBrotherhood", "repeatable bit can coexist with other flags")
row[1] = 2
Check(nil, "other special flags do not imply repeatable")
row = Objective(59, 11370)
row[2] = nil
Check(nil, "missing finisher fails closed")
row = Objective(59, 11370)
row[3][1][2] = -10
Check(nil, "negative reputation does not establish the category")
row = Objective(59, 11370)
row[4][3][2] = { 99999, "Another material", 1 }
Check(nil, "every objective item must belong to the category")
row = Objective(529, 12844)
row[4][3][1][3] = 0
Check("argentDawn", "classification needs item identity, not an unavailable objective quantity")
row = Objective(59, 11370)
keys.specialFlags = nil
Check(nil, "older contracts without required metadata fail closed")
keys.specialFlags = 1
local reader = db.Quest.GetAll
db.Quest.GetAll = function()
	error("companion unavailable")
end
Check(nil, "companion failures do not break the event handler")
db.Quest.GetAll = reader

-- A quest does not change category while its library stays installed, so the answer is kept and handed out again.
row = Objective(59, 11370)
local cached = Check("thoriumBrotherhood", "a commission is classified once")
row = Objective(59, 99999)
assert(
	ns.Questie.CommissionCategory(cached) == "thoriumBrotherhood",
	"the session cache answers again without re-reading QuestieDB"
)
-- A failed read is no answer at all, so it stays uncached and the same ID is classified once the library answers.
row = Objective(59, 11370)
nextID = nextID + 1
local retried = nextID
db.Quest.GetAll = function()
	error("companion unavailable")
end
assert(ns.Questie.CommissionCategory(retried) == nil, "a failed read answers nothing")
db.Quest.GetAll = reader
assert(ns.Questie.CommissionCategory(retried) == "thoriumBrotherhood", "a failed read is asked again")
-- A library that is fitted again is a new source, so the classifications it gave are forgotten.
row = Objective(59, 99999)
local replacement = {}
for key, value in pairs(db) do
	replacement[key] = value
end
rawset(_G, "LibQuestieDB", replacement)
assert(ns.Questie.CommissionCategory(cached) == nil, "a replaced library forgets the old classifications")
row = Objective(59, 11370)

rawset(_G, "LibQuestieDB", nil)
Check(nil, "missing companion records nothing")
print("Commissions stable-ID category specs passed")
