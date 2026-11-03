local checks = 0
local function check(value, label)
	checks = checks + 1
	assert(value, label)
end
local function boot(saved, mode, hardcore, guid)
	local frames, timers, sent, lines = {}, {}, {}, {}
	local now = 2000
	local env = setmetatable({ SlashCmdList = {} }, { __index = _G })
	env._G = env
	env.GetServerTime = function()
		return now
	end
	env.GetTime = function()
		return now
	end
	env.GetNormalizedRealmName = function()
		return "Home"
	end
	env.UnitName = function()
		return "Me"
	end
	env.UnitGUID = function()
		if guid == false then
			return nil
		end
		return guid or "Player-1"
	end
	env.IsInGuild = function()
		return true
	end
	env.IsInGroup = function()
		return false
	end
	env.IsInRaid = function()
		return false
	end
	env.C_GameRules = {
		GetCurrentGameModeRecordID = function()
			return mode
		end,
		IsHardcoreActive = function()
			return hardcore
		end,
	}
	env.C_Timer = {
		After = function(_, callback)
			timers[#timers + 1] = callback
		end,
	}
	env.C_ChatInfo = {
		SendAddonMessage = function(_, payload, channel)
			sent[#sent + 1] = { payload = payload, channel = channel }
			return true
		end,
	}
	env.CreateFrame = function()
		local frame = { events = {} }
		function frame:RegisterEvent(event)
			self.events[event] = true
		end
		function frame:SetScript(_, callback)
			self.callback = callback
		end
		frames[#frames + 1] = frame
		return frame
	end
	env.strtrim = function(text)
		return text:match("^%s*(.-)%s*$")
	end
	env.CommissionsForeverDB = saved or {}
	local ns = {}
	for _, path in ipairs({
		"Locales/enUS.lua",
		"Core/PeerStats.lua",
	}) do
		setfenv(assert(loadfile(path)), env)("CommissionsForever", ns)
	end
	ns.Questie = {
		CommissionCategory = function(id)
			return id == 123 and "thoriumBrotherhood" or nil
		end,
		Available = function()
			return true
		end,
	}
	env.DEFAULT_CHAT_FRAME = {
		AddMessage = function(_, text)
			lines[#lines + 1] = text
		end,
	}
	setfenv(assert(loadfile("Core/Stats.lua")), env)("CommissionsForever", ns)
	local kit = { ns = ns, env = env, sent = sent, lines = lines }
	function kit.fire(event, ...)
		for _, frame in ipairs(frames) do
			if frame.events[event] and frame.callback then
				frame.callback(frame, event, ...)
			end
		end
	end
	function kit.flush()
		local rounds = 0
		while #timers > 0 do
			rounds = rounds + 1
			assert(rounds < 100, "bounded timer work")
			local due = timers
			timers = {}
			for _, callback in ipairs(due) do
				callback()
			end
		end
	end
	function kit.hear(sender, subject, value, eventUnix)
		now = now + 2
		kit.fire(
			"CHAT_MSG_ADDON",
			"WFAStats",
			("1|commissions|commission_turnin|%s|%d|%d"):format(subject, value, eventUnix or 1000),
			"GUILD",
			sender
		)
	end
	return kit
end

local kit = boot(nil, 1, false)
local stats = kit.ns.Stats
check(stats.Participating(), "sharing defaults on")
kit.fire("PLAYER_LOGIN")
kit.flush()
check(#kit.sent == 0, "login does not invent past completions")
kit.fire("QUEST_TURNED_IN", 123)
kit.fire("QUEST_TURNED_IN", 123)
kit.flush()
check(stats.Activity()[1].value == 2, "two events for the same ID in one second count twice")
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "QUEST_LOG_UPDATE", "QUEST_COMPLETE", "QUEST_REMOVED" }) do
	kit.fire(event, 123)
end
kit.fire("QUEST_TURNED_IN", 124)
kit.fire("QUEST_TURNED_IN", "123")
check(stats.Activity()[1].value == 2, "unrelated quests and non-completion events cannot advance totals")
kit.hear("Bob-Home", "1_0", 8)
kit.hear("Alice-Home", "1_0", 8)
kit.hear("Hardcore-Home", "1_1", 99)
local board = stats.Leaderboard(1)
check(
	#board.rows == 2 and board.rows[1].name == "Alice" and board.rows[2].self,
	"deterministic tied rank, matching ruleset and personal row below the limit"
)
board.rows[1].value = 999
check(stats.Leaderboard().rows[1].value == 8, "public reads return fresh copies")
check(stats.Leaderboard(-1) == nil and stats.Leaderboard("1") == nil, "invalid limits fail explicitly")
check(not stats.SetEnabled("false"), "switch accepts booleans only")
check(stats.SetEnabled(false) and not stats.Participating(), "saved false stays false")
kit.flush()
local sent = #kit.sent
kit.fire("QUEST_TURNED_IN", 123)
kit.flush()
check(stats.Activity()[1].value == 3 and #kit.sent == sent, "opt-out keeps local history without publishing")
kit.hear("Ignored-Home", "1_0", 50)
check(#stats.Leaderboard().rows == 1, "opt-out hides peers and stops receiving")
local restored = boot(kit.env.CommissionsForeverDB, 1, false)
restored.fire("PLAYER_LOGIN")
restored.flush()
check(
	not restored.ns.Stats.Participating() and restored.ns.Stats.Activity()[1].value == 3,
	"reload preserves opt-out and does not replay completions"
)
local unknown = boot(nil, nil, false)
unknown.fire("QUEST_TURNED_IN", 123)
unknown.flush()
check(
	unknown.ns.Stats.Activity()[1].value == 1 and #unknown.sent == 0,
	"unknown client ruleset records personal events without publishing a guessed category"
)
local unavailable = boot(nil, 1, false, false)
unavailable.fire("QUEST_TURNED_IN", 123)
check(unavailable.ns.Stats.Activity()[1].value == 0, "missing character identity fails closed")
local queued = boot(nil, 1, false)
queued.fire("QUEST_TURNED_IN", 123)
queued.ns.Stats.SetEnabled(false)
queued.flush()
check(#queued.sent == 0, "opting out cancels an already queued snapshot")
queued.ns.Stats.SetEnabled(true)
queued.flush()
check(#queued.sent == 1 and queued.sent[1].payload:find("|1|2000$"), "re-enable publishes the preserved local total")
local secret = boot(nil, 1, false, "secret")
secret.env.issecretvalue = function(value)
	return value == "secret"
end
secret.fire("QUEST_TURNED_IN", 123)
check(secret.ns.Stats.Activity()[1].value == 0, "secret character identity is never indexed")
local noClock = boot(nil, 1, false)
noClock.env.GetServerTime = function()
	return nil
end
noClock.fire("QUEST_TURNED_IN", 123)
check(noClock.ns.Stats.Activity()[1].value == 0, "an unavailable event timestamp is not invented")
stats.Print()
check(#kit.lines > 0, "ranked view is printable")
print(("Commissions stats adapter: %d checks passed"):format(checks))
