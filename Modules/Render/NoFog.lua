local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local toggleNoFog = Utils.toggleNoFog or Utils.toggleClearVision

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Render", "No Fog", 440, 50, true, S.NoFog or S.ClearVision, function(v)
    S.NoFog = v
    S.ClearVision = v
    toggleNoFog(v)
    saveConfig()
end)
