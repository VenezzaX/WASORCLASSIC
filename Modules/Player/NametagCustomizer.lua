local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local updateLocalNametag = Utils.updateLocalNametag

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addTextboxOption = UI.addTextboxOption

local saveConfig = VH.Config.saveConfig

registerModule("Player", "Nametag Customizer", 160, 50, true, S.CustomNametag, function(v) S.CustomNametag = v; updateLocalNametag(); saveConfig() end, function(drawer)
    addToggleOption(drawer, "Hide All Player Nametags", S.HideNametags, function(v) S.HideNametags = v; saveConfig() end)
    addTextboxOption(drawer, "Custom Nametag Text", S.CustomNametagText or "WeAreSkidding", function(txt) S.CustomNametagText = txt; updateLocalNametag(); saveConfig() end)
end, false)
