-- Every English phrase is text: the window and chat pass it straight to SetText and AddMessage.
local ns = {}
assert(loadfile("Locales/enUS.lua"))("CommissionsForever", ns)
local count = 0
for key, value in pairs(ns.L) do
	assert(type(value) == "string", key .. " is text, not " .. tostring(value))
	count = count + 1
end
assert(count > 0, "the English table has phrases")
assert(ns.L["Commissions Forever"] == "Commissions Forever", "the window title is its English phrase")
print("Commissions Forever locale specs passed")
