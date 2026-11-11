local _, ns = ...

-- The game refuses to load this addon when ForeverCore is absent (## Dependencies), but an older ForeverCore still
-- loads. Every ForeverCore member this addon calls that arrived after API 1 is checked here, so an out-of-date core
-- stops the addon's own files at this point and the shared warning says which addon to update. The stop is a missing
-- member, never a version comparison.
--
-- APIKit arrived in ForeverCore 1.1.0 and ProfessionTabs in 1.4.0. APIKit.Publish arrived in 1.3.0, but Core/API.lua
-- calls it only when the kit advertises minor 2, so an older kit without it still runs the rest of the addon.
local ready = ForeverCore ~= nil and ForeverCore.APIKit ~= nil and ForeverCore.ProfessionTabs ~= nil

ns.ForeverRequire(ready)
