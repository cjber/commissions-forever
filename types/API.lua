---@meta

-- CommissionsForever.API, version 1, minor 3: the contract other addons read (docs/api.md). Core/API.lua implements
-- it, and these declarations never load in the client.

-- ForeverCore.APIKit's not-ready reasons. "loading" asks again later, "disabled" is the player's choice and "none"
-- is nothing to answer. They come from the kit so every Forever addon answers the same way.
---@alias CommissionsAPIReason ForeverCoreAPIReason

---@class CommissionsAPIMaterial
---@field itemID integer
---@field count number

---@class CommissionsAPIObjective
---@field questID integer
---@field questName string QuestieDB's name, or the quest log's title when it has none
---@field itemID integer
---@field sourceItemID? integer the item that both starts and is provided by the quest
---@field required? integer the quest log's required count, absent before the client has the item cached
---@field finished boolean the quest log's progress for that item
---@field npcIDs integer[] fresh finisher NPC IDs

---@class CommissionsAPIStatsRow
---@field addon "CommissionsForever"
---@field metric "commission_turnin"
---@field subject "all"
---@field value integer
---@field eventUnix? integer the last accepted turn-in's time, absent before the first one

---@class CommissionsAPILeaderboardRow
---@field rank integer
---@field name string
---@field value integer
---@field eventUnix? integer
---@field self? boolean true on this character's row

---@class CommissionsAPILeaderboard
---@field metric "commission_turnin"
---@field scope "guild_group"
---@field ruleset? string the client's game-mode record ID and Hardcore flag, absent when the client cannot classify
---@field sharing boolean whether this character sends and receives totals
---@field total integer every eligible row, before the limit
---@field rows CommissionsAPILeaderboardRow[]

---@class CommissionsPublicAPI
---@field version 1
---@field minor 3
---@field RequiredMaterials fun(recipeID: integer, crafts?: integer): CommissionsAPIMaterial[]?, CommissionsAPIReason?
---@field ActiveObjectives fun(): CommissionsAPIObjective[]?, CommissionsAPIReason?
---@field NavigateActiveAssignments fun(): boolean
---@field Stats fun(): CommissionsAPIStatsRow[]
---@field Leaderboard fun(limit?: integer): CommissionsAPILeaderboard?, "invalid"?
