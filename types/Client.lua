---@meta

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
-- Frames Escape closes, by name.
---@type string[]
UISpecialFrames = {}

-- Blizzard_Professions is loaded on demand by the client's trade-skill call.
---@class CommissionsSideTab : Frame
---@field SetChecked fun(self: CommissionsSideTab, checked: boolean)
---@class CommissionsProfessionsFrame : Frame
---@field CraftingPage Frame
---@field BookPage Frame
---@field ProfessionsOverviewTab CommissionsSideTab
---@field rightProfessionTabs CommissionsSideTab[]
---@type CommissionsProfessionsFrame
ProfessionsFrame = nil

-- Core/LeaderboardsData.lua reads the client's weekly reset countdown when it has one.
---@type {GetSecondsUntilWeeklyReset: fun(): number?}
C_DateAndTime = nil

-- UI/Leaderboards.lua publishes the one window every Forever addon registers into.
---@type ForeverLeaderboardsAPI?
ForeverLeaderboards = nil

-- UI/Leaderboards.lua: the client's scroll-box list and its class colour table.
---@type fun(entries?: any[]): any
CreateDataProvider = nil
---@type fun(top?: number, bottom?: number, left?: number, right?: number, spacing?: number): any
CreateScrollBoxListLinearView = nil
---@type {InitScrollBoxListWithScrollBar: fun(scrollBox: Frame, scrollBar: any, view: any)}
ScrollUtil = nil
---@class CommissionsScrollBoxConstants
---@field RetainScrollPosition integer
---@type CommissionsScrollBoxConstants
ScrollBoxConstants = nil
---@class CommissionsClassColor
---@field GetRGB fun(self: CommissionsClassColor): number, number, number
---@type table<string, CommissionsClassColor>?
RAID_CLASS_COLORS = nil
