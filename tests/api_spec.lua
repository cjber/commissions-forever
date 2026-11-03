local materials = { { itemID = 17203, count = 2 } }
local ns = {
	Stats = {
		Activity = function()
			return { { value = 3 } }
		end,
		Leaderboard = function(limit)
			assert(limit == 5)
			return { rows = { { value = 3, self = true } } }
		end,
	},
	SkillUp = {
		RequiredMaterials = function(recipeID, crafts)
			assert(recipeID == 1234 and crafts == 2)
			return materials
		end,
	},
	Questie = {
		ActiveObjectives = function()
			return { { questID = 99 } }
		end,
	},
	NavigateActiveAssignments = function()
		return true
	end,
}
local chunk = assert(loadfile("Core/API.lua"))
local api = chunk("CommissionsForever", ns)
assert(api.version == 1 and api.minor == 2, "publishes a versioned API")
assert(api.RequiredMaterials(1234, 2) == materials, "forwards recipe material requests to SkillUp Forever")
assert(api.ActiveObjectives()[1].questID == 99, "exposes a copy of active quest objectives")
assert(api.NavigateActiveAssignments(), "forwards turn-in routes to Shortest Path Forever")
assert(api.Stats()[1].value == 3, "exposes local completion observations")
assert(api.Leaderboard(5).rows[1].self, "forwards bounded leaderboard requests")
print("Commissions Forever API specs passed")
