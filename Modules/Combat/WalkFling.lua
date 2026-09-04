local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local moduleButtons = UI.moduleButtons

local getHRP = Utils.getHRP
local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Walk Fling", 20, 50, true, S.WalkFling, function(v)
    S.WalkFling = v
    if v then
        S.FlingActive = false
        S.FlingAllActive = false
        S.FlingTarget = nil
        local modPlayer = moduleButtons and moduleButtons["Fling Player"]
        if modPlayer and modPlayer.SetActive then modPlayer.SetActive(false) end
        local modAll = moduleButtons and moduleButtons["Fling All"]
        if modAll and modAll.SetActive then modAll.SetActive(false) end
    else
        task.spawn(function()
            local hrp = getHRP()
            if hrp then
                hrp.AssemblyLinearVelocity = Vector3.zero
                hrp.AssemblyAngularVelocity = Vector3.zero
            end
        end)
    end
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Fling Noclip", S.FlingNoclip ~= false, function(v)
        S.FlingNoclip = v
        saveConfig()
    end)
end, false)
