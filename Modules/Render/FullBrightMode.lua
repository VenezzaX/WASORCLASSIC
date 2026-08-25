local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local Lighting = Services.Lighting
local originalAmbient = State.originalAmbient
local originalOutdoor = State.originalOutdoor
local originalClockTime = State.originalClockTime

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "FullBright Mode", 440, 50, true, S.FullBright, function(v) S.FullBright = v; if v then Lighting.Ambient = Color3.new(1, 1, 1); Lighting.OutdoorAmbient = Color3.new(1, 1, 1) else Lighting.Ambient = originalAmbient; Lighting.OutdoorAmbient = originalOutdoor; Lighting.ClockTime = originalClockTime or 14 end; saveConfig() end)
