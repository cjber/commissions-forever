-- The shared error journal and debug log in the saved table, and /cf report through the addon's slash command.
local checks = 0
local function check(value, label)
	checks = checks + 1
	assert(value, label)
end

-- The client pieces Core/SafeCall.lua and Core/Log.lua install against.
local frames = {}
_G.CreateFrame = function()
	local frame = {
		RegisterEvent = function() end,
	}
	frame.SetScript = function(self, event, handler)
		self[event] = handler
	end
	frames[#frames + 1] = frame
	return frame
end
_G.strtrim = function(text)
	return text:match("^%s*(.-)%s*$")
end
_G.geterrorhandler = function()
	return function() end
end
_G.seterrorhandler = function() end
_G.time = function()
	return 100
end
_G.GetTime = function()
	return 1
end
_G.date = function()
	return "2026-11-08 12:00:00"
end
_G.ForeverErrorJournal = nil
_G.ForeverDebugLog = nil
_G.SlashCmdList = {}

-- Saved variables load before PLAYER_LOGIN, as the client sends them.
_G.CommissionsForeverDB = {}

local ns = {
	Model = {
		IsCommissionQuest = function(name)
			return name == "Feathers for Nafien"
		end,
		Inventory = function()
			return { { itemID = 1 } }
		end,
	},
	Questie = {
		Available = function()
			return true
		end,
		ActiveObjectives = function()
			return {}
		end,
	},
	ShortestPath = {
		Navigate = function()
			return false
		end,
	},
	Stats = {
		Participating = function()
			return true
		end,
	},
	Window = {
		Refresh = function() end,
		Toggle = function() end,
	},
}

-- The TOC's order for the files this spec needs.
for _, path in ipairs({
	"Locales/enUS.lua",
	"Core/SafeCall.lua",
	"Core/Log.lua",
	"Core/Core.lua",
	"Core/Report.lua",
	"UI/Art.lua",
	"UI/Report.lua",
}) do
	assert(loadfile(path))("CommissionsForever", ns)
end

-- Saved variables load, then PLAYER_LOGIN creates and attaches the addon's tables.
ns.Addon.OnEvent(ns.Addon, "PLAYER_LOGIN")
check(type(CommissionsForeverDB.errors) == "table", "PLAYER_LOGIN creates the error journal table")
check(
	type(CommissionsForeverDB.log) == "table" and type(CommissionsForeverDB.log.lines) == "table",
	"PLAYER_LOGIN creates the debug log ring"
)
check(CommissionsForeverDB.log.pinned == false, "a fresh debug log is unpinned")

-- A recorded error lands in the attached journal, so it survives the next reload.
ns.RecordError("spec", "journal entry", "spec.lua:1: here")
local journaled
for _, entry in ipairs(CommissionsForeverDB.errors) do
	if entry.message == "journal entry" then
		journaled = entry.kind
	end
end
check(journaled == "error", "a recorded error is kept in the saved journal")

-- An error caught through ns.SafeCall is kept too, and still reaches the game's handler.
local ok = ns.SafeCall("spec call", function()
	error("safe call entry", 0)
end)
check(not ok, "SafeCall reports the failure")
local caught
for _, entry in ipairs(CommissionsForeverDB.errors) do
	if entry.message:find("safe call entry", 1, true) then
		caught = entry.kind
	end
end
check(caught == "error", "an error caught through SafeCall reaches the saved journal")

-- The log ring is the saved table too.
ns.Log("info", "spec", "logged before a reload")
local logged
for _, line in ipairs(CommissionsForeverDB.log.lines) do
	if line:find("logged before a reload", 1, true) then
		logged = line
	end
end
check(logged ~= nil, "a log line is kept in the saved ring")

-- /cf report goes to the shared report before the addon's own commands.
local reported, toggled
ns.Report.Command = function(command)
	reported = command
	return command == "report"
end
ns.Window.Toggle = function()
	toggled = true
end
SlashCmdList.COMMISSIONSFOREVER("report")
check(reported == "report", "/cf report is handled by ns.Report.Command")
check(not toggled, "/cf report does not fall through to the addon's command")

print(("error_journal_spec: %d checks passed"):format(checks))
