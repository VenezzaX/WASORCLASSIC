local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHRP = Utils.getHRP
local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Walk Fling", 20, 50, true, S.WalkFling, function(v)
    S.WalkFling = v
    if not v then
        task.spawn(function()
            local hrp = getHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
    saveConfig()
end, nil, false)
