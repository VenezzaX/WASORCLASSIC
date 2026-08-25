local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHRP = Utils.getHRP
local getHum = Utils.getHum
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Auto Bunnyhop", 300, 50, true, S.BHop, function(v)
    S.BHop = v
    if not v then
        local hum = getHum()
        if hum then hum.WalkSpeed = (S.ForceWalkSpeed and S.WalkSpeed) or (State.gameDefaultSpeed or hum.WalkSpeed or 16) end
        local hrp = getHRP()
        if hrp then hrp.CustomPhysicalProperties = nil end
    end
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Auto-Strafe (Momentum)", S.BHopAutoStrafe, function(v) S.BHopAutoStrafe = v; saveConfig() end)
end, false)
