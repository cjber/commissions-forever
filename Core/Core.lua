local addonName, ns = ...

local addon = CreateFrame("Frame")
ns.Addon = addon

local function ItemCount(itemID)
	return C_Item.GetItemCount(itemID) or 0
end

function ns.Refresh()
	ns.ActiveObjectives = ns.Questie.ActiveObjectives()
	ns.Rows = ns.Model.Inventory(ItemCount, ns.ActiveObjectives)
	if ns.Window and ns.Window.Refresh then
		ns.Window.Refresh()
	end
end

function ns.Toggle()
	if ns.Window then
		ns.Window.Toggle()
	end
end

-- Every active commission's finishers, finished objectives included: those are the quests ready to hand in.
function ns.NavigateActiveAssignments()
	local stops, seen = {}, {}
	for _, row in ipairs(ns.ActiveObjectives or {}) do
		if ns.Model.IsCommissionQuest(row.questName, row.sourceItemID) then
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
		SlashCmdList.COMMISSIONSFOREVER = function(message)
			local command = (message or ""):lower():match("^%s*(.-)%s*$")
			if command == "leaderboard" or command == "stats" then
				ns.Stats.Print()
			elseif command == "share on" or command == "share off" then
				ns.Stats.SetEnabled(command == "share on")
				ns.Stats.Print()
			else
				ns.Toggle()
			end
		end
	end
	ns.Refresh()
end)

_G.CommissionsForever_OnAddonCompartmentClick = function()
	ns.Toggle()
end

return addonName
