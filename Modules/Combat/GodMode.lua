local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local applyGodMode = Utils.applyGodMode
local disableGodMode = Utils.disableGodMode

local LP = Services.LP

local registerModule = UI.registerModule

local addInfoRowOption = UI.addInfoRowOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "God Mode", 20, 50, true, S.GodMode, function(v) S.GodMode = v; if v then if LP.Character then applyGodMode(LP.Character) end else disableGodMode() end; saveConfig() end, function(drawer)
    local warning = addInfoRowOption(drawer, "Status", "SEMI WORKING")
    warning:SetColor(Color3.fromRGB(255, 50, 50))
end, false)
