local _, ns = ...

-- Item IDs are client data. Active quest objectives, including the variable Logistics Assignment
-- requirements and individual Craftsman's Writ recipes, come from the live quest log.
ns.TurnIns = {
	{
		key = "argentDawn",
		faction = "Argent Dawn",
		place = "Light's Hope Chapel",
		items = { 12844 }, -- Argent Dawn Valor Token, used to obtain a Craftsman's Writ.
		quest = "Craftsman's Writ",
	},
	{
		key = "cenarionCircle",
		faction = "Cenarion Circle",
		place = "Cenarion Hold",
		items = {}, -- Logistics assignments come from the active quest log, not a guessed briefing item.
		quest = "Logistics Task Briefing",
		-- Client briefing items identify assignments whose quest titles differ from the briefing.
		sourceItems = {
			20806,
			20807,
			20939,
			20940,
			21257,
			21258,
			21259,
			21260,
			21261,
			21262,
			21263,
			21264,
			21265,
			21378,
			21379,
			21380,
			21381,
			21382,
			21384,
			21385,
			21514,
		},
	},
	{
		key = "thoriumBrotherhood",
		faction = "Thorium Brotherhood",
		place = "The Grim Guzzler",
		items = { 11370, 17012, 11382, 17010, 17011 },
		quest = "Favor Amongst the Brotherhood",
	},
	{
		key = "timbermawHold",
		faction = "Timbermaw Hold",
		place = "Timbermaw Hold",
		items = { 21377, 21383, 20741, 20742 }, -- Headdress Feather, Spirit Beads, Deadwood and Winterfall Ritual Totems.
		quest = "Feathers for Nafien",
		questAliases = { "Beads for Salfa", "Feathers for Grazle", "Deadwood Ritual Totem", "Winterfall Ritual Totem" },
	},
	{
		key = "morrowgrain",
		faction = "Morrowgrain research",
		place = "Darnassus or Thunder Bluff",
		items = { 11040, 11018 }, -- Morrowgrain and Un'Goro Soil.
		quest = "Morrowgrain",
		questAliases = { "Un'Goro Soil" },
	},
}
