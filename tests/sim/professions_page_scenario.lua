-- The Commissions page inside the native Professions window (WFA-35): the player's way in through the side tab and
-- /commissions, the hand-off between that page and Blizzard's own pages, the native search box, a side tab another
-- addon added, reopening the window, and the states that have broken before (combat, a secret tooltip, the gamepad
-- interface, Questie's tracker, an old saved file).
-- luacheck: read globals scenario ADDON

local ForeverCore = dofile("tests/forever_core.lua")
-- Every scenario loads ForeverCore first, as the client loads the TOC's required dependency.
local declare = scenario
local function scenario(name, options, fn)
	if type(options) == "function" then
		options, fn = {}, options
	end
	options.addons = options.addons or ForeverCore.addons()
	declare(name, options, fn)
end

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
	-- the way the client does, through a secure hide, so /commissions's close is the same here as in game.
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

-- The documented FrameStrata order, lowest first, for comparing frames the way the client draws them.
local STRATA = {
	BACKGROUND = 1,
	LOW = 2,
	MEDIUM = 3,
	HIGH = 4,
	DIALOG = 5,
	FULLSCREEN = 6,
	FULLSCREEN_DIALOG = 7,
	TOOLTIP = 8,
}

local function above(frame, other)
	local rank = STRATA[frame:GetFrameStrata()] or 0
	local otherRank = STRATA[other:GetFrameStrata()] or 0
	return rank > otherRank or (rank == otherRank and frame:GetFrameLevel() > other:GetFrameLevel())
end

-- A left click on the Commissions side tab, as the client delivers it to its custom mouse-up handler.
local function press(sim, tab)
	local W = sim.widgets
	W.dispatch(tab, "OnMouseDown", "LeftButton")
	W.dispatch(tab, "OnMouseUp", "LeftButton", true)
	sim.events.flush()
	sim:advance(0.05)
end

-- A native tab pressed without the mouse-down/mouse-up pair a real click sends, the way the gamepad's tab indicator
-- reaches the tab. The shared owner hands the window back from the tab's mouse-up script, not from its OnClick.
local function click(sim, tab)
	sim.widgets.dispatch(tab, "OnMouseUp", "LeftButton", true)
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
			check(above(page(sim), pf[nativePage]), why .. ": the Commissions page is not above " .. nativePage)
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

	-- Every native tab takes the window back by mouse and by the gamepad's OnClick path.
	local nativeTabs = {
		{ tab = pf.ProfessionsOverviewTab, nativePage = "BookPage", name = "the overview tab" },
		{ tab = pf.rightProfessionTabs[1], nativePage = "CraftingPage", name = "the Blacksmithing tab" },
		{ tab = pf.rightProfessionTabs[2], nativePage = "CraftingPage", name = "the Mining tab" },
	}
	for _, case in ipairs(nativeTabs) do
		for _, path in ipairs({ "mouse", "gamepad" }) do
			press(sim, commissionsTab(sim))
			expectCommissionsPage(sim, case.name .. " is about to take the window back by " .. path)
			if path == "mouse" then
				press(sim, case.tab)
			else
				click(sim, case.tab)
			end
			expectNativePage(sim, case.nativePage, case.name .. " by " .. path)
			check(checked(case.tab), case.name .. " is not selected after " .. path)
		end
	end
	check(not pf.BookPage:IsShown(), "the book page shows under the crafting page")

	-- A skill-up fires SKILL_LINES_CHANGED, whose RefreshRightTabs selects the open profession's tab itself. That is
	-- not a player choosing a tab, so the Commissions page stays above it.
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "before a skill-up")
	sim.events.fire("SKILL_LINES_CHANGED")
	sim:advance(0.05)
	check(page(sim):IsVisible(), "a skill-up deselected the Commissions page")
	check(checked(commissionsTab(sim)), "a skill-up deselected the Commissions tab")
	local selected = 0
	for _, nativeTab in ipairs(pf.rightProfessionTabs) do
		if checked(nativeTab) then
			selected = selected + 1
		end
	end
	check(selected == 1, "a skill-up did not select the open profession's native tab")

	-- Attach gets past its tab hooks: its OnHide hook is installed, so a native close puts the page away.
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "before a native close")
	sim:closeProfessions()
	check(
		not page(sim):IsVisible(),
		"Attach stopped before its OnHide hook: the page stayed shown after a native close"
	)
	check(not checked(commissionsTab(sim)), "Attach stopped before its OnHide hook: the tab stayed selected")
end)

scenario("a HIGH frame under the book page stays below the Commissions page", function(sim)
	world(sim)
	sim:login()
	local pf = sim:openProfessions(164)
	click(sim, pf.ProfessionsOverviewTab)
	check(pf.BookPage:IsShown(), "the book page did not open")
	-- The book page's rank bars are HIGH while the page is MEDIUM, so the page has to cover their strata, not just
	-- a level above the page frame.
	sim:runAs(
		"SyntheticStatusBar",
		[[
		local bar = CreateFrame("Frame", "TestHighStatusBar", ProfessionsFrame.BookPage)
		bar:SetFrameStrata("HIGH")
		bar:SetFrameLevel(12)
		bar:Show()
	]]
	)
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "with a HIGH frame under the book page")
	local bar = sim.G.TestHighStatusBar
	local strata = page(sim):GetFrameStrata()
	check(
		(STRATA[strata] or 0) >= STRATA.HIGH,
		"the Commissions page stayed below the book page's HIGH strata: " .. strata
	)
	check(above(page(sim), bar), "a HIGH frame under the book page draws over the Commissions page")

	-- A native page can create and re-level frames after attach; the next show takes the new highest level. The
	-- late frame sits in whatever strata the page found highest, above the page's current level.
	local lateStrata = strata
	local lateLevel = page(sim):GetFrameLevel() + 10
	sim:runAs(
		"SyntheticStatusBar",
		string.format(
			[[
		local bar = CreateFrame("Frame", "TestLateStatusBar", ProfessionsFrame.BookPage)
		bar:SetFrameStrata(%q)
		bar:SetFrameLevel(%d)
		bar:Show()
	]],
			lateStrata,
			lateLevel
		)
	)
	click(sim, pf.ProfessionsOverviewTab)
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "after a frame was created and re-levelled under the book page")
	bar = sim.G.TestLateStatusBar
	check(
		page(sim):GetFrameStrata() == lateStrata and page(sim):GetFrameLevel() == lateLevel + 1,
		"the Commissions page did not take the new level under "
			.. lateStrata
			.. ": "
			.. page(sim):GetFrameStrata()
			.. " "
			.. page(sim):GetFrameLevel()
	)
	check(above(page(sim), bar), "a frame created after attach draws over the Commissions page")
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

-- cjber/forever-core#382: the shared owner places every registered tab under the client's own in registration
-- order. A SkillUp-like second tab, the client's own tab, a profession change and the way back each leave exactly
-- one page shown, and the window keeps one width and its anchor throughout.
scenario("Commissions and a second registered tab keep one page and one window", function(sim)
	world(sim)
	sim:login()
	local pf = sim:openProfessions(164)
	sim:runAs(
		"SkillUpForever",
		[[
		local page = CreateFrame("Frame", "SkillUpScenarioPage", UIParent)
		local tab = ForeverCore.ProfessionTabs.Register("skillup", {
			icon = "Interface\\Icons\\INV_Misc_Note_01",
			tooltip = "SkillUp Forever",
			page = page,
		})
		SkillUpScenario = { page = page, tab = tab }
	]]
	)
	local second = sim.G.SkillUpScenario
	check(second and second.page and second.tab, "the second registered tab was not built")
	local secondPage, secondTab = second.page, second.tab

	-- The window keeps the client's own width and its anchor while tabs and professions change.
	local width, point = pf:GetWidth(), { pf:GetPoint(1) }
	check(width > 1, "the client gave the window a width")
	local function stable(why)
		check(pf:GetWidth() == width, why .. ": the window width changed to " .. tostring(pf:GetWidth()))
		local now = { pf:GetPoint(1) }
		check(#now == #point, why .. ": the window anchor changed")
		for index = 1, #point do
			check(now[index] == point[index], why .. ": the window anchor changed at " .. index)
		end
	end
	local function only(expected, why)
		local count, actual = 0, nil
		for _, candidate in ipairs({ page(sim), secondPage }) do
			if candidate:IsShown() then
				count, actual = count + 1, candidate
			end
		end
		check(count == 1 and actual == expected, why .. ": exactly one registered page must be shown")
	end

	-- Both tabs sit in their own slots, in registration order under the lowest client tab.
	local tabs = sideTabs(sim)
	for i = 1, #tabs do
		for j = i + 1, #tabs do
			sim:expectNoOverlap(tabs[i], tabs[j])
		end
	end
	local lowest
	for _, tab in ipairs(pf.rightProfessionTabs) do
		if tab:IsShown() and (not lowest or tab:GetBottom() < lowest:GetBottom()) then
			lowest = tab
		end
	end
	check(lowest, "the client has no side tab to place the registered tabs under")
	local ours = commissionsTab(sim)
	check(
		math.abs(ours:GetLeft() - lowest:GetLeft()) < 1 and math.abs(ours:GetTop() - (lowest:GetBottom() - 2)) < 1,
		"the Commissions tab at "
			.. sim.describeRect(ours)
			.. " is not directly under the client's own side tab at "
			.. sim.describeRect(lowest)
	)
	check(
		math.abs(secondTab:GetLeft() - ours:GetLeft()) < 1 and math.abs(secondTab:GetTop() - (ours:GetBottom() - 2)) < 1,
		"the second registered tab at "
			.. sim.describeRect(secondTab)
			.. " is not directly under the Commissions tab at "
			.. sim.describeRect(ours)
	)

	press(sim, ours)
	only(page(sim), "after the Commissions tab")
	check(checked(ours) and not checked(secondTab), "the Commissions tab is not the only selected tab")
	stable("after the Commissions tab")

	press(sim, secondTab)
	only(secondPage, "after the second tab")
	check(checked(secondTab) and not checked(ours), "the second tab is not the only selected tab")
	stable("after the second tab")

	press(sim, pf.rightProfessionTabs[1])
	check(not page(sim):IsShown() and not secondPage:IsShown(), "a client tab left a registered page shown")
	check(pf.CraftingPage:IsShown(), "a client tab did not show its own page")
	check(not checked(ours) and not checked(secondTab), "a client tab left a registered tab selected")
	stable("after a client tab")

	-- A profession change hands the window back to the client and keeps the one width and anchor.
	sim:openProfessions(186)
	sim:advance(0.2)
	check(not page(sim):IsShown() and not secondPage:IsShown(), "a profession change left a registered page shown")
	stable("after a profession change")

	press(sim, ours)
	only(page(sim), "back on Commissions")
	stable("back on Commissions")

	press(sim, secondTab)
	only(secondPage, "back on the second tab")
	stable("back on the second tab")

	-- A skill-up refreshes the client's own tabs without taking the selected registered page away.
	sim.events.fire("SKILL_LINES_CHANGED")
	sim:advance(0.05)
	only(secondPage, "after a skill-up")
	stable("after a skill-up")

	sim:expectNoErrors(ADDON)
end)

scenario("closing on the Commissions page reopens the native window on its own page", function(sim)
	world(sim)
	sim:login()
	-- /commissions cannot open the window from addon code; it waits for the player's own profession control.
	slash(sim)
	check(
		not sim.G.ProfessionsFrame or not sim.G.ProfessionsFrame:IsShown(),
		"/commissions opened the Professions window itself"
	)
	local pf = sim:openProfessions(164)
	expectCommissionsPage(sim, "the player's profession after /commissions")
	slash(sim)
	check(not pf:IsShown(), "a second /commissions did not close the window")

	sim:openProfessions(164)
	expectNativePage(sim, "CraftingPage", "reopened on Blacksmithing after /commissions")
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
	expectCommissionsPage(sim, "/commissions with the window already open")
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
	-- A client tab hands the window back at once in the shared owner's checks, while the pages wait for combat to
	-- end: the protected native window and this addon's secure children refuse the swap under our taint.
	click(sim, sim.G.ProfessionsFrame.ProfessionsOverviewTab)
	check(not checked(commissionsTab(sim)), "the overview tab in combat left the Commissions tab selected")
	check(page(sim):IsShown(), "combat hid the Commissions page before combat ended")
	check(sim.G.ProfessionsFrame.BookPage:IsShown(), "the overview tab in combat did not show the book page")
	sim:leaveCombat()
	sim:advance(0.2)
	expectNativePage(sim, "BookPage", "the overview tab after combat")

	sim:enterCombat()
	press(sim, commissionsTab(sim))
	check(checked(commissionsTab(sim)), "the Commissions tab in combat is not selected")
	check(not page(sim):IsShown(), "combat showed the Commissions page before combat ended")
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

	-- /commissions asks for the page, and the player opens the window with their own profession control under the gamepad
	-- interface; the page appears with it and the gamepad bookkeeping stays the client's.
	sim:closeProfessions()
	sim:gamepadNavigate()
	slash(sim)
	check(not pf:IsShown(), "gamepad /commissions opened the Professions window itself")
	sim:openProfessions(164)
	expectCommissionsPage(sim, "/commissions with the gamepad interface")
	sim:expectNoGamepadTaint(ADDON)

	-- The player opens Professions with the game's own control and presses the tab, then closes with /commissions.
	sim:closeProfessions()
	sim:openProfessions(164)
	press(sim, commissionsTab(sim))
	expectCommissionsPage(sim, "the Commissions tab in a gamepad window")
	slash(sim)
	check(not pf:IsShown(), "gamepad /commissions did not close the Professions window")
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
	sim:openProfessions(164)
	expectCommissionsPage(sim, "/commissions with Questie's tracker")
	check(rows(sim) == "Dark Iron Ore, Fiery Core, Lava Core", "rows with Questie: " .. rows(sim))
end)

scenario("slash waits for the player's profession without recasting the previously selected one", function(sim)
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
	check(casts == 0, "/commissions recast the old profession, whose TRADE_SKILL_SHOW would replace the ledger")
	check(not host:IsShown(), "/commissions opened the Professions window itself")
	sim:openProfessions(164)
	expectCommissionsPage(sim, "/commissions after closing a previously selected profession")
end)

scenario("in combat, /commissions waits for combat to end and then opens the ledger", function(sim)
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
		"combat /commissions opened the Professions window"
	)
	check(#messages == 1, "combat /commissions did not tell the player on screen")
	check(messages[1] == "Commissions opens when combat ends.", "the on-screen message is not the phrase")
	check(#sim.chat == chat, "combat /commissions wrote to chat")
	sim:leaveCombat()
	sim:expectNoErrors(ADDON)
	check(
		not sim.G.ProfessionsFrame or not sim.G.ProfessionsFrame:IsShown(),
		"the pending open opened the window itself"
	)
	check(#messages == 2, "the pending open did not tell the player how to open the window")
	check(
		messages[2] == "Commissions opens in the Professions window. Open it from your spellbook.",
		"the pending open's on-screen message is not the phrase"
	)
	sim:openProfessions(164)
	expectCommissionsPage(sim, "after combat ended and the player opened their profession")

	-- Two toggles in combat share one pending request, which waits when combat ends.
	sim:closeProfessions()
	sim:enterCombat()
	slash(sim)
	slash(sim)
	sim:expectNoErrors(ADDON)
	sim:leaveCombat()
	check(not sim.G.ProfessionsFrame:IsShown(), "two /commissions in combat opened the window itself")
	sim:openProfessions(164)
	expectCommissionsPage(sim, "two /commissions in combat")
end)

scenario("completion records count only supported turn-in events", function(sim)
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
	sim:openProfessions(164)
	-- Forever Leaderboards is gone: neither its button nor its sharing switch is on the page.
	for _, child in ipairs({ page(sim):GetChildren() }) do
		local label
		if child.Text and child.Text.GetText then
			label = child.Text:GetText()
		elseif child.GetText then
			local ok, text = pcall(child.GetText, child)
			label = ok and text or nil
		end
		check(
			label ~= "Share my progress" and label ~= "Leaderboard",
			"a removed leaderboard control is still on the page"
		)
	end
	sim:event("QUEST_TURNED_IN", 123, 0, 0)
	sim:event("QUEST_TURNED_IN", 123, 0, 0)
	sim:event("QUEST_TURNED_IN", 124, 0, 0)
	check(sim.G.CommissionsForever.API.Stats()[1].value == 2, "repeat hand-ins were lost or an unrelated quest counted")
	check(sim.G.CommissionsForever.API.Leaderboard == nil, "the board member is still published")
end)

-- cjber/commissions-forever#194: the client refuses C_TradeSkillUI.OpenTradeSkill from addon code
-- (AllowedWhenUntainted), so opening Commissions must never call it. The command and the addon compartment tell the
-- player on screen how to open the window, and the page appears when they open it with their own profession control.
scenario("opening Commissions never calls the blocked trade-skill function", function(sim)
	world(sim)
	sim:login()
	-- The client's answer to the old open path: a blocked action, exactly as the game reports it.
	sim.impl["C_TradeSkillUI.OpenTradeSkill"] = function()
		sim.forbidden("C_TradeSkillUI.OpenTradeSkill")
	end
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
		"/commissions opened the Professions window itself"
	)
	check(#messages == 1, "/commissions did not tell the player on screen how to open the window")
	check(
		messages[1] == "Commissions opens in the Professions window. Open it from your spellbook.",
		"/commissions's on-screen message is not the phrase"
	)
	check(#sim.chat == chat, "/commissions wrote to chat")

	-- The player opens the window with their own profession control; the waiting page appears with it.
	sim:openProfessions(164)
	expectCommissionsPage(sim, "the player opened their profession after /commissions")
	sim:expectNoErrors(ADDON)

	-- The addon compartment takes the same path.
	sim:closeProfessions()
	messages = {}
	sim:input(function()
		sim.G.CommissionsForever_OnAddonCompartmentClick()
	end)
	sim:advance(0.1)
	sim:expectNoErrors(ADDON)
	check(not sim.G.ProfessionsFrame:IsShown(), "the addon compartment opened the Professions window itself")
	check(#messages == 1, "the addon compartment did not tell the player on screen how to open the window")
	check(
		messages[1] == "Commissions opens in the Professions window. Open it from your spellbook.",
		"the addon compartment's on-screen message is not the phrase"
	)
	check(#sim.chat == chat, "the addon compartment wrote to chat")
	sim:openProfessions(164)
	expectCommissionsPage(sim, "the player opened their profession after the addon compartment")
	sim:expectNoErrors(ADDON)

	-- With the window already open, the command only selects the page and says nothing.
	sim:closeProfessions()
	sim:openProfessions(164)
	expectNativePage(sim, "CraftingPage", "the player opened Blacksmithing")
	local beforeOpen = #messages
	slash(sim)
	expectCommissionsPage(sim, "/commissions with the window already open")
	check(#messages == beforeOpen, "/commissions said how to open a window that was already open")
	sim:expectNoErrors(ADDON)
end)
