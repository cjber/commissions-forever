local _, ns = ...

ns.L = {
	["Commissions Forever"] = true,
	["Turn-ins"] = true,
	["Materials in bags"] = true,
	["No tracked materials found"] = true,
	["Open turn-in route"] = true,
	["No active commission route is available."] = true,
	["Install QuestieDB to see your active turn-ins."] = true,
	["Have %d"] = "Have %d",
	["Need %d"] = "Need %d",
}

-- `true` marks a phrase that reads as its own English key.
for key, value in pairs(ns.L) do
	if value == true then
		ns.L[key] = key
	end
end
