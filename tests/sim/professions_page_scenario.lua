-- The Commissions page inside the native Professions window (WFA-35): the player's way in through the side tab and
-- /cf, the hand-off between that page and Blizzard's own pages, the native search box, a side tab another addon
-- added, reopening the window, and the states that have broken before (combat, a secret tooltip, the gamepad
-- interface, Questie's tracker, an old saved file).
-- luacheck: read globals scenario ADDON

local TAB_TEXT = "Commissions Forever"
local SEARCH_SCRIPTS = {
	"OnEscapePressed",
	"OnEnterPressed",
	"OnEditFocusLost",
	"OnEditFocusGained",
	"OnTextChanged",
	"OnEnter",
	"OnLeave",
	"OnEnable",
	"OnDisable",
}

local function check(condition, message)
	if not condition then
		error(message, 2)
	end
end

-- Blacksmithing and Mining, each with its spellbook entry, so Blizzard shows both native profession tabs; and
-- Thorium Brotherhood materials in the bags, so the page lists rows.
local function world(sim)
	-- Client pieces the sim does not boot but the game always has, which Blizzard's Professions pages call:
	-- the casting bar (crafting page show and hide), the TOC's [Bootstrap] file (the game's own open entry
	-- points), the action bar grids and the micro menu refresh (book page show). Without them Blizzard's own
	-- OnShow stops half way and never reaches the hooks after it.
	sim:loadBlizzard("Blizzard_UIPanels_Game:CastingBarFrame")
	sim:loadBlizzard("Blizzard_Professions/Blizzard_Professions_Bootstrap.lua")
	sim:loadBlizzard("Blizzard_ActionBar/Shared/MultiActionBars.lua")
	if sim.G.UpdateMicroButtons == nil then
		sim.G.UpdateMicroButtons = function()
			sim.gaps["shim UpdateMicroButtons"] = true
		end
	end
	-- The client's LE_* constants are native, so Blizzard code reads them even when an addon's call tainted it.
	-- The sim answers them to untainted reads only; read the Professions UI's here, from the client's side.
	local professionsUI = sim.ui .. "/Interface/AddOns/Blizzard_Professions"
	local names = assert(io.popen(string.format('grep -rhoE "\\bLE_[A-Z0-9_]+" "%s"* | sort -u', professionsUI)))
	for name in names:lines() do
		local value
		sim.run(function()
			value = sim.env[name]
		end)
		check(value ~= nil, "the client has no " .. name)
	end
	names:close()
	local professions = {
		{
			skillLineID = 164,
			name = "Blacksmithing",
			skill = 30,
			max = 75,
			spellID = 2018,
			categories = { { id = 1, name = "Materials" } },
			recipes = { { id = 2660, name = "Rough Sharpening Stone", category = 1, itemID = 2862 } },
		},
		{ skillLineID = 186, name = "Mining", skill = 30, max = 75, spellID = 2575, categories = {}, recipes = {} },
	}
	sim.world.professions = professions
	for _, p in ipairs(professions) do
		sim.world.spells[p.spellID] = { name = p.name, icon = 136241 }
	end
	sim.impl.GetProfessionInfo = function(index)
		local p = professions[index]
		if p then
			return p.name, 136241, p.skill, p.max, 1, index - 1, p.skillLineID, 0, 0, 0, p.name
		end
	end
	sim.impl["C_SpellBook.GetSpellBookItemInfo"] = function(slot)
		local p = professions[slot]
		return p and { spellID = p.spellID, name = p.name, itemType = 1 }
	end
	sim.impl["C_TradeSkillUI.CanTradeSkillShowCraftingUI"] = function()
		return true
	end
	sim.world.items[11370] = { name = "Dark Iron Ore", count = 12 }
	sim.world.items[17010] = { name = "Fiery Core", count = 2 }
	sim.world.items[17011] = { name = "Lava Core", count = 3 }
	-- The client closes the window from its own trade-skill call, which forever_sim leaves unanswered. Answer it
	-- the way the client does, through a secure hide, so /cf's close is the same here as in game.
	sim.impl["C_TradeSkillUI.CloseTradeSkill"] = function()
		sim.run(function()
			local frame = sim.G.ProfessionsFrame
			if frame and frame:IsShown() then
				frame:Hide()
			end
		end)
	end
end

local function sideTabs(sim)
	local out = {}
	for _, child in ipairs({ sim.G.ProfessionsFrame:GetChildren() }) do
		if child.SetCustomOnMouseUpHandler and child.Icon then
			out[#out + 1] = child
		end
	end
	return out
end

local function commissionsTab(sim)
	local found
	for _, tab in ipairs(sideTabs(sim)) do
		if tab.tooltipText == TAB_TEXT then
			check(not found, "two Commissions tabs on the Professions window")
			found = tab
		end
	end
	check(found, "no Commissions tab on the Professions window")
	return found
end

-- The page: the ProfessionsFrame child, outside Blizzard's own pages, that holds a SearchBoxTemplate box.
local function searchBox(sim)
	local pf = sim.G.ProfessionsFrame
	local function walk(frame)
		for _, child in ipairs({ frame:GetChildren() }) do
			if child ~= pf.CraftingPage and child ~= pf.BookPage then
				if child.clearButton and child.searchIcon and child.Instructions then
					return child
				end
				local hit = walk(child)
				if hit then
					return hit
				end
			end
		end
	end
	local box = walk(pf)
	check(box, "no search box on the Commissions page")
	return box
end

local function page(sim)
	return searchBox(sim):GetParent()
end

local function checked(tab)
	return tab.SelectedTexture and tab.SelectedTexture:IsShown() or false
end

-- A left click on the Commissions side tab, as the client delivers it to its custom mouse-up handler.
local function press(sim, tab)
	local W = sim.widgets
	W.dispatch(tab, "OnMouseDown", "LeftButton")
	W.dispatch(tab, "OnMouseUp", "LeftButton", true)
	sim.events.flush()
	sim:advance(0.05)
end

-- A native tab pressed with the gamepad: the client runs the tab's OnClick with no mouse-up. The tab's own OnClick
-- switches the native page, then the Commissions post-hook on that script hands the window back.
local function click(sim, tab)
	sim:input(function()
		tab:OnClick()
		sim.widgets.dispatch(tab, "OnClick")
	end)
	sim:advance(0.05)
end

local function slash(sim)
	sim:input(function()
		sim.G.SlashCmdList.COMMISSIONSFOREVER("")
	end)
	sim:advance(0.1)
end

local function rows(sim)
	local list = {}
	local scroll
	for _, child in ipairs({ page(sim):GetChildren() }) do
		for _, inner in ipairs({ child:GetChildren() }) do
			if inner.GetScrollChild and inner:GetScrollChild() then
				scroll = inner
			end
		end
	end
	check(scroll, "no material list on the Commissions page")
	for _, row in ipairs({ scroll:GetScrollChild():GetChildren() }) do
		if row:IsShown() and row.name then
			list[#list + 1] = row.name:GetText()
		end
	end
	table.sort(list)
	return table.concat(list, ", ")
end

local function expectCommissionsPage(sim, why)
	local pf = sim.G.ProfessionsFrame
	local tab = commissionsTab(sim)
	check(pf:IsShown(), why .. ": the Professions window is closed")
	check(page(sim):IsVisible(), why .. ": the Commissions page is not shown")
	-- The native page stays shown beneath this page; showing or hiding it from addon code would taint the gamepad
	-- frame manager. The ledger takes its input from above.
	for _, nativePage in ipairs({ "CraftingPage", "BookPage" }) do
		if pf[nativePage]:IsShown() then
			check(
				page(sim):GetFrameLevel() > pf[nativePage]:GetFrameLevel(),
				why .. ": the Commissions page is not above " .. nativePage
			)
		end
	end
	check(page(sim):IsMouseEnabled(), why .. ": the Commissions page does not take input over the native page")
	check(checked(tab), why .. ": the Commissions tab is not selected")
	check(not checked(pf.ProfessionsOverviewTab), why .. ": the overview tab is still selected")
	for i, nativeTab in ipairs(pf.rightProfessionTabs) do
		check(not checked(nativeTab), why .. ": profession tab " .. i .. " is still selected")
	end
	sim:expectOnScreen(page(sim))
end

local function expectNativePage(sim, which, why)
	local pf = sim.G.ProfessionsFrame
	check(pf:IsShown(), why .. ": the Professions window is closed")
	check(not page(sim):IsShown(), why .. ": the Commissions page stayed over the native page")
	check(not checked(commissionsTab(sim)), why .. ": the Commissions tab stayed selected")
	check(pf[which]:IsShown(), why .. ": " .. which .. " is not shown")
end

-- Every shown side tab sits in its own slot, and the Commissions tab is directly under the lowest other one.
local function expectTabSlots(sim, why)
	local tabs = {}
	for _, tab in ipairs(sideTabs(sim)) do
		if tab:IsVisible() then
			tabs[#tabs + 1] = tab
		end
	end
	for i = 1, #tabs do
		for j = i + 1, #tabs do
			sim:expectNoOverlap(tabs[i], tabs[j])
		end
	end
	local ours = commissionsTab(sim)
	check(ours:IsVisible(), why .. ": the Commissions tab is hidden")
	local lowest
	for _, tab in ipairs(tabs) do
		if tab ~= ours and (not lowest or tab:GetBottom() < lowest:GetBottom()) then
			lowest = tab
		end
	end
	check(
		math.abs(ours:GetLeft() - lowest:GetLeft()) < 1 and math.abs(ours:GetTop() - (lowest:GetBottom() - 2)) < 1,
		why
			.. ": the Commissions tab is not in the slot under "
			.. sim.describeRect(lowest)
			.. ", it is at "
			.. sim.describeRect(ours)
	)
end

scenario("the side tab opens the Commissions page and every native tab takes the window back", function(sim)
	world(sim)
	sim:login()
	local pf = sim:openProfessions(164)
	check(pf.rightProfessionTabs[1]:IsShown() and pf.rightProfessionTabs[2]:IsShown(), "native tabs not shown")
	expectNativePage(sim, "CraftingPage", "opened on Blacksmithing")
	expectTabSlots(sim, "opened on Blacksmithing")

	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "after the Commissions tab")
	check(rows(sim) == "Dark Iron Ore, Fiery Core, Lava Core", "rows: " .. rows(sim))

	click(sim, pf.ProfessionsOverviewTab)
	expectNativePage(sim, "BookPage", "after the overview tab")
	check(checked(pf.ProfessionsOverviewTab), "the overview tab is not selected")

	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "back on the Commissions tab")

	click(sim, pf.rightProfessionTabs[1])
	expectNativePage(sim, "CraftingPage", "after the Blacksmithing tab")
	check(checked(pf.rightProfessionTabs[1]), "the Blacksmithing tab is not selected")
	check(not pf.BookPage:IsShown(), "the book page shows under the crafting page")
end)

scenario("a character with no profession is told on screen and no window opens", function(sim)
	sim:login()
	local messages = {}
	sim.G.UIErrorsFrame = {
		AddMessage = function(_, text)
			messages[#messages + 1] = text
		end,
	}
	local chat = #sim.chat
	slash(sim)
	sim:expectNoErrors(ADDON)
	check(
		not sim.G.ProfessionsFrame or not sim.G.ProfessionsFrame:IsShown(),
		"a character with no profession opened the Professions window"
	)
	check(#messages == 1, "no profession did not tell the player on screen exactly once")
	check(
		messages[1] == "Commissions opens in the Professions window. Learn a profession to use it.",
		"the no-profession message is not the phrase"
	)
	check(#sim.chat == chat, "the no-profession message went to chat")
end)

scenario("the search box keeps every native SearchBoxTemplate handler", function(sim)
	world(sim)
	sim:login()
	sim:openProfessions(164)
	press(sim, commissionsTab(sim))
	local box = searchBox(sim)
	local reference
	sim:input(function()
		reference = sim.G.CreateFrame("EditBox", nil, sim.G.UIParent, "SearchBoxTemplate")
	end)
	for _, script in ipairs(SEARCH_SCRIPTS) do
		check(
			box:GetScript(script) == reference:GetScript(script),
			script
				.. " is not SearchBoxTemplate's own handler: "
				.. tostring(box:GetScript(script))
				.. " replaced "
				.. tostring(reference:GetScript(script))
		)
	end
	check(box.Instructions:GetText() == sim.G.SEARCH, "the box lost its native Search instructions")
	check(box.Instructions:IsShown() and not box.clearButton:IsShown(), "an empty box shows its clear button")

	sim:input(function()
		box:SetFocus()
	end)
	check(box.clearButton:IsShown(), "focus did not show the native clear button")
	sim:input(function()
		box:SetText("core")
	end)
	sim:advance(0.05)
	check(not box.Instructions:IsShown(), "typing did not hide the native instructions")
	check(rows(sim) == "Fiery Core, Lava Core", "the filter did not run on typing: " .. rows(sim))

	sim.widgets.dispatch(box, "OnEscapePressed")
	sim:advance(0.05)
	check(not box:HasFocus(), "Escape kept the focus")
	check(box:GetText() == "core" and box.clearButton:IsShown(), "Escape cleared the text or the clear button")

	sim:click(box.clearButton)
	check(box:GetText() == "", "the native clear button left text")
	check(box.Instructions:IsShown() and not box.clearButton:IsShown(), "clearing did not restore the empty box")
	check(rows(sim) == "Dark Iron Ore, Fiery Core, Lava Core", "clearing did not restore the rows: " .. rows(sim))
end)

scenario("another addon's side tabs keep their slots and the Commissions tab goes under them", function(sim)
	world(sim)
	sim:login()
	sim:openProfessions(164)
	expectTabSlots(sim, "before the other addon")
	-- Another addon stacks two tabs under the native ones, outside Blizzard's array, as side-tab addons do.
	sim:runAs(
		"OtherSideTabs",
		[[
		local pf = ProfessionsFrame
		local last = pf.rightProfessionTabs[2]
		for i = 1, 2 do
			local tab = CreateFrame("Frame", "OtherSideTab" .. i, pf, "LargeSideTabButtonTemplate")
			tab.tooltipText = "Other " .. i
			tab:SetPoint("TOPLEFT", last, "BOTTOMLEFT", 0, -2)
			tab:Show()
			last = tab
		end
	]]
	)
	sim:closeProfessions()
	sim:openProfessions(164)
	expectTabSlots(sim, "after the other addon's tabs")
	check(
		commissionsTab(sim):GetTop() < sim.G.OtherSideTab2:GetBottom(),
		"the Commissions tab is not under the other addon's tabs"
	)

	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "with the other addon's tabs")
	check(sim.G.OtherSideTab1:IsVisible() and sim.G.OtherSideTab2:IsVisible(), "the other addon's tabs were hidden")
end)

scenario("closing on the Commissions page reopens the native window on its own page", function(sim)
	world(sim)
	sim:login()
	-- /cf before the Professions window has ever loaded.
	slash(sim)
	expectCommissionsPage(sim, "after /cf")
	slash(sim)
	check(not sim.G.ProfessionsFrame:IsShown(), "a second /cf did not close the window")

	local pf = sim:openProfessions(164)
	expectNativePage(sim, "CraftingPage", "reopened on Blacksmithing after /cf")
	sim:closeProfessions()
	check(not pf.BookPage:IsShown(), "closing on a native crafting page showed the native book page")
	sim:openProfessions(164)
	expectNativePage(sim, "CraftingPage", "reopened on Blacksmithing after a native close")

	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "the Commissions tab after reopening")
	sim:closeProfessions()
	check(not page(sim):IsVisible(), "the Commissions page is visible with the window closed")

	sim:openProfessions(164)
	expectNativePage(sim, "CraftingPage", "reopened from the Commissions page")
	expectTabSlots(sim, "reopened from the Commissions page")

	press(sim, commissionsTab(sim))
	sim:closeProfessions()
	sim:showPanel(pf)
	expectNativePage(sim, "CraftingPage", "the native profession page reopened from the Commissions page")

	slash(sim)
	expectCommissionsPage(sim, "/cf with the window already open")
end)

scenario("in combat, after a secret unit tooltip, a material row's tooltip still shows", function(sim)
	world(sim)
	sim:login()
	sim:openProfessions(164)
	press(sim, commissionsTab(sim))
	sim:enterCombat()
	sim:hoverUnit({ name = "Dark Iron Guard", level = 55, friendly = false })
	sim:unhoverUnit()
	local row
	for _, child in ipairs({ page(sim):GetChildren() }) do
		for _, inner in ipairs({ child:GetChildren() }) do
			if inner.GetScrollChild and inner:GetScrollChild() then
				row = ({ inner:GetScrollChild():GetChildren() })[1]
			end
		end
	end
	check(row and row:IsShown(), "no material row to hover")
	sim:hover(row)
	check(sim.G.GameTooltip:IsShown() and sim.G.GameTooltip:GetOwner() == row, "the row's item tooltip did not show")
	sim:leave()
	click(sim, sim.G.ProfessionsFrame.ProfessionsOverviewTab)
	expectNativePage(sim, "BookPage", "the overview tab in combat")
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "the Commissions tab in combat")
	check(
		sim.G.ProfessionsFrame.BookPage:IsShown(),
		"the book page should stay shown under the Commissions page in combat"
	)
	sim:leaveCombat()
	expectCommissionsPage(sim, "the Commissions tab after combat")
	check(sim.G.ProfessionsFrame.BookPage:IsShown(), "the book page left the native page under the Commissions page")
end)

scenario("the gamepad interface walks the window with the Commissions page open", function(sim)
	world(sim)
	sim:login()
	sim:setGamepad(true)
	local pf = sim:openProfessions(164)
	sim:gamepadNavigate()
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "with the gamepad interface")
	sim:gamepadNavigate()
	click(sim, pf.rightProfessionTabs[2])
	expectNativePage(sim, "CraftingPage", "the Mining tab with the gamepad interface")
	sim:gamepadNavigate()
	sim:expectNoGamepadTaint(ADDON)

	-- The client's own trade-skill call opens the window from /cf under the gamepad interface and owns its
	-- gamepad bookkeeping, so the tab still works there.
	sim:closeProfessions()
	sim:gamepadNavigate()
	slash(sim)
	check(pf:IsShown(), "gamepad /cf did not open the Professions window")
	expectCommissionsPage(sim, "/cf with the gamepad interface")
	sim:expectNoGamepadTaint(ADDON)

	-- The player opens Professions with the game's own control and presses the tab, then closes with /cf.
	sim:closeProfessions()
	sim:openProfessions(164)
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "the Commissions tab in a gamepad window")
	slash(sim)
	check(not pf:IsShown(), "gamepad /cf did not close the Professions window")
	sim:gamepadNavigate()
	sim:expectNoGamepadTaint(ADDON)

	-- Same, closed with the game's own close control: the native hide path must not change its page under our call.
	sim:openProfessions(164)
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "the Commissions tab before a native close")
	sim:closeProfessions()
	sim:gamepadNavigate()
	sim:expectNoGamepadTaint(ADDON)
end)

scenario("Questie's tracker and an old saved file", { stubs = { Questie = {} } }, function(sim)
	world(sim)
	sim:login({ savedVariables = "tests/sim/fixtures/old_saved.lua" })
	sim:advance(4)
	check(sim.G.Questie_BaseFrame and sim.G.Questie_BaseFrame:IsShown(), "Questie's tracker did not build")
	check(type(sim:savedState().CommissionsForeverDB) == "table", "the old saved value was kept")
	slash(sim)
	expectCommissionsPage(sim, "/cf with Questie's tracker")
	check(rows(sim) == "Dark Iron Ore, Fiery Core, Lava Core", "rows with Questie: " .. rows(sim))
end)

scenario("slash opens the ledger after a previously selected profession without recasting it", function(sim)
	world(sim)
	sim:login()
	local host = sim:openProfessions(164)
	check(host.selectedSkillLine == 164, "the native window did not remember Blacksmithing")
	sim:closeProfessions()
	local casts = 0
	sim.impl["C_SpellBook.CastSpellBookItem"] = function()
		casts = casts + 1
	end
	slash(sim)
	check(casts == 0, "/cf recast the old profession, whose TRADE_SKILL_SHOW would replace the ledger")
	expectCommissionsPage(sim, "/cf after closing a previously selected profession")
end)

scenario("in combat, /cf waits for combat to end and then opens the ledger", function(sim)
	world(sim)
	sim:login()
	local messages = {}
	sim.G.UIErrorsFrame = {
		AddMessage = function(_, text)
			messages[#messages + 1] = text
		end,
	}
	sim:enterCombat()
	local chat = #sim.chat
	slash(sim)
	sim:expectNoErrors(ADDON)
	check(
		not sim.G.ProfessionsFrame or not sim.G.ProfessionsFrame:IsShown(),
		"combat /cf opened the Professions window"
	)
	check(#messages == 1, "combat /cf did not tell the player on screen")
	check(messages[1] == "Commissions opens when combat ends.", "the on-screen message is not the phrase")
	check(#sim.chat == chat, "combat /cf wrote to chat")
	sim:leaveCombat()
	sim:expectNoErrors(ADDON)
	expectCommissionsPage(sim, "after combat ended")

	-- Two toggles in combat share one pending open, which runs when combat ends.
	sim:closeProfessions()
	sim:enterCombat()
	slash(sim)
	slash(sim)
	sim:expectNoErrors(ADDON)
	sim:leaveCombat()
	expectCommissionsPage(sim, "two /cf in combat")
end)

scenario("completion controls preserve the ledger and count only supported turn-in events", function(sim)
	world(sim)
	-- Synthetic public-contract fixture. No quest-log title or inventory change establishes completion.
	sim:runAs(
		"QuestieDB",
		[[
		LibQuestieDB = {
			RequireContract = function() return true end,
			Meta = { QuestMeta = { questKeys = {
				specialFlags = 1, finishedBy = 2, reputationReward = 3,
				objectives = 4, sourceItemId = 5, startedBy = 6,
			} } },
			Enum = { factionIDs = { THORIUM_BROTHERHOOD = 59 } },
			Quest = { GetAll = function(id)
				if id == 123 then
					return { 1, { { 42 } }, { { 59, 10 } }, { [3] = { { 11370, "Ore", 10 } } } }
				end
			end },
		}
	]]
	)
	sim:login()
	slash(sim)
	local share, board
	for _, child in ipairs({ page(sim):GetChildren() }) do
		if child.Text and child.Text.GetText and child.Text:GetText() == "Share my progress" then
			share = child
		elseif child.GetText and child:GetText() == "Leaderboard" then
			board = child
		end
	end
	check(share and board, "completion controls are missing from the native page")
	check(share:GetChecked(), "participation should default on")
	sim:click(share)
	check(sim:savedState().CommissionsForeverDB.statsShare == false, "the checkbox did not save explicit opt-out")
	check(not share:GetChecked(), "the checkbox stayed checked after opt-out")
	check(not sim.G.CommissionsForever.API.Leaderboard().sharing, "opt-out left the shared view enabled")
	sim:event("QUEST_TURNED_IN", 123, 0, 0)
	sim:event("QUEST_TURNED_IN", 123, 0, 0)
	sim:event("QUEST_TURNED_IN", 124, 0, 0)
	check(sim.G.CommissionsForever.API.Stats()[1].value == 2, "repeat hand-ins were lost or an unrelated quest counted")
	-- The Leaderboard button opens the shared Forever Leaderboards window, which is client UI the simulator does
	-- not render; the board itself still reads while in combat.
	check(
		sim.G.CommissionsForever.API.Leaderboard().rows[1].value == 2,
		"the personal board stopped reading after opt-out"
	)
	sim:enterCombat()
	sim:hoverUnit({ name = "Guard", level = 55, friendly = false })
	sim:unhoverUnit()
	sim:hover(share)
	check(sim.G.GameTooltip:IsShown(), "the sharing explanation did not show after a secret tooltip")
	sim:leave()
	sim:input(function()
		sim.G.SlashCmdList.COMMISSIONSFOREVER("share on")
	end)
	check(share:GetChecked(), "slash participation did not refresh the visible checkbox")
	sim:leaveCombat()
	sim:setGamepad(true)
	sim:gamepadNavigate()
	sim:expectNoGamepadTaint(ADDON)
end)
