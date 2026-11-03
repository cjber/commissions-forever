local _, ns = ...

---@type table<string, string | boolean>
ns.L = {
	["Commissions Forever"] = true,
	["No tracked materials found"] = true,
	["Open turn-in route"] = true,
	["No active commission route is available."] = true,
	["Install QuestieDB to see your active turn-ins."] = true,
	["Material"] = true,
	["Turn-in"] = true,
	["Have"] = true,
	["Need"] = true,
	["Item %d"] = true,
}

-- `true` marks a phrase that reads as its own English key.
for key, value in pairs(ns.L) do
	if value == true then
		ns.L[key] = key
	end
end
