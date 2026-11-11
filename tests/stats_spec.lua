local checks = 0
local function check(value, label)
	checks = checks + 1
	assert(value, label)
end

-- Core/Stats.lua alone: the local completion record, its client events and the dead Forever Leaderboards data it
-- clears on load. Chat delivery is gone with the board, so the harness stubs no addon channel.
local function boot(saved, guid)
	local frames = {}
	local notifications = {}
	local now = 2000
	local env = setmetatable({}, { __index = _G })
	env.GetServerTime = function()
		return now
	end
	env.UnitGUID = function()
		if guid == false then
			return nil
		end
		return guid or "Player-1"
	end
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
	env.CommissionsForeverDB = saved or {}
	local ns = {}
	ns.APIChanged = function(kind)
		notifications[kind] = (notifications[kind] or 0) + 1
	end
	ns.Questie = {
		CommissionCategory = function(id)
			return id == 123 and "thoriumBrotherhood" or nil
		end,
	}
	setfenv(assert(loadfile("Core/Stats.lua")), env)("CommissionsForever", ns)
	local kit = { ns = ns, env = env, notifications = notifications }
	function kit.fire(event, ...)
		for _, frame in ipairs(frames) do
			if frame.events[event] and frame.callback then
				frame.callback(frame, event, ...)
			end
		end
	end
	return kit
end

-- The saved peer table and sharing switch are dead data: load clears them and keeps the local total.
local saved = {
	statsShare = true,
	completionRecords = {
		["Player-1"] = { total = 4, eventUnix = 900, peers = { { identity = "Bob", value = 9 } } },
		["Player-2"] = { total = 2, peers = {} },
		foreign = "not a record",
	},
}
local kit = boot(saved)
local stats = kit.ns.Stats
check(
	stats.Leaderboard == nil and stats.Participating == nil and stats.SetEnabled == nil,
	"the shared board's members are gone"
)
kit.fire("PLAYER_LOGIN")
check(kit.env.CommissionsForeverDB.statsShare == nil, "the saved sharing switch is dropped on load")
check(saved.completionRecords["Player-1"].peers == nil, "the saved peer table is dropped on load")
check(saved.completionRecords["Player-2"].peers == nil, "every character's peer table is dropped")
check(saved.completionRecords.foreign == "not a record", "a save that is not a record is left alone")
check(stats.Activity()[1].value == 4, "the local total survives the cleanup")

kit.fire("QUEST_TURNED_IN", 123)
kit.fire("QUEST_TURNED_IN", 123)
check(stats.Activity()[1].value == 6, "two events for the same ID in one second count twice")
check(kit.notifications.turnin == 2, "each recorded completion tells the API's hub")
for _, event in ipairs({ "BAG_UPDATE_DELAYED", "QUEST_LOG_UPDATE", "QUEST_COMPLETE", "QUEST_REMOVED" }) do
	kit.fire(event, 123)
end
kit.fire("QUEST_TURNED_IN", 124)
kit.fire("QUEST_TURNED_IN", "123")
check(stats.Activity()[1].value == 6, "unrelated quests and non-completion events cannot advance totals")
check(kit.notifications.turnin == 2, "only a recorded completion tells the API's hub")

local restored = boot(kit.env.CommissionsForeverDB)
restored.fire("PLAYER_LOGIN")
check(restored.ns.Stats.Activity()[1].value == 6, "a reload keeps the local total without replaying completions")

local unavailable = boot(nil, false)
unavailable.fire("QUEST_TURNED_IN", 123)
check(unavailable.ns.Stats.Activity()[1].value == 0, "missing character identity fails closed")

local secret = boot(nil, "secret")
secret.env.issecretvalue = function(value)
	return value == "secret"
end
secret.fire("QUEST_TURNED_IN", 123)
check(secret.ns.Stats.Activity()[1].value == 0, "secret character identity is never indexed")

local noClock = boot(nil)
noClock.env.GetServerTime = function()
	return nil
end
noClock.fire("QUEST_TURNED_IN", 123)
check(noClock.ns.Stats.Activity()[1].value == 0, "an unavailable event timestamp is not invented")

local anonymous = boot(nil)
check(anonymous.ns.Stats.Activity()[1].eventUnix == nil, "no completion leaves no event time")
print(("Commissions stats: %d checks passed"):format(checks))
