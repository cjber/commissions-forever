local _, ns = ...

-- Only game-authored turn-in events with a stable, supported QuestieDB quest ID advance this record.
local Stats = {}
ns.Stats = Stats
local DEFAULTS = { statsShare = true }
local METRIC = "commission_turnin"
local MAX_VALUE, MAX_LIMIT = 1e9, 25

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

local function Ruleset()
	if not (C_GameRules and C_GameRules.GetCurrentGameModeRecordID and C_GameRules.IsHardcoreActive) then
		return nil
	end
	local ok, mode = pcall(C_GameRules.GetCurrentGameModeRecordID)
	local hcOK, hardcore = pcall(C_GameRules.IsHardcoreActive)
	if ok and Integer(mode, 1, MAX_VALUE) and hcOK and type(hardcore) == "boolean" then
		return ("%d_%d"):format(mode, hardcore and 1 or 0)
	end
end

function Stats.Participating()
	local value = DB().statsShare
	if type(value) ~= "boolean" then
		return DEFAULTS.statsShare
	end
	return value
end

local function Enabled()
	return Stats.Participating() and Ruleset() ~= nil
end

local peer = ns.PeerStats.New({
	addon = "commissions",
	enabled = Enabled,
	db = function()
		local record = Character()
		if not record then
			return nil
		end
		if type(record.peers) ~= "table" then
			record.peers = {}
		end
		return record.peers
	end,
	metrics = { [METRIC] = { subject = "numeric_pair" } },
	snapshot = function()
		local total, eventUnix = Totals()
		local subject = Ruleset()
		return subject
				and total > 0
				and eventUnix
				and { { metric = METRIC, subject = subject, value = total, eventUnix = eventUnix } }
			or {}
	end,
})

function Stats.SetEnabled(enabled)
	if type(enabled) ~= "boolean" then
		return false
	end
	DB().statsShare = enabled
	peer:SetEnabled(enabled)
	if ns.Window then
		ns.Window.Refresh()
	end
	return true
end

function Stats.Leaderboard(limit)
	limit = limit == nil and 10 or limit
	if not Integer(limit, 0, MAX_VALUE) then
		return nil, "invalid"
	end
	limit = math.min(limit, MAX_LIMIT)
	local subject = Ruleset()
	local total, eventUnix = Totals()
	local ranked = peer:Board(METRIC, subject or "unknown", total, eventUnix)
	local rows = {}
	for _, row in ipairs(ranked) do
		if row.rank <= limit or row.self then
			rows[#rows + 1] = {
				rank = row.rank,
				name = row.name,
				value = row.value,
				eventUnix = row.eventUnix,
				self = row.self == true or nil,
			}
		end
	end
	return {
		metric = METRIC,
		scope = "guild_group",
		ruleset = subject,
		sharing = Enabled(),
		total = #ranked,
		rows = rows,
	}
end

function Stats.Activity()
	local total, eventUnix = Totals()
	return { { addon = "CommissionsForever", metric = METRIC, subject = "all", value = total, eventUnix = eventUnix } }
end

function Stats.Print()
	local L = ns.L
	local board = Stats.Leaderboard()
	if not board then
		return
	end
	DEFAULT_CHAT_FRAME:AddMessage(L["Observed commission turn-ins: guild and group"])
	DEFAULT_CHAT_FRAME:AddMessage(L["Current client ruleset only. Other players' totals are player-reported."])
	for _, row in ipairs(board.rows) do
		local text = row.self and L["%d. %s: %d (you)"] or L["%d. %s: %d (player-reported)"]
		DEFAULT_CHAT_FRAME:AddMessage(text:format(row.rank, row.name, row.value))
	end
	if not board.ruleset then
		DEFAULT_CHAT_FRAME:AddMessage(L["Ruleset unavailable. Only your personal record is shown."])
	elseif not board.sharing then
		DEFAULT_CHAT_FRAME:AddMessage(L["Sharing is off. Only your personal record is shown."])
	end
	if not ns.Questie.Available() then
		DEFAULT_CHAT_FRAME:AddMessage(L["Install QuestieDB to record supported commission turn-ins."])
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("QUEST_TURNED_IN")
events:SetScript("OnEvent", function(_, event, questID)
	if event == "QUEST_TURNED_IN" then
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
	end
	peer:Sync()
end)

return Stats
