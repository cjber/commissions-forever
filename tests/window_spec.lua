-- Native Professions page, real event ordering and a long materials list.
local function Region()
	local region = { shown = false, text = "", children = {}, scripts = {}, hooks = {}, width = 673, height = 594 }
	return setmetatable(region, {
		__index = function(_, key)
			local methods = {
				CreateFontString = function()
					return Region()
				end,
				CreateTexture = function(_, _, layer)
					local texture = Region()
					texture.layer = layer
					return texture
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
				SetScale = function(self, scale)
					self.scale = scale
				end,
				GetScale = function(self)
					return self.scale or 1
				end,
				SetBlendMode = function(self, blend)
					self.blend = blend
				end,
				SetAtlas = function(self, atlas)
					self.atlas = atlas
				end,
				SetHighlightTexture = function(self, texture, blendMode)
					self.highlightTexture, self.highlightBlend = texture, blendMode
				end,
				SetHeight = function(self, height)
					self.height = height
				end,
				GetHeight = function(self)
					return self.height
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
				SetPoint = function(self, ...)
					self.point = { ... }
				end,
				GetLeft = function(self)
					return rawget(self, "left") or 10
				end,
				GetBottom = function(self)
					return rawget(self, "bottom") or 100
				end,
				GetTop = function(self)
					return rawget(self, "top") or 500
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
	frame.Text = Region()
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
		return cached and ("Cached item " .. id) or nil
	end,
	GetItemIconByID = function(id)
		return id
	end,
}
local available = true
local ns = {
	Stats = {
		Participating = function()
			return true
		end,
	},
	Questie = {
		Available = function()
			return available
		end,
	},
}
assert(loadfile("Locales/enUS.lua"))("CommissionsForever", ns)
assert(loadfile("UI/Art.lua"))("CommissionsForever", ns)
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
-- Two other addon tabs occupy consecutive slots outside the native profession array.
local firstTab, secondTab = Region(), Region()
firstTab.top, firstTab.bottom = 98, 60
secondTab.top, secondTab.bottom = 58, 20
firstTab:Show()
secondTab:Show()
host.children[#host.children + 1] = firstTab
host.children[#host.children + 1] = secondTab
ns.Rows = {}
for index = 1, 30 do
	ns.Rows[index] = { turnIn = { faction = "Thorium Brotherhood" }, itemID = index, count = index }
end
window.Toggle()
assert(window.page.shown and ProfessionsFrame.shown, "slash command opens the native host and commissions page")
assert(window.tab.point[2] == secondTab, "commissions leaves both existing addon tabs visible and uses the next slot")
assert(firstTab.shown and secondTab.shown, "placing commissions does not hide other addon tabs")
window.Refresh()
assert(Visible() == 30 and window.list.height == 30 * 30, "all rows remain reachable through scrolling")
assert(window.rows[30].name.text == "Cached item 30", "the final row is not lost")
assert(window.inset.background.atlas == "common-insideframe", "the ledger inset uses the native common-insideframe")
local row = window.rows[1]
local scale = 30 / 69
assert(row.background.atlas == "common-button-list-large", "row background uses the native list row atlas")
assert(row.selected.atlas == "common-button-list-large-selected", "row selected state uses the native list row atlas")
assert(row.hover.atlas == "common-button-list-large-hover", "row hover uses the native list row atlas")
assert(
	row.background.height == 69 and row.selected.height == 69 and row.hover.height == 69,
	"row art keeps the list atlases' native 69 height"
)
assert(
	math.abs(row.background:GetScale() - scale) < 1e-9
		and math.abs(row.selected:GetScale() - scale) < 1e-9
		and math.abs(row.hover:GetScale() - scale) < 1e-9,
	"row art scales uniformly to the 30-high row"
)
assert(math.abs(row.hover.width - row:GetWidth() / scale) < 1e-9, "row art fills the row before it is scaled")
assert(
	row.hover.layer == "HIGHLIGHT" and row.hover.blend == "ADD",
	"row hover is a highlight texture added like the Who list"
)
assert(row.highlightTexture == row.hover and row.highlightBlend == "ADD", "row hover is the button's highlight texture")
assert(not row.selected.shown, "row selected art starts hidden")
row.height = 46
for _, hook in ipairs(row.hooks.OnSizeChanged) do
	hook(row)
end
assert(
	math.abs(row.hover:GetScale() - 46 / 69) < 1e-9 and row.hover.height == 69,
	"row art is re-laid on OnSizeChanged"
)
row.height = 30
for _, hook in ipairs(row.hooks.OnSizeChanged) do
	hook(row)
end
window.search:SetText("Cached item 30")
window.search.hooks.OnTextChanged[1]()
assert(Visible() == 1 and window.rows[1].name.text == "Cached item 30", "search filters without losing the final row")
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
window.Refresh()
assert(window.rows[1].name.text == "Cached item 1", "cached names replace the item-ID fallback")
print("Commissions Forever window specs passed")
