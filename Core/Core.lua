local addonName, ns = ...

if ns.broken then
	return
end

-- The one client icon every in-game identity surface draws: the Professions side tab. The TOC declares it once, and
-- the drawn media/Icon stays the addon list, compartment and store identity.
ns.ICON = C_AddOns.GetAddOnMetadata(addonName, "X-Forever-Icon") --[[@as string]]

-- The shared services, registered once: the report window's title, this addon's own report lines, and later the
-- journal and log that live in CommissionsForeverDB.
ns.core = ForeverCore.Register(addonName, {
	title = ns.ReportTitle,
	lines = ns.ReportLines,
})

-- Hands the generated player credits to the shared Thanks page (WFA-31). An older core has no Credits module, and the
-- addon loads as before.
if type(ForeverCore.Credits) == "table" then
	ns.core.SafeCall("credits", ForeverCore.Credits.Register, "Commissions Forever", ns.Credits)
end

local addon = CreateFrame("Frame")
ns.Addon = addon

local function ItemCount(itemID)
	return C_Item.GetItemCount(itemID) or 0
end

-- True once a scan read QuestieDB's quest fields: a bag change cannot change the quest log, so it reuses that scan and
-- only recounts the bags. A scan that could not read them settles nothing, so the next refresh scans again until it
-- can, and a scan from a library since replaced is not reused either.
local objectivesScanned = false
local scannedGeneration ---@type integer?
-- Objective items whose names had not cached at the last scan: the scan matches objectives by name, so a name
-- arriving for one of them rescans.
local waitingNames = {} ---@type table<integer, true>

---@param scanObjectives boolean? true when the quest log or the item names it matches on may have changed
function ns.Refresh(scanObjectives)
	local generation = ns.Questie.Generation and ns.Questie.Generation()
	if scanObjectives or not objectivesScanned or generation ~= scannedGeneration then
		local read, waiting
		ns.ActiveObjectives, read, waiting = ns.Questie.ActiveObjectives()
		objectivesScanned, waitingNames = read == true, waiting or {}
		scannedGeneration = generation
	end
	ns.Rows = ns.Model.Inventory(ItemCount, ns.ActiveObjectives)
	ns.Refreshed = true
	ns.APIChanged("refresh")
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
		if ns.Questie.CommissionCategory(row.questID) then
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

local started = false
function ns.Start()
	if started then
		return
	end
	started = true
	CommissionsForeverDB = type(CommissionsForeverDB) == "table" and CommissionsForeverDB or {}
	ns.core.Attach(CommissionsForeverDB)
	if ns.StartStats then
		ns.StartStats()
	end
	_G.SLASH_COMMISSIONSFOREVER1 = "/commissions"
	SlashCmdList.COMMISSIONSFOREVER = function(message)
		local command = (message or ""):lower():match("^%s*(.-)%s*$")
		if ns.core.Report.Command(command) then
			return
		end
		ns.Toggle()
	end
	ns.Refresh(true)
end

addon:RegisterEvent("PLAYER_LOGIN")
addon:RegisterEvent("BAG_UPDATE_DELAYED")
addon:RegisterEvent("QUEST_LOG_UPDATE")
addon:RegisterEvent("ADDON_LOADED")
addon:RegisterEvent("GET_ITEM_INFO_RECEIVED")
addon:SetScript("OnEvent", function(_, event, arg)
	if event == "PLAYER_LOGIN" then
		ns.Start()
	elseif event == "QUEST_LOG_UPDATE" then
		ns.Refresh(true)
	elseif event == "ADDON_LOADED" then
		-- QuestieDB loading after the login scan (late, or replaced) has no quest or bag event of its own, so the rows
		-- it would change are read once it can answer.
		if ns.Refreshed and ns.Questie.Available() then
			local generation = ns.Questie.Generation and ns.Questie.Generation()
			if not objectivesScanned or generation ~= scannedGeneration then
				ns.Refresh(true)
			end
		end
	elseif event == "GET_ITEM_INFO_RECEIVED" then
		if ns.Refreshed and waitingNames[tonumber(arg)] then
			ns.Refresh(true)
		end
	else
		ns.Refresh()
	end
end)

_G.CommissionsForever_OnAddonCompartmentClick = function()
	ns.Toggle()
end

return addonName
