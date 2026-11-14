-- Actual packaged Commissions graph. The client restores saved globals after TOC execution.
local core, packages = assert(arg[1]), assert(arg[2])
local FakeClient = dofile(core .. "/tests/fake_client.lua")
local Toc = dofile(core .. "/.agents/skills/wow-forever-addon/tooling/forever_sim/toc.lua")
local function clone(value)
	if type(value) ~= "table" then
		return value
	end
	local result = {}
	for key, item in pairs(value) do
		result[key] = clone(item)
	end
	return result
end
local function session(order, saved)
	local env, frames = FakeClient.new()
	env.ObjectiveTrackerFrame = nil
	env.C_Item = {
		GetItemCount = function()
			return 0
		end,
	}
	env.UnitGUID = function()
		return "Player-1"
	end
	local loggedIn = false
	env.IsLoggedIn = function()
		return loggedIn
	end
	local hosts = {}
	local declarations = {}
	local function event(name, addon)
		if name == "PLAYER_LOGIN" then
			loggedIn = true
		end
		local listeners = {}
		for _, frame in ipairs(frames) do
			if frame.events[name] then
				listeners[#listeners + 1] = frame
			end
		end
		for _, frame in ipairs(listeners) do
			frame.scripts.OnEvent(frame, name, addon)
		end
	end
	for _, folder in ipairs(order) do
		local legacy = folder == "Legacy"
		local path = legacy and assert(arg[3]) or packages .. "/" .. folder
		folder = legacy and "ForeverCore" or folder
		local host = {}
		hosts[folder] = host
		for _, file in ipairs(Toc.files(path, folder .. ".toc")) do
			if file.kind == "lua" then
				setfenv(assert(loadfile(file.path)), env)(folder, host)
			else
				for _, template in ipairs(Toc.templates(file.path)) do
					assert(not declarations[template.name], "unique eager template")
					declarations[template.name] = folder
				end
			end
		end
		if folder == "CommissionsForever" then
			assert(not host.core, "consumer waits for restored globals")
		end
		env[folder .. "DB"] = (folder == "CommissionsForever" and saved and clone(saved))
			or { statsShare = true, completionRecords = { old = { peers = {} } } }
		event("ADDON_LOADED", folder)
	end
	event("VARIABLES_LOADED")
	event("PLAYER_LOGIN")
	assert(not env.ForeverCoreLoader.Error(), env.ForeverCoreLoader.Error())
	assert(not env.ForeverCoreLoader.CallbackError(), env.ForeverCoreLoader.CallbackError())
	local selected = env.ForeverCoreLoader.Selected()
	local template = selected.mode == "legacy" and "ForeverTrackerInteractiveLineTemplate"
		or env.ForeverCore.TrackerLine.template
	assert(
		declarations[template] == (selected.mode == "legacy" and "ForeverCore" or selected.folder),
		"template belongs to installed elected owner"
	)
	if selected.mode ~= "legacy" then
		assert(env.ForeverCore.Art.Marker(1) == selected.root .. "\\media\\Numbers\\1", "elected media root")
	end
	local ns = assert(hosts.CommissionsForever)
	assert(ns.core and ns.Window and ns.API and ns.Refreshed, "actual full consumer starts")
	assert(env.CommissionsForeverDB.statsShare == nil, "late startup migrates saved data")
	assert(env.CommissionsForeverDB.completionRecords.old.peers == nil)
	assert(env.SlashCmdList.COMMISSIONSFOREVER, "late startup installs slash command")
	local count = #frames
	ns.Start()
	assert(#frames == count, "startup is idempotent")
	if saved then
		assert(
			env.ForeverCoreLoader.Namespace().Store().trackerHost.scale == 1.37,
			"surviving consumer restores shared settings"
		)
	end
	if env.ForeverCoreLoader.Namespace() then
		env.ForeverCoreLoader.Namespace().Store().trackerHost.scale = 1.37
	end
	return clone(env.CommissionsForeverDB)
end
local saved = session({ "CommissionsForever" })
session({ "CommissionsForever" }, saved)
local standaloneSaved = session({ "ForeverCore", "CommissionsForever" })
session({ "CommissionsForever" }, standaloneSaved)
session({ "CommissionsForever", "ForeverCore" })
local mixed = session({ "ConsumerB", "CommissionsForever" })
session({ "CommissionsForever" }, mixed)
session({ "CommissionsForever", "ConsumerB" })
session({ "ConsumerB", "ForeverCore", "CommissionsForever" })
session({ "CommissionsForever", "ForeverCore", "ConsumerB" })
session({ "ForeverCore", "CommissionsForever", "ConsumerB" })
session({ "ForeverCore", "ConsumerB", "CommissionsForever" })
session({ "CommissionsForever", "ConsumerB", "ForeverCore" })
session({ "ConsumerB", "CommissionsForever", "ForeverCore" })
session({ "Legacy", "CommissionsForever" })
session({ "CommissionsForever", "Legacy" })
print("actual Commissions startup passed")
