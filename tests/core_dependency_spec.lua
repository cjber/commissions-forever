-- Run from the repository root: luajit tests/core_dependency_spec.lua
-- Commissions Forever requires ForeverCore. This spec covers the one-line stop for a ForeverCore older than API 1.
-- The game already refuses to load the addon when ForeverCore is absent; this stops the addon's own files when an
-- installed ForeverCore is too old for what they call.
local function Require(foreverCore)
	local lines = {}
	local env = {
		UIErrorsFrame = {
			AddMessage = function(_, text, red, green, blue)
				lines[#lines + 1] = { text = text, red = red, green = green, blue = blue }
			end,
		},
		ForeverCore = foreverCore,
	}
	env._G = env
	setmetatable(env, { __index = _G })
	local addon = {}
	setfenv(assert(loadfile("Core/Require.lua")), env)("CommissionsForever", addon)
	return addon, lines
end

local missing, missingLines = Require(nil)
assert(missing.broken == true, "a missing ForeverCore stops the addon")
assert(#missingLines == 1 and missingLines[1].text:find("ForeverCore", 1, true), "and names it in one error line")

local old, oldLines = Require({ API = 0 })
assert(old.broken == true and #oldLines == 1, "a ForeverCore older than API 1 stops the addon too")

-- ForeverCore 1.0.0 has API 1 but no shared API kit, which Core/API.lua calls, so it is too old as well.
local noKit, noKitLines = Require({ API = 1 })
assert(noKit.broken == true and #noKitLines == 1, "a ForeverCore without the API kit stops the addon")
assert(noKitLines[1].text:find("ForeverCore", 1, true), "and names it in one error line")

local ready, readyLines = Require({ API = 1, APIKit = {} })
assert(ready.broken == nil, "API 1 with the API kit runs the addon")
assert(#readyLines == 0, "and says nothing")

print("core_dependency_spec: ok")
