---@meta

-- Optional addons own these APIs; callers test availability before using them.

-- QuestieDB's public contract (version 2). Its tables are read through RequireContract, Meta and GetAll.
---@type table?
LibQuestieDB = nil

-- Shortest Path Forever's public API (version 1): uiMapID and 0-1 coordinates.
---@class CommissionsShortestPathAPI
---@field NavigateRoute? fun(owner: string, stops: {map: integer, x: number, y: number, title?: string}[]): boolean
---@type {API: CommissionsShortestPathAPI?}?
ShortestPathForever = nil

-- SkillUp Forever's public API: the materials a recipe needs for a number of crafts.
---@class CommissionsSkillUpAPI
---@field RequiredMaterials? fun(recipeID: integer, crafts: integer): {itemID: integer, count: number}[]?
---@type {API: CommissionsSkillUpAPI?}?
SkillUpForever = nil
