local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addDropdownOption = UI.addDropdownOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "ESP Tracer Lines", 440, 50, true, S.ESPTracers, function(v) S.ESPTracers = v; saveConfig() end, function(drawer) addDropdownOption(drawer, "ESP Tracer Origin", {"Bottom", "Center", "Top"}, table.find({"Bottom", "Center", "Top"}, S.TracerOrigin) or 1, function(_, opt) S.TracerOrigin = opt; saveConfig() end) end, false)
