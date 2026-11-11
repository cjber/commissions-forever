-- Run from the repository root: luajit tests/gamepad_window_spec.lua
-- The ledger sits above the native page and never shows or hides a Blizzard page itself. Under the gamepad interface
-- those calls rebuild the frame manager's focus and the footer's binding group under our taint, and the next secure
-- window call has its protected SetPreferredGamepadInteractTarget refused (cjber/commissions-forever#147). The player
-- opens the window with their own profession control; closing goes through the client's own trade-skill call, which
-- owns that bookkeeping.
local Toc = dofile("tests/toc.lua")
Toc.install(_G, "CommissionsForever")
local nativeSelections = 0
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
				SetScale = function(self, scale)
					self.scale = scale
				end,
				GetScale = function(self)
					return self.scale or 1
				end,
				SetFrameLevel = function(self, level)
					self.level = level
				end,
				GetFrameLevel = function(self)
					return rawget(self, "level") or 0
				end,
				GetHighestFrameLevel = function(self)
					return rawget(self, "level") or 0
				end,
				SetBlendMode = function(self, blend)
					self.blend = blend
				end,
				SetAtlas = function(self, atlas)
					self.atlas = atlas
				end,
				SetAllPoints = function(self, frame)
					self.allPoints = frame
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
_G.CreateFrame = function()
	local frame = Region()
	frame.Icon = Region()
	frame.Text = Region()
	return frame
end
local host = Region()
_G.ProfessionsFrame = host
host.CraftingPage = Region()
host.BookPage = Region()
-- A native Professions tab: a Frame whose mouse-up handler and gamepad press both run its mixin OnClick.
local function NativeTab()
	local nativeTab = Region()
	nativeTab.OnClick = function(self)
		host:RightTabSelected(self)
	end
	nativeTab:SetCustomOnMouseUpHandler(function(self, button, upInside)
		if button == "LeftButton" and upInside then
			self:OnClick()
		end
	end)
	return nativeTab
end
host.ProfessionsOverviewTab = NativeTab()
local professionTab = NativeTab()
host.rightProfessionTabs = { professionTab }
host.RightTabSelected = function()
	nativeSelections = nativeSelections + 1
end
local hidden, bookPage = 0, 0
host.SelectBookPage = function()
	bookPage = bookPage + 1
	host.BookPage:Show()
end
local nativeShows, nativeHides = 0, 0
for _, nativePage in ipairs({ host.CraftingPage, host.BookPage }) do
	local show, hide = nativePage.Show, nativePage.Hide
	nativePage.Show = function(self)
		nativeShows = nativeShows + 1
		return show(self)
	end
	nativePage.Hide = function(self)
		nativeHides = nativeHides + 1
		return hide(self)
	end
end
local panelCalls = 0
_G.ShowProfessionsFrame = function()
	panelCalls = panelCalls + 1
	host:Show()
end
_G.HideUIPanel = function(frame)
	panelCalls = panelCalls + 1
	frame:Hide()
end
_G.C_TradeSkillUI = {
	-- The client refuses this from addon code (AllowedWhenUntainted); this spec fails if the addon calls it.
	OpenTradeSkill = function()
		error("C_TradeSkillUI.OpenTradeSkill is blocked from addon code")
	end,
	CloseTradeSkill = function()
		hidden = hidden + 1
		host:Hide()
	end,
}
_G.GetProfessions = function()
	return 1
end
_G.GameTooltip = Region()
_G.InCombatLockdown = function()
	return false
end
_G.NORMAL_FONT_COLOR = {
	GetRGB = function()
		return 1, 0.82, 0
	end,
}
local messages = {}
_G.UIErrorsFrame = {
	AddMessage = function(_, text)
		messages[#messages + 1] = text
	end,
}
_G.DEFAULT_CHAT_FRAME = {
	AddMessage = function() end,
}
_G.C_Item = {
	RequestLoadItemDataByID = function() end,
	GetItemNameByID = function(id)
		return "Item " .. id
	end,
	GetItemIconByID = function(id)
		return id
	end,
}
local gamepad = false
_G.InputUtil = {
	IsGamepadUIEnabled = function()
		return gamepad
	end,
}
local ns = {
	-- Core/Core.lua reads this from the TOC before UI/Window.lua loads.
	ICON = Toc.get("CommissionsForever", "X-Forever-Icon"),
	Questie = {
		Available = function()
			return true
		end,
	},
	Rows = {},
	core = {
		SafeCall = function(_, fn, ...)
			return fn(...)
		end,
	},
}
-- ForeverCore.ProfessionTabs, with the same one-page and native hand-back contract its real module publishes.
local registered = {}
local order = {}
local selectedKey
local installed = false
local ProfessionTabs = {}
local function ApplyPages()
	local selected = selectedKey and registered[selectedKey]
	for _, entry in ipairs(order) do
		entry.spec.page:SetShown(entry == selected)
		entry.tab:SetChecked(entry == selected)
	end
end
function ProfessionTabs.Register(key, spec)
	assert(type(key) == "string" and key ~= "", "the key is not a non-empty string")
	assert(not registered[key], "the key is already registered: " .. tostring(key))
	if not installed then
		installed = true
		for _, nativePage in ipairs({ host.CraftingPage, host.BookPage }) do
			nativePage:HookScript("OnShow", function()
				ProfessionTabs.ShowNative()
			end)
		end
		local nativeTabs = { host.ProfessionsOverviewTab }
		for _, nativeTab in ipairs(host.rightProfessionTabs or {}) do
			nativeTabs[#nativeTabs + 1] = nativeTab
		end
		for _, nativeTab in ipairs(nativeTabs) do
			nativeTab:HookScript("OnMouseUp", function()
				ProfessionTabs.ShowNative()
			end)
		end
	end
	local tab = CreateFrame("Frame", nil, host, "LargeSideTabButtonTemplate")
	tab.Icon:SetTexture(spec.icon)
	tab.tooltipText = spec.tooltip
	tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
		if button == "LeftButton" and upInside then
			ProfessionTabs.Select(key)
		end
	end)
	tab:SetChecked(false)
	local entry = { key = key, spec = spec, tab = tab }
	registered[key] = entry
	order[#order + 1] = entry
	return tab
end
function ProfessionTabs.Select(key)
	local entry = registered[key]
	if not entry then
		return
	end
	selectedKey = key
	ApplyPages()
	host.ProfessionsOverviewTab:SetChecked(false)
	for _, nativeTab in ipairs(host.rightProfessionTabs or {}) do
		nativeTab:SetChecked(false)
	end
	local spec = entry.spec
	if spec.onSelect then
		if spec.safeCall then
			spec.safeCall("profession tab selected", spec.onSelect, key)
		else
			spec.onSelect(key)
		end
	end
end
function ProfessionTabs.ShowNative()
	selectedKey = nil
	ApplyPages()
end
function ProfessionTabs.Selected()
	return selectedKey
end
ProfessionTabs.registered = registered
_G.ForeverCore = { ProfessionTabs = ProfessionTabs }
assert(loadfile("Locales/enUS.lua"))("CommissionsForever", ns)
assert(loadfile("UI/RowArt.lua"))("CommissionsForever", ns)
local window = assert(loadfile("UI/Window.lua"))("CommissionsForever", ns)

-- The command cannot open the client's window from addon code; the player's own profession control does, and the
-- page appears with it without writing Blizzard's panel or page state.
window.Toggle()
assert(not host.shown and not window.page.shown, "the command opened the Professions window itself")
assert(
	messages[1] == ns.L["Commissions opens in the Professions window. Open it from your spellbook."],
	"the command did not say how to open the window"
)
host:Show()
assert(window.page.shown and window.tab.checked, "the page did not appear with the player's profession window")
assert(panelCalls == 0 and bookPage == 0, "opening wrote Blizzard's panel or page state")
window.Toggle()
assert(hidden == 1 and not host.shown and not window.page.shown, "the mouse closes the ledger")
assert(panelCalls == 0 and bookPage == 0, "closing wrote Blizzard's panel or page state")

-- The same on the gamepad interface: selecting the page and closing touch no native page.
gamepad = true
window.Toggle()
assert(not host.shown, "the gamepad command opened the Professions window itself")
host:Show()
-- The client shows the profession's native page with the window, after the window's own OnShow.
host.CraftingPage:Show()
nativeShows, nativeHides = 0, 0
assert(window.page.shown and window.tab.checked, "/commissions did not show the ledger under the gamepad interface")
assert(nativeShows == 0 and nativeHides == 0, "opening changed a native page under the gamepad interface")
assert(bookPage == 0, "opening changed the remembered profession under the gamepad interface")

window.tab.click(nil, "LeftButton", true)
assert(window.page.shown and window.tab.checked, "the Commissions tab did not open")
assert(nativeShows == 0 and nativeHides == 0, "the Commissions tab changed a native page under the gamepad interface")

-- The client shows another native page (the one on screen must change for OnShow to run).
host.CraftingPage:Hide()
host.CraftingPage:Show()
assert(not window.page.shown and not window.tab.checked, "a native page did not take the window back")
nativeShows, nativeHides = 0, 0
window.tab.click(nil, "LeftButton", true)
assert(window.page.shown, "the Commissions tab did not reopen")

-- A native tab's mouse-up (and the gamepad press that sends the same pair) runs its mixin and then the shared
-- owner's mouse-up hook, which hands the window back.
local function NativeMouseUp(tab)
	tab.click(tab, "LeftButton", true)
	for _, hook in ipairs(tab.hooks.OnMouseUp or {}) do
		hook(tab, "LeftButton", true)
	end
end
NativeMouseUp(host.ProfessionsOverviewTab)
assert(not window.page.shown and not window.tab.checked, "the overview tab's mouse-up did not hand the window back")
window.tab.click(nil, "LeftButton", true)
NativeMouseUp(professionTab)
assert(not window.page.shown and not window.tab.checked, "a profession tab's gamepad press did not hand it back")
assert(nativeSelections == 2, "a native tab's own click did not run for both native tabs")
-- The client refreshes the tabs on SKILL_LINES_CHANGED and selects a native tab itself; that leaves our page.
window.tab.click(nil, "LeftButton", true)
host:RightTabSelected(professionTab)
assert(window.page.shown and window.tab.checked, "a tab refresh deselected the Commissions page")
nativeShows, nativeHides = 0, 0
window.tab.click(nil, "LeftButton", true)
assert(window.page.shown, "the Commissions tab did not reopen after the tab hand-backs")

window.Toggle()
assert(
	hidden == 2 and not host.shown and not window.page.shown,
	"/commissions did not close the ledger under the gamepad interface"
)
assert(nativeShows == 0 and nativeHides == 0, "closing changed a native page under the gamepad interface")
assert(bookPage == 0, "closing changed the remembered profession under the gamepad interface")

print("Commissions Forever gamepad window spec passed")
