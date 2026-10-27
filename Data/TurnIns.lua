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
		items = { 21105 }, -- Logistics Task Briefing; the requested goods vary by assignment.
		quest = "Logistics Task Briefing",
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
		items = { 21377, 21383, 21384 }, -- Headdress Feather, Spirit Beads, Ritual Totem.
		quest = "Feathers for Nafien",
		questAliases = { "Winterfall Spirit Beads", "Deadwood Headdress Feather" },
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
