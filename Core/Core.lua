local addonName, ns = ...

if ns.broken then
	return
end

-- The one client icon every in-game identity surface draws: the Professions side tab and the leaderboard tab. The TOC
-- declares it once, and the drawn media/Icon stays the addon list, compartment and store identity.
ns.ICON = C_AddOns.GetAddOnMetadata(addonName, "X-Forever-Icon") --[[@as string]]

-- The shared services, registered once: the report window's title, this addon's own report lines, and later the
-- journal and log that live in CommissionsForeverDB.
ns.core = ForeverCore.Register(addonName, {
	title = ns.ReportTitle,
	lines = ns.ReportLines,
})

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
		-- The journal and the log ring are Forever Core's now, under `errors` and `log` in this same table, which
		-- Attach makes when they are missing and merges into when an older save has them.
		ns.core.Attach(CommissionsForeverDB)
		_G.SLASH_COMMISSIONSFOREVER1 = "/commissions"
		_G.SLASH_COMMISSIONSFOREVER2 = "/cf"
		SlashCmdList.COMMISSIONSFOREVER = function(message)
			local command = (message or ""):lower():match("^%s*(.-)%s*$")
			if ns.core.Report.Command(command) then
				return
			end
			if command == "leaderboard" or command == "stats" then
				ns.Stats.Open()
			elseif command == "share on" or command == "share off" then
				ns.Stats.SetEnabled(command == "share on")
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
