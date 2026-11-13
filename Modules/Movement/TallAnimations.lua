local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local applyTallAnimations = Utils.applyTallAnimations
local revertTallAnimations = Utils.revertTallAnimations
local notify = Utils.notify

local LP = Services.LP
local registerModule = UI.registerModule
local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Tall Animations R15", 300, 50, true, S.TallAnim, function(v)
    S.TallAnim = v
    if v and LP.Character then
        local hum = LP.Character:FindFirstChildOfClass("Humanoid")
        if hum and hum.RigType ~= Enum.HumanoidRigType.R15 then
            notify("Tall Animations requires R15 avatar!", Color3.fromRGB(241, 196, 15))
        end
        applyTallAnimations(LP.Character)
    elseif LP.Character then
        revertTallAnimations(LP.Character)
    end
    saveConfig()
end)
