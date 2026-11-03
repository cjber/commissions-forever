---@meta

-- FrameXML globals absent from Ketho's pinned Core and FrameXML annotations.
-- These declarations never load in the client.
---@type table<string, fun(msg: string)>
SlashCmdList = {}
---@type MessageFrame
DEFAULT_CHAT_FRAME = nil
-- Frames Escape closes, by name.
---@type string[]
UISpecialFrames = {}

-- Blizzard_Professions is loaded on demand by ShowProfessionsFrame.
---@class CommissionsSideTab : Frame
---@field SetChecked fun(self: CommissionsSideTab, checked: boolean)
---@class CommissionsProfessionsFrame : Frame
---@field SelectBookPage fun(self: CommissionsProfessionsFrame)
---@field CraftingPage Frame
---@field BookPage Frame
---@field ProfessionsOverviewTab CommissionsSideTab
---@field rightProfessionTabs CommissionsSideTab[]
---@type CommissionsProfessionsFrame
ProfessionsFrame = nil

function ShowProfessionsFrame() end
