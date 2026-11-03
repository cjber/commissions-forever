-- Native Professions page, real event ordering and a long materials list.
local function Region()
	local region = { shown = false, text = "", children = {}, scripts = {}, hooks = {}, width = 673, height = 594 }
	return setmetatable(region, {
		__index = function(_, key)
			local methods = {
				CreateFontString = function()
					return Region()
				end,
				CreateTexture = function()
					return Region()
				end,
				SetText = function(self, value)
					self.text = tostring(value)
				end,
				GetText = function(self)
					return self.text
				end,
				SetSize = function(self, width, height)
					self.width, self.height = width, height
				end,
				SetHeight = function(self, height)
					self.height = height
				end,
				GetWidth = function(self)
					return self.width
				end,
				SetShown = function(self, shown)
					if shown then
						self:Show()
					else
						self:Hide()
					end
				end,
				Show = function(self)
					if self.shown then
						return
					end
					self.shown = true
					if self.scripts.OnShow then
						self.scripts.OnShow(self)
					end
					for _, fn in ipairs(self.hooks.OnShow or {}) do
						fn(self)
					end
				end,
				Hide = function(self)
					if not self.shown then
						return
					end
					self.shown = false
					if self.scripts.OnHide then
						self.scripts.OnHide(self)
					end
					for _, fn in ipairs(self.hooks.OnHide or {}) do
						fn(self)
					end
				end,
				IsShown = function(self)
					return self.shown
				end,
				SetScript = function(self, event, fn)
					self.scripts[event] = fn
				end,
				HookScript = function(self, event, fn)
					self.hooks[event] = self.hooks[event] or {}
					table.insert(self.hooks[event], fn)
				end,
				GetChildren = function(self)
					return unpack(self.children)
				end,
				SetChecked = function(self, checked)
					self.checked = checked
				end,
				SetCustomOnMouseUpHandler = function(self, fn)
					self.click = fn
				end,
				GetLeft = function()
					return 10
				end,
				GetBottom = function()
					return 100
				end,
				GetTop = function()
					return 500
				end,
			}
			return methods[key] or function() end
		end,
	})
end
local frames = {}
_G.CreateFrame = function(_, _, parent)
	local frame = Region()
	frame.Icon = Region()
	if parent then
		table.insert(parent.children, frame)
	end
	table.insert(frames, frame)
	return frame
end
local host = Region()
_G.ProfessionsFrame = host
host.CraftingPage = Region()
host.BookPage = Region()
host.ProfessionsOverviewTab = Region()
host.rightProfessionTabs = {}
_G.ShowProfessionsFrame = function()
	ProfessionsFrame:Show()
end
_G.HideUIPanel = function(frame)
	frame:Hide()
end
_G.GameTooltip = Region()
local requested = {}
local cached = true
_G.C_Item = {
	RequestLoadItemDataByID = function(id)
		requested[id] = true
	end,
	GetItemNameByID = function(id)
		return cached and ("Item " .. id) or nil
	end,
	GetItemIconByID = function(id)
		return id
	end,
}
local available = true
local ns = { Questie = {
	Available = function()
		return available
	end,
} }
assert(loadfile("Locales/enUS.lua"))("CommissionsForever", ns)
local window = assert(loadfile("UI/Window.lua"))("CommissionsForever", ns)
local function Visible()
	local count = 0
	for _, row in ipairs(window.rows) do
		if row.shown then
			count = count + 1
		end
	end
	return count
end
ns.Rows = {}
for index = 1, 30 do
	ns.Rows[index] = { turnIn = { faction = "Thorium Brotherhood" }, itemID = index, count = index }
end
window.Toggle()
assert(window.page.shown and ProfessionsFrame.shown, "slash command opens the native host and commissions page")
window.Refresh()
assert(Visible() == 30 and window.list.height == 30 * 30, "all rows remain reachable through scrolling")
assert(window.rows[30].name.text == "Item 30", "the final row is not lost")
window.search:SetText("Item 30")
window.search.hooks.OnTextChanged[1]()
assert(Visible() == 1 and window.rows[1].name.text == "Item 30", "search filters without losing the final row")
window.search:SetText("missing")
window.Refresh()
assert(Visible() == 0 and window.empty.shown, "empty search is explicit")
window.search:SetText("")
ns.Rows = { ns.Rows[1] }
window.Refresh()
assert(Visible() == 1 and not window.empty.shown, "shorter lists hide old rows")
assert(window.rows[1].need.text == "-", "unknown requirements are not invented")
ns.Rows[1].need = 10
window.Refresh()
assert(window.rows[1].need.text == "10", "active quest requirements show separately")
available = false
window.Refresh()
assert(window.notice.shown, "missing QuestieDB is named while bag counts remain")
ProfessionsFrame.CraftingPage:Show()
assert(not window.page.shown and not window.tab.checked, "native profession selection deselects commissions")
ProfessionsFrame.CraftingPage:Hide()
local otherPage = Region()
otherPage:Show()
ProfessionsFrame.CraftingPage:HookScript("OnShow", function()
	otherPage:Hide()
end)
window.tab.click(nil, "LeftButton", true)
assert(window.page.shown and not otherPage.shown, "native handoff lets another addon page deselect")
window.Toggle()
assert(not ProfessionsFrame.shown and not window.page.shown, "toggle closes the native host cleanly")
cached = false
window.Refresh()
assert(requested[1] and window.rows[1].name.text == "Item 1", "uncached items request data and keep a usable fallback")
cached = true
print("Commissions Forever window specs passed")
