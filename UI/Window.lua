local _, ns = ...
local L = ns.L

local frame = CreateFrame("Frame", "CommissionsForeverWindow", UIParent, "PortraitFrameTemplate")
frame:SetSize(460, 390)
frame:SetPoint("CENTER")
frame:SetClampedToScreen(true)
frame:Hide()
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

frame.TitleText:SetText(L["Commissions Forever"])
table.insert(UISpecialFrames, "CommissionsForeverWindow")

local route = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
route:SetSize(160, 24)
route:SetPoint("BOTTOM", 0, 20)
route:SetText(L["Open turn-in route"])
route:SetScript("OnClick", function()
	if not ns.NavigateActiveAssignments() then
		DEFAULT_CHAT_FRAME:AddMessage(L["No active commission route is available."])
	end
end)

-- One line under the title when QuestieDB is missing: bag counts still show, active turn-ins cannot.
frame.notice = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
frame.notice:SetPoint("TOPLEFT", 18, -58)
frame.notice:SetText(L["Install QuestieDB to see your active turn-ins."])
frame.notice:Hide()

-- Rows live in a scroll child, so a list longer than the window scrolls instead of dropping its last rows.
local ROW_HEIGHT = 22
local LIST_WIDTH = 400
frame.scroll = CreateFrame("ScrollFrame", "CommissionsForeverScroll", frame, "UIPanelScrollFrameTemplate")
frame.scroll.scrollBarHideable = true
frame.scroll:SetPoint("TOPLEFT", 18, -78)
frame.scroll:SetPoint("BOTTOMRIGHT", -42, 52)
frame.list = CreateFrame("Frame", nil, frame.scroll)
frame.list:SetSize(LIST_WIDTH, ROW_HEIGHT)
frame.scroll:SetScrollChild(frame.list)
frame.rows = {}

---@param index integer
---@return FontString
local function Row(index)
	local row = frame.rows[index]
	if not row then
		row = frame.list:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
		row:SetPoint("TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
		row:SetWidth(LIST_WIDTH)
		row:SetJustifyH("LEFT")
		frame.rows[index] = row
	end
	return row
end

function frame:Refresh()
	local rows = ns.Rows or {}
	self.notice:SetShown(not ns.Questie.Available())
	for _, fontString in ipairs(self.rows) do
		fontString:SetText("")
	end
	self.list:SetHeight(math.max(1, #rows) * ROW_HEIGHT)
	if #rows == 0 then
		Row(1):SetText(L["No tracked materials found"])
	end
	for index, row in ipairs(rows) do
		local itemName = C_Item.GetItemNameByID(row.itemID) or ("item " .. row.itemID)
		local quantity = row.need and ("  " .. L["Have %d"]:format(row.count) .. " / " .. L["Need %d"]:format(row.need))
			or (" × " .. row.count)
		Row(index):SetText(row.turnIn.faction .. " · " .. itemName .. quantity)
	end
end

ns.Window = frame
return frame
