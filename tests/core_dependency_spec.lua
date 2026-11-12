-- Run from the repository root: luajit tests/core_dependency_spec.lua
-- Commissions Forever requires ForeverCore. This spec covers the shared out-of-date warning: Core/Require.lua checks
-- the post-API-1 members and module minors this addon calls and hands one boolean to Core/ForeverRequire.lua, which
-- core's own tests/forever_require_spec.lua holds to the naming and plural rules.
local Toc = dofile("tests/toc.lua")

local THIS = "CommissionsForever"

-- The client's addon list: this addon and ForeverCore, both loaded. GetAddOnDependencies returns its names as
-- varargs, as the client does, not a table.
local function Addons()
	local entries = {
		{
			name = THIS,
			title = "Commissions Forever",
			version = Toc.get(THIS, "X-Forever-Core"),
			deps = { "ForeverCore" },
		},
		{ name = "ForeverCore", title = "Forever Core", version = "v1.5.0", deps = {} },
	}
	local function At(index)
		return entries[index]
	end
	return {
		GetNumAddOns = function()
			return #entries
		end,
		GetAddOnInfo = function(index)
			local entry = At(index)
			if entry then
				return entry.name, entry.title
			end
		end,
		IsAddOnLoaded = function(index)
			return At(index) ~= nil
		end,
		GetAddOnEnableState = function(index)
			return At(index) and 2 or 0
		end,
		GetAddOnDependencies = function(index)
			local entry = At(index)
			if entry then
				return unpack(entry.deps)
			end
		end,
		GetAddOnMetadata = function(addon, field)
			if addon == THIS then
				return Toc.get(THIS, field)
			end
			for _, entry in ipairs(entries) do
				if entry.name == addon then
					if field == "Title" then
						return entry.title
					end
					if field == "X-Forever-Core" then
						return entry.version
					end
				end
			end
		end,
	}
end

local function Require(foreverCore)
	local lines = {}
	local env = {
		UIErrorsFrame = {
			AddMessage = function(_, text, red, green, blue)
				lines[#lines + 1] = { text = text, red = red, green = green, blue = blue }
			end,
		},
		ForeverCore = foreverCore,
		C_AddOns = Addons(),
		UnitName = function()
			return "Tester"
		end,
	}
	env._G = env
	setmetatable(env, { __index = _G })
	local addon = {}
	-- The addon's TOC loads the shared warning before its own Require, which calls it.
	setfenv(assert(loadfile("Core/ForeverRequire.lua")), env)(THIS, addon)
	setfenv(assert(loadfile("Core/Require.lua")), env)(THIS, addon)
	return addon, lines
end

-- APIKit arrived after API 1; a core without it is too old for Core/API.lua.
local noKit, noKitLines = Require({ API = 1 })
assert(noKit.broken == true, "a ForeverCore without the API kit stops the addon")
assert(#noKitLines == 1, "and the shared warning says so in one error line")

-- ProfessionTabs also arrived after API 1; UI/Window.lua asserts it.
local noTabs, noTabsLines = Require({ API = 1, APIKit = {} })
assert(noTabs.broken == true, "a ForeverCore without the shared Professions tabs stops the addon")
assert(#noTabsLines == 1, "and the shared warning says so in one error line")
assert(
	noTabsLines[1].text == "Commissions Forever could not start. Reinstall Commissions Forever to fix this.",
	noTabsLines[1].text
)

-- A missing core stops it too; the game normally refuses to load the addon first.
local missing, missingLines = Require(nil)
assert(missing.broken == true, "a missing ForeverCore stops the addon")
assert(#missingLines == 1, "and the shared warning says so in one error line")

-- ProfessionTabs minor 2, from ForeverCore 1.8.1, hides the client's own page beneath the addon page. An earlier
-- tabs module draws the two pages over each other.
local oldTabs, oldTabsLines = Require({ API = 1, APIKit = {}, ProfessionTabs = { minor = 1 } })
assert(oldTabs.broken == true, "a ForeverCore with ProfessionTabs minor 1 stops the addon")
assert(#oldTabsLines == 1, "and the shared warning says so in one error line")

-- A tabs module that predates the minor counter is older still, and a missing minor counts as 0.
local unversionedTabs, unversionedLines = Require({ API = 1, APIKit = {}, ProfessionTabs = {} })
assert(unversionedTabs.broken == true, "a ForeverCore with an unversioned ProfessionTabs stops the addon")
assert(#unversionedLines == 1, "and the shared warning says so in one error line")

local ready, readyLines = Require({ API = 1, APIKit = {}, ProfessionTabs = { minor = 2 } })
assert(ready.broken == nil, "a core with every member the addon calls runs it")
assert(#readyLines == 0, "and says nothing")

print("core_dependency_spec: ok")
