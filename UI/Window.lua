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

frame.rows = {}
for index = 1, 12 do
	local row = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	row:SetPoint("TOPLEFT", 18, -78 - (index - 1) * 22)
	row:SetWidth(372)
	row:SetJustifyH("LEFT")
	frame.rows[index] = row
end

function frame:Refresh()
	local rows = ns.Rows or {}
	for index, fontString in ipairs(self.rows) do
		local row = rows[index]
		if row then
			local itemName = C_Item.GetItemNameByID(row.itemID) or ("item " .. row.itemID)
			local quantity = row.need
					and ("  " .. L["Have %d"]:format(row.count) .. " / " .. L["Need %d"]:format(row.need))
				or (" × " .. row.count)
			fontString:SetText(row.turnIn.faction .. " · " .. itemName .. quantity)
		else
			fontString:SetText(index == 1 and #rows == 0 and L["No tracked materials found"] or "")
		end
	end
end

ns.Window = frame
return frame
