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
