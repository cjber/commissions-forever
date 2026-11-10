-- Native Professions page, real event ordering and a long materials list.
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
				SetFrameLevel = function(self, level)
					self.level = level
				end,
				GetFrameLevel = function(self)
					return rawget(self, "level") or 0
				end,
				SetFrameStrata = function(self, strata)
					self.strata = strata
				end,
				GetFrameStrata = function(self)
					return rawget(self, "strata") or "MEDIUM"
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
-- A native Professions tab: a Frame whose mouse-up handler and gamepad press both run its mixin OnClick.
local function NativeTab()
	local nativeTab = Region()
	nativeTab.OnClick = function(self)
		ProfessionsFrame:RightTabSelected(self)
	end
	nativeTab:SetCustomOnMouseUpHandler(function(self, button, upInside)
		if button == "LeftButton" and upInside then
			self:OnClick()
		end
	end)
	return nativeTab
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
host.ProfessionsOverviewTab = NativeTab()
host.rightProfessionTabs = {}
host.RightTabSelected = function() end
-- The book page declares its profession rank bar at HIGH while the pages are MEDIUM. A deeper HIGH frame and a
-- much higher MEDIUM frame prove the page covers the highest strata, not the highest level anywhere.
local highStatusBar = Region()
highStatusBar:SetFrameStrata("HIGH")
highStatusBar.level = 7
host.BookPage.children[#host.BookPage.children + 1] = highStatusBar
local deepHigh = Region()
deepHigh:SetFrameStrata("HIGH")
deepHigh.level = 4
highStatusBar.children[#highStatusBar.children + 1] = deepHigh
local mediumDeep = Region()
mediumDeep.level = 100
host.BookPage.children[#host.BookPage.children + 1] = mediumDeep
-- A hidden DIALOG frame draws nothing, so it must not lift the page level with the game's popups.
local hiddenDialog = Region()
hiddenDialog:SetFrameStrata("DIALOG")
hiddenDialog.level = 50
host.BookPage.children[#host.BookPage.children + 1] = hiddenDialog
-- The book page is open beneath, as in the game, with its bars shown.
host.BookPage.shown = true
highStatusBar.shown, deepHigh.shown, mediumDeep.shown = true, true, true
local shown, hidden = 0, 0
local baseProfession = { professionID = 164 }
_G.C_TradeSkillUI = {
	GetBaseProfessionInfo = function()
		return baseProfession
	end,
	OpenTradeSkill = function()
		shown = shown + 1
		ProfessionsFrame:Show()
	end,
	CloseTradeSkill = function()
		hidden = hidden + 1
		ProfessionsFrame:Hide()
	end,
}
_G.GameTooltip = Region()
local inCombat = false
_G.InCombatLockdown = function()
	return inCombat
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
local chat = {}
_G.DEFAULT_CHAT_FRAME = {
	AddMessage = function(_, text)
		chat[#chat + 1] = text
	end,
}
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
local opened = false
local ns = {
	Stats = {
		Participating = function()
			return true
		end,
		Open = function()
			opened = true
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
assert(
	window.page.strata == "HIGH" and window.page.level == 8,
	"the Commissions page did not cover the native page's HIGH strata: "
		.. tostring(window.page.strata)
		.. " "
		.. tostring(window.page.level)
)
-- The native pages build and re-level frames after attach; showing the page again picks up the new HIGH level.
local lateStatusBar = Region()
lateStatusBar:SetFrameStrata("HIGH")
lateStatusBar.level = 20
lateStatusBar.shown = true
host.BookPage.children[#host.BookPage.children + 1] = lateStatusBar
window.page:Hide()
window.page:Show()
assert(
	window.page.strata == "HIGH" and window.page.level == 21,
	"a HIGH frame created after attach stayed above the Commissions page"
)
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
window.tab.click(nil, "LeftButton", true)
assert(window.page.shown, "the tab opens the ledger above the native page")
-- A native tab's mouse-up runs its mixin OnClick, and a gamepad press runs it with no mouse-up.
host.ProfessionsOverviewTab.click(host.ProfessionsOverviewTab, "LeftButton", true)
assert(not window.page.shown and not window.tab.checked, "a native tab mouse-up deselects commissions")
window.tab.click(nil, "LeftButton", true)
host.ProfessionsOverviewTab:OnClick()
assert(not window.page.shown and not window.tab.checked, "a gamepad press on a native tab deselects commissions")
-- The client refreshes the tabs on SKILL_LINES_CHANGED and selects a native tab itself; that leaves our page.
window.tab.click(nil, "LeftButton", true)
host:RightTabSelected(host.ProfessionsOverviewTab)
assert(window.page.shown and window.tab.checked, "a tab refresh deselected the Commissions page")
otherPage:Hide()
window.Toggle()
assert(not ProfessionsFrame.shown and not window.page.shown, "toggle closes the native host cleanly")
cached = false
window.Refresh()
assert(requested[1] and window.rows[1].name.text == "Item 1", "uncached items request data and keep a usable fallback")
cached = true
window.Refresh()
assert(window.rows[1].name.text == "Cached item 1", "cached names replace the item-ID fallback")
window.leaderboard.scripts.OnClick()
assert(opened, "the Leaderboard button opens the shared window on this addon's tab")
assert(window.share.Text.text == "Share my progress", "the share switch names the opt-out setting")

local function Fire(event)
	for _, frame in ipairs(frames) do
		if frame.scripts.OnEvent then
			frame.scripts.OnEvent(frame, event)
		end
	end
end

-- In combat the panel manager refuses panel changes, so the toggle waits and tells the player on screen only.
assert(not ProfessionsFrame.shown, "the window is closed before the combat toggle")
shown, hidden = 0, 0
local printed = 0
local realPrint = print
rawset(_G, "print", function()
	printed = printed + 1
end)
inCombat = true
local before = #messages
window.Toggle()
assert(shown == 0 and hidden == 0, "a combat toggle called a panel API or touched the Professions frame")
assert(not ProfessionsFrame.shown and not window.page.shown, "a combat toggle opened the window")
assert(#messages == before + 1, "a combat toggle did not add exactly one UIErrorsFrame message")
assert(messages[#messages] == ns.L["Commissions opens when combat ends."], "the on-screen message is not the phrase")
assert(#chat == 0, "a combat toggle wrote to chat")
assert(printed == 0, "a combat toggle printed to chat")

-- Leaving combat opens the one pending window, and the event cannot open it again.
inCombat = false
Fire("PLAYER_REGEN_ENABLED")
assert(shown == 1, "the pending open did not run once when combat ended")
assert(ProfessionsFrame.shown and window.page.shown and window.tab.checked, "the pending open left the ledger closed")
Fire("PLAYER_REGEN_ENABLED")
assert(shown == 1, "the pending open ran again after it was consumed")
rawset(_G, "print", realPrint)

-- Two toggles in combat share one pending open, which runs once.
window.Toggle()
assert(hidden == 1 and not ProfessionsFrame.shown, "an out-of-combat toggle no longer closes the window")
inCombat = true
window.Toggle()
window.Toggle()
assert(shown == 1 and hidden == 1, "combat toggles called a panel API")
inCombat = false
Fire("PLAYER_REGEN_ENABLED")
assert(shown == 2, "two combat toggles did not open the window exactly once")
assert(window.page.shown and window.tab.checked, "the pending open did not select the Commissions page")
window.Toggle()
assert(hidden == 2 and not ProfessionsFrame.shown, "an out-of-combat toggle no longer closes the window")

-- With no remembered profession, the character's first profession opens the client's own way.
shown, hidden = 0, 0
baseProfession = nil
_G.GetProfessions = function()
	return 1
end
_G.GetProfessionInfo = function()
	return "Blacksmithing", nil, 1, 1, 0, 0, 164
end
window.Toggle()
assert(
	shown == 1 and ProfessionsFrame.shown and window.page.shown,
	"the character's profession did not open the ledger"
)
window.Toggle()
assert(hidden == 1 and not ProfessionsFrame.shown and not window.page.shown, "the fallback profession did not close")

-- With no profession at all, nothing opens and the player is told on screen, never in chat.
shown, hidden = 0, 0
_G.GetProfessions = function()
	return nil
end
local beforeNoProfession = #messages
local chatBefore = #chat
window.Toggle()
assert(shown == 0 and hidden == 0, "a character with no profession called a trade-skill function")
assert(not ProfessionsFrame.shown and not window.page.shown, "a character with no profession opened the window")
assert(#messages == beforeNoProfession + 1, "no profession did not add exactly one UIErrorsFrame message")
assert(
	messages[#messages] == ns.L["Commissions opens in the Professions window. Learn a profession to use it."],
	"the no-profession message is not the phrase"
)
assert(#chat == chatBefore, "the no-profession message went to chat")

print("Commissions Forever window specs passed")
