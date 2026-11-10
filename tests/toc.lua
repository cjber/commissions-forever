-- The addon's TOC fields, as C_AddOns.GetAddOnMetadata reports them to the client at load. A spec reads the same
-- declared values the addon reads at runtime, so it follows the TOC instead of repeating what the TOC owns.
local Toc = {}

local cache = {}

---@param addon string
---@return table<string, string>
function Toc.metadata(addon)
	if cache[addon] then
		return cache[addon]
	end
	local fields = {}
	local file = assert(io.open(addon .. ".toc", "r"), addon .. ".toc")
	for line in file:lines() do
		local key, value = line:match("^##%s*([^:]+):%s*(.-)%s*$")
		if key then
			fields[key] = value
		end
	end
	file:close()
	cache[addon] = fields
	return fields
end

---@param addon string
---@param field string
---@return string?
function Toc.get(addon, field)
	return Toc.metadata(addon)[field]
end

--- C_AddOns.GetAddOnMetadata as the client answers it for the addon under test.
---@param env table
---@param addon string
function Toc.install(env, addon)
	env.C_AddOns = env.C_AddOns or {}
	env.C_AddOns.GetAddOnMetadata = function(name, field)
		if name ~= addon then
			return nil
		end
		return Toc.get(addon, field)
	end
end

return Toc
