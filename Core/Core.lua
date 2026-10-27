local addonName, ns = ...

local addon = CreateFrame("Frame")
ns.Addon = addon

local function ItemCount(itemID)
	if C_Item and type(C_Item.GetItemCount) == "function" then
		return C_Item.GetItemCount(itemID) or 0
	end
	return GetItemCount(itemID) or 0
end

function ns.Refresh()
	ns.ActiveObjectives = ns.Questie.ActiveObjectives()
	ns.Rows = ns.Model.Inventory(ItemCount)
	if ns.Window and ns.Window.Refresh then
		ns.Window:Refresh()
	end
end

function ns.Toggle()
	if ns.Window then
		ns.Window:SetShown(not ns.Window:IsShown())
	end
end

function ns.NavigateActiveAssignments()
	local stops, seen = {}, {}
	for _, row in ipairs(ns.ActiveObjectives or {}) do
		if not row.finished and ns.Model.IsCommissionQuest(row.questName) then
			for _, npcID in ipairs(row.npcIDs or {}) do
				if not seen[npcID] then
					local npc = ns.Questie.NPC(npcID)
					if npc and npc.map and npc.x and npc.y then
						seen[npcID] = true
						stops[#stops + 1] = { map = npc.map, x = npc.x, y = npc.y, title = npc.name, kind = "quest" }
					end
				end
			end
		end
	end
	return #stops > 0 and ns.ShortestPath.Navigate("CommissionsForever", stops)
end

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("QUEST_LOG_UPDATE")
addon:SetScript("OnEvent", function(_, event)
	if event == "PLAYER_LOGIN" then
		CommissionsForeverDB = type(CommissionsForeverDB) == "table" and CommissionsForeverDB or {}
		_G.SLASH_COMMISSIONSFOREVER1 = "/commissions"
		_G.SLASH_COMMISSIONSFOREVER2 = "/cf"
		SlashCmdList.COMMISSIONSFOREVER = ns.Toggle
	end
	ns.Refresh()
end)

_G.CommissionsForever_OnAddonCompartmentClick = function()
	ns.Toggle()
end

return addonName
