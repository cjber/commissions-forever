-- Run from the repository root: luajit tests/gamepad_window_spec.lua
-- The ledger sits above the native page and never shows or hides a Blizzard page itself. Under the gamepad interface
-- those calls rebuild the frame manager's focus and the footer's binding group under our taint, and the next secure
-- window call has its protected SetPreferredGamepadInteractTarget refused (cjber/commissions-forever#147). Opening and
-- closing go through the client's own trade-skill call, which owns that bookkeeping.
local nativeSelections = 0
_G.hooksecurefunc = function(t, name, post)
	local original = t[name]
	t[name] = function(...)
		local result = { original(...) }
		post(...)
		return unpack(result)
	end
end
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
local shown, hidden, bookPage = 0, 0, 0
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
	GetBaseProfessionInfo = function()
		return { professionID = 164 }
	end,
	OpenTradeSkill = function()
		shown = shown + 1
		host:Show()
	end,
	CloseTradeSkill = function()
		hidden = hidden + 1
		host:Hide()
	end,
}
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
	Stats = {
		Participating = function()
			return true
		end,
		Open = function() end,
	},
	Questie = {
		Available = function()
			return true
		end,
	},
	Rows = {},
}
assert(loadfile("Locales/enUS.lua"))("CommissionsForever", ns)
assert(loadfile("UI/Art.lua"))("CommissionsForever", ns)
local window = assert(loadfile("UI/Window.lua"))("CommissionsForever", ns)

-- Mouse and keyboard open and close through the client's own trade-skill call, never the panel manager.
window.Toggle()
assert(shown == 1 and host.shown and window.page.shown and window.tab.checked, "the mouse opens the ledger")
assert(panelCalls == 0 and bookPage == 0, "opening wrote Blizzard's panel or page state")
window.Toggle()
assert(hidden == 1 and not host.shown and not window.page.shown, "the mouse closes the ledger")
assert(panelCalls == 0 and bookPage == 0, "closing wrote Blizzard's panel or page state")

-- The same on the gamepad interface: opening, selecting the tab and closing touch no native page.
gamepad = true
window.Toggle()
assert(shown == 2 and host.shown and window.page.shown, "/cf did not open the ledger under the gamepad interface")
assert(nativeShows == 0 and nativeHides == 0, "opening changed a native page under the gamepad interface")
assert(bookPage == 0, "opening changed the remembered profession under the gamepad interface")

window.tab.click(nil, "LeftButton", true)
assert(window.page.shown and window.tab.checked, "the Commissions tab did not open")
assert(nativeShows == 0 and nativeHides == 0, "the Commissions tab changed a native page under the gamepad interface")

host.CraftingPage:Show()
assert(not window.page.shown and not window.tab.checked, "a native page did not take the window back")
nativeShows, nativeHides = 0, 0
window.tab.click(nil, "LeftButton", true)
assert(window.page.shown, "the Commissions tab did not reopen")

-- A native tab's mouse-up runs its mixin OnClick, and a gamepad press runs it with no mouse-up.
host.ProfessionsOverviewTab.click(host.ProfessionsOverviewTab, "LeftButton", true)
assert(not window.page.shown and not window.tab.checked, "the overview tab's mouse-up did not hand the window back")
window.tab.click(nil, "LeftButton", true)
professionTab:OnClick()
assert(not window.page.shown and not window.tab.checked, "a profession tab's gamepad press did not hand it back")
assert(nativeSelections == 2, "the OnClick hooks did not run for both native tabs")
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
	"/cf did not close the ledger under the gamepad interface"
)
assert(nativeShows == 0 and nativeHides == 0, "closing changed a native page under the gamepad interface")
assert(bookPage == 0, "closing changed the remembered profession under the gamepad interface")

print("Commissions Forever gamepad window spec passed")
