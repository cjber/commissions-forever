local _, ns = ...
local L = ns.L
local Window = {}
ns.Window = Window

local ROW_HEIGHT = 30
local page, tab
local requestedItems = {}

local function IsTrackedItem(itemID)
	for _, row in ipairs(ns.Rows or {}) do
		if row.itemID == itemID then
			return true
		end
	end
	return false
end

local function Deselect()
	if page then
		page:Hide()
		tab:SetChecked(false)
	end
end

local function PlaceTab()
	local last = ProfessionsFrame.ProfessionsOverviewTab
	for _, candidate in ipairs(ProfessionsFrame.rightProfessionTabs or {}) do
		if candidate:IsShown() then
			last = candidate
		end
	end
	-- Other addons can add tabs outside Blizzard's array. Walk every occupied slot, not just the first.
	local seen = {}
	while last and not seen[last] do
		seen[last] = true
		local occupied
		local left, bottom = last:GetLeft(), last:GetBottom()
		if type(left) == "number" and type(bottom) == "number" then
			for _, child in ipairs({ ProfessionsFrame:GetChildren() }) do
				if child ~= tab and child:IsShown() then
					local childLeft, top = child:GetLeft(), child:GetTop()
					if type(childLeft) == "number" and type(top) == "number" then
						if math.abs(childLeft - left) < 1 and math.abs(top - (bottom - 2)) < 1 then
							occupied = child
							break
						end
					end
				end
			end
		end
		if not occupied then
			break
		end
		last = occupied
	end
	tab:ClearAllPoints()
	tab:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -2)
end

local function SelectPage()
	-- Hand the host back to its native page first, so another addon's page can deselect itself.
	ProfessionsFrame.CraftingPage:Show()
	ProfessionsFrame.CraftingPage:Hide()
	ProfessionsFrame.BookPage:Hide()
	page:Show()
	tab:SetChecked(true)
	ProfessionsFrame.ProfessionsOverviewTab:SetChecked(false)
	for _, nativeTab in ipairs(ProfessionsFrame.rightProfessionTabs or {}) do
		nativeTab:SetChecked(false)
	end
	-- RightTabSelected expects a native gamepad tab ID. Our extra tab is not part of that array.
	Window.Refresh()
end

local function Text(parent, font, x, y, width)
	local text = parent:CreateFontString(nil, "OVERLAY", font)
	text:SetPoint("TOPLEFT", x, y)
	text:SetWidth(width)
	text:SetJustifyH("LEFT")
	text:SetWordWrap(false)
	return text
end

local function Row(index)
	local row = Window.rows[index]
	if not row then
		row = CreateFrame("Button", nil, Window.list)
		row:SetPoint("TOPLEFT", 4, -(index - 1) * ROW_HEIGHT)
		row:SetPoint("TOPRIGHT", -4, -(index - 1) * ROW_HEIGHT)
		row:SetHeight(ROW_HEIGHT)
		row.background = ns.Art.RowAtlas(row, "common-button-list-large", "BACKGROUND")
		row.selected = ns.Art.RowAtlas(row, "common-button-list-large-selected", "BACKGROUND")
		row.selected:Hide()
		row.hover = ns.Art.RowAtlas(row, "common-button-list-large-hover", "HIGHLIGHT", "ADD")
		row:SetHighlightTexture(row.hover, "ADD")
		row.icon = row:CreateTexture(nil, "ARTWORK")
		row.icon:SetSize(24, 24)
		row.icon:SetPoint("LEFT", 4, 0)
		row.name = Text(row, "GameFontHighlight", 36, -8, 218)
		row.source = Text(row, "GameFontHighlightSmall", 260, -9, 170)
		row.count = Text(row, "GameFontHighlight", 440, -8, 64)
		row.need = Text(row, "GameFontHighlight", 510, -8, 64)
		row:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetItemByID(self.itemID)
			GameTooltip:Show()
		end)
		row:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
		Window.rows[index] = row
	end
	return row
end

function Window.Refresh()
	if not page then
		return
	end
	local rows = ns.Rows or {}
	local query = (Window.search:GetText() or ""):lower()
	local shown = 0
	for _, row in ipairs(Window.rows) do
		row:Hide()
	end
	for _, item in ipairs(rows) do
		local name = C_Item.GetItemNameByID(item.itemID)
		if not name and not requestedItems[item.itemID] then
			requestedItems[item.itemID] = true
			C_Item.RequestLoadItemDataByID(item.itemID)
		end
		name = name or L["Item %d"]:format(item.itemID)
		local source = item.turnIn.faction
		if query == "" or name:lower():find(query, 1, true) or source:lower():find(query, 1, true) then
			shown = shown + 1
			local row = Row(shown)
			row.itemID = item.itemID
			row.icon:SetTexture(C_Item.GetItemIconByID(item.itemID))
			row.name:SetText(name)
			row.source:SetText(source)
			row.count:SetText(item.count)
			row.need:SetText(item.need and tostring(item.need) or "-")
			row:Show()
		end
	end
	Window.list:SetHeight(math.max(1, shown * ROW_HEIGHT))
	Window.empty:SetShown(shown == 0)
	Window.notice:SetShown(not ns.Questie.Available())
	Window.share:SetChecked(ns.Stats.Participating())
end

local function Attach()
	if page or not ProfessionsFrame then
		return
	end
	page = CreateFrame("Frame", nil, ProfessionsFrame)
	page:SetPoint("TOPLEFT", 4, -28)
	page:SetPoint("BOTTOMRIGHT", -4, 4)
	page:Hide()
	Window.page = page
	Text(page, "GameFontNormalLarge", 74, -12, 350):SetText(L["Commissions Forever"])
	Window.leaderboard = CreateFrame("Button", nil, page, "SharedButtonSmallTemplate")
	Window.leaderboard:SetSize(132, 24)
	Window.leaderboard:SetPoint("TOPRIGHT", -14, -8)
	Window.leaderboard:SetText(L["Leaderboard"])
	Window.leaderboard:SetScript("OnClick", function()
		ns.Stats.Print()
	end)
	Window.share = CreateFrame("CheckButton", nil, page, "CheckboxWithLabelTemplate")
	Window.share:SetSize(26, 26)
	Window.share:SetPoint("BOTTOMLEFT", 14, 9)
	Window.share.Text:SetText(L["Share totals with guild and group"])
	Window.share.Text:SetWidth(300)
	Window.share.Text:SetJustifyH("LEFT")
	Window.share:SetScript("OnClick", function(self)
		ns.Stats.SetEnabled(self:GetChecked() == true)
	end)
	Window.share:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(L["Share totals with guild and group"])
		GameTooltip:AddLine(
			L["Stop sending and receiving totals. Keep your history. Already shared totals cannot be recalled."],
			nil,
			nil,
			nil,
			true
		)
		GameTooltip:Show()
	end)
	Window.share:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	Window.search = CreateFrame("EditBox", nil, page, "SearchBoxTemplate")
	Window.search:SetSize(250, 20)
	Window.search:SetPoint("TOPLEFT", 22, -48)
	Window.search:SetAutoFocus(false)
	Window.search:HookScript("OnTextChanged", Window.Refresh)
	Window.notice = Text(page, "GameFontDisableSmall", 288, -52, 350)
	Window.notice:SetText(L["Install QuestieDB to see your active turn-ins."])
	local inset = CreateFrame("Frame", nil, page)
	inset:SetPoint("TOPLEFT", 14, -78)
	inset:SetPoint("BOTTOMRIGHT", -14, 44)
	Window.inset = inset
	local background = inset:CreateTexture(nil, "BACKGROUND")
	inset.background = background
	background:SetPoint("TOPLEFT", 2, -2)
	background:SetPoint("BOTTOMRIGHT", -2, 2)
	-- art-ok: common-insideframe is a nine-slice, so the client keeps its 53px corners (WhoList.xml:86).
	background:SetAtlas("common-insideframe")
	for _, column in ipairs({
		{ "Material", 40, 218 },
		{ "Turn-in", 264, 170 },
		{ "Have", 444, 64 },
		{ "Need", 514, 64 },
	}) do
		Text(inset, "GameFontNormalSmall", column[2], -10, column[3]):SetText(L[column[1]])
	end
	Window.scroll = CreateFrame("ScrollFrame", nil, inset, "UIPanelScrollFrameTemplate")
	Window.scroll.scrollBarHideable = true
	Window.scroll:SetPoint("TOPLEFT", 4, -32)
	Window.scroll:SetPoint("BOTTOMRIGHT", -30, 4)
	Window.list = CreateFrame("Frame", nil, Window.scroll)
	Window.list:SetSize(584, 1)
	Window.scroll:SetScrollChild(Window.list)
	Window.rows = {}
	Window.empty = Text(inset, "GameFontDisableSmall", 12, -42, 560)
	Window.empty:SetText(L["No tracked materials found"])
	local route = CreateFrame("Button", nil, page, "SharedButtonSmallTemplate")
	route:SetSize(190, 24)
	route:SetPoint("BOTTOMRIGHT", -14, 10)
	route:SetText(L["Open turn-in route"])
	route:SetScript("OnClick", function()
		if not ns.NavigateActiveAssignments() then
			DEFAULT_CHAT_FRAME:AddMessage(L["No active commission route is available."])
		end
	end)
	tab = CreateFrame("Frame", nil, ProfessionsFrame, "LargeSideTabButtonTemplate")
	tab.Icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
	tab:SetFillToInterior(true)
	tab.tooltipText = L["Commissions Forever"]
	tab:EnableMouse(true)
	tab:SetCustomOnMouseUpHandler(function(_, button, upInside)
		if button == "LeftButton" and upInside then
			SelectPage()
		end
	end)
	Window.tab = tab
	PlaceTab()
	ProfessionsFrame:HookScript("OnShow", PlaceTab)
	ProfessionsFrame.CraftingPage:HookScript("OnShow", Deselect)
	ProfessionsFrame.BookPage:HookScript("OnShow", Deselect)
	ProfessionsFrame:HookScript("OnHide", function()
		if page and page:IsShown() then
			Deselect()
			ProfessionsFrame:SelectBookPage()
		end
	end)
	Window.Refresh()
end

function Window.Toggle()
	if page and page:IsShown() and ProfessionsFrame:IsShown() then
		HideUIPanel(ProfessionsFrame)
		return
	end
	-- Clear the host's remembered profession through its native API before OnShow can recast it.
	if ProfessionsFrame then
		ProfessionsFrame:SelectBookPage()
	end
	ShowProfessionsFrame()
	Attach()
	if page then
		SelectPage()
	end
end

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("GET_ITEM_INFO_RECEIVED")
events:RegisterEvent("SKILL_LINES_CHANGED")
events:SetScript("OnEvent", function(_, event, name)
	if event == "ADDON_LOADED" and name == "Blizzard_Professions" then
		Attach()
	elseif event == "GET_ITEM_INFO_RECEIVED" and (requestedItems[name] or IsTrackedItem(name)) then
		ns.Refresh()
	elseif event == "SKILL_LINES_CHANGED" and page then
		PlaceTab()
	end
end)
Attach()
return Window
