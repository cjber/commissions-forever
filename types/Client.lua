---@meta

-- Core/ForeverRequire.lua, copied byte for byte from ForeverCore, collects pcall's results into one table and reads a
-- dependency name from it. LuaLS types that table from pcall's first result only, so the shared file needs pcall typed
-- as one value here. At runtime pcall still returns its truthy status and the call's results; this only widens what the
-- table constructor sees.
---@param f function
---@param ... any
---@return any
function pcall(f, ...) end

-- FrameXML globals absent from Ketho's pinned Core and FrameXML annotations.
-- These declarations never load in the client.
---@type table<string, fun(msg: string)>
SlashCmdList = {}
---@type MessageFrame
DEFAULT_CHAT_FRAME = nil
-- UI/Window.lua tells the player in combat through the client's error frame.
---@class CommissionsErrorFrame : Frame
---@field AddMessage fun(self: CommissionsErrorFrame, message: string, red?: number, green?: number, blue?: number, alpha?: number, holdTime?: number)
---@type CommissionsErrorFrame
UIErrorsFrame = nil

-- Blizzard_Professions is loaded on demand by the client's trade-skill call.
---@class CommissionsSideTab : Frame
---@field OnClick fun(self: CommissionsSideTab)
---@field SetChecked fun(self: CommissionsSideTab, checked: boolean)
---@class CommissionsProfessionsFrame : Frame
---@field CraftingPage Frame
---@field BookPage Frame
---@field ProfessionsOverviewTab CommissionsSideTab
---@field rightProfessionTabs CommissionsSideTab[]
---@type CommissionsProfessionsFrame
ProfessionsFrame = nil
