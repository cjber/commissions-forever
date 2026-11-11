-- luacheck: read globals scenario
-- Every surface, in and out of combat and across a reload, with the gamepad interface on and off.
-- forever_sim leaves C_TradeSkillUI.CloseTradeSkill unanswered; the client hides the window from that call. Answer it
-- the way the client does, through a secure hide, so the close from /commissions runs the same path as in game.
local ForeverCore = dofile("tests/forever_core.lua")
scenario("every surface, in and out of combat and across a reload", { addons = ForeverCore.addons() }, function(sim)
	sim.impl["C_TradeSkillUI.CloseTradeSkill"] = function()
		sim.run(function()
			local frame = sim.G.ProfessionsFrame
			if frame and frame:IsShown() then
				frame:Hide()
			end
		end)
	end
	sim:exercise()
end)
