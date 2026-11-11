local _, ns = ...

if ns.broken then
	return
end

-- Only game-authored turn-in events with a stable, supported QuestieDB quest ID advance this record.
local Stats = {}
ns.Stats = Stats
local METRIC = "commission_turnin"
local MAX_VALUE = 1e9

local function DB()
	if type(CommissionsForeverDB) ~= "table" then
		CommissionsForeverDB = {}
	end
	return CommissionsForeverDB
end

local function Character()
	local guid = UnitGUID("player")
	if issecretvalue and issecretvalue(guid) then
		return nil
	end
	if type(guid) ~= "string" or guid == "" then
		return nil
	end
	local db = DB()
	if type(db.completionRecords) ~= "table" then
		db.completionRecords = {}
	end
	if type(db.completionRecords[guid]) ~= "table" then
		db.completionRecords[guid] = {}
	end
	return db.completionRecords[guid]
end

local function Integer(value, low, high)
	return type(value) == "number" and value == value and value >= low and value <= high and value % 1 == 0
end

local function Totals()
	local record = Character()
	return record and Integer(record.total, 0, MAX_VALUE) and record.total or 0,
		record and Integer(record.eventUnix, 1, MAX_VALUE * 10) and record.eventUnix or nil
end

function Stats.Activity()
	local total, eventUnix = Totals()
	return { { addon = "CommissionsForever", metric = METRIC, subject = "all", value = total, eventUnix = eventUnix } }
end

-- Forever Leaderboards is gone: drop the peer table and sharing switch it saved.
local function DropLeaderboardData()
	local db = type(CommissionsForeverDB) == "table" and CommissionsForeverDB or nil
	if not db then
		return
	end
	db.statsShare = nil
	if type(db.completionRecords) ~= "table" then
		return
	end
	for _, record in pairs(db.completionRecords) do
		if type(record) == "table" then
			record.peers = nil
		end
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("QUEST_TURNED_IN")
events:SetScript("OnEvent", function(_, event, questID)
	if event == "PLAYER_LOGIN" then
		DropLeaderboardData()
		return
	end
	if not Integer(questID, 1, MAX_VALUE) or not ns.Questie.CommissionCategory(questID) then
		return
	end
	local record = Character()
	local stamp = GetServerTime()
	if not record or not Integer(stamp, 1, MAX_VALUE * 10) then
		return
	end
	local total = Totals()
	record.total, record.eventUnix = math.min(total + 1, MAX_VALUE), stamp
	ns.APIChanged("turnin")
end)

return Stats
