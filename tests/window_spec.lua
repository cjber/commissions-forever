-- The window: every row is listed however long the list grows, and a missing QuestieDB is named.
local frames = {}
local function Region()
	local region = { shown = true, text = "", children = {} }
	return setmetatable(region, {
		__index = function(_, key)
			local methods = {
				CreateFontString = function(self)
					local child = Region()
					self.children[#self.children + 1] = child
					return child
				end,
				SetText = function(self, text)
					self.text = text
				end,
				GetText = function(self)
					return self.text
				end,
				SetShown = function(self, shown)
					self.shown = shown and true or false
				end,
				Hide = function(self)
					self.shown = false
				end,
				IsShown = function(self)
					return self.shown
				end,
				SetHeight = function(self, height)
					self.height = height
				end,
			}
			return methods[key] or function() end
		end,
	})
end
rawset(_G, "CreateFrame", function()
	local frame = Region()
	frame.TitleText = Region()
	frames[#frames + 1] = frame
	return frame
end)
rawset(_G, "UIParent", Region())
rawset(_G, "UISpecialFrames", {})
rawset(_G, "C_Item", {
	GetItemNameByID = function(itemID)
		return "Item " .. itemID
	end,
})

local available = true
local ns = {
	L = setmetatable({}, {
		__index = function(_, key)
			return key
		end,
	}),
	Questie = {
		Available = function()
			return available
		end,
	},
}
local window = assert(loadfile("UI/Window.lua"))("CommissionsForever", ns)

local function Shown()
	local texts = {}
	for _, row in ipairs(window.rows) do
		if row.text ~= "" then
			texts[#texts + 1] = row.text
		end
	end
	return texts
end

ns.Rows = {}
for index = 1, 13 do
	ns.Rows[index] = { turnIn = { faction = "Thorium Brotherhood" }, itemID = index, count = index }
end
window:Refresh()
local texts = Shown()
assert(#texts == 13, "all 13 rows are listed, not the first 12: got " .. #texts)
assert(texts[13]:find("Item 13", 1, true), "the 13th row is the 13th item")

ns.Rows = { ns.Rows[1] }
window:Refresh()
assert(#Shown() == 1, "a shorter list clears the rows it no longer uses")

assert(window.notice and not window.notice.shown, "no notice while QuestieDB is installed")
available = false
window:Refresh()
assert(window.notice.shown, "the window says QuestieDB is missing")
assert(window.notice.text == "Install QuestieDB to see your active turn-ins.", "in one plain line")

print("Commissions Forever window specs passed")
