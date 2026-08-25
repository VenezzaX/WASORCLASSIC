local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local moduleButtons = UI.moduleButtons

local getHRP = Utils.getHRP
local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Fling All", 20, 50, true, S.FlingAllActive, function(v)
    S.FlingAllActive = v
    if v then S.FlingActive = false; local mod = moduleButtons["Fling Player"]; if mod then mod.SetActive(false) end
    else
        flingAllTarget = nil
        task.spawn(function() local hrp = getHRP(); if hrp then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; if S.LastSafePosition then hrp.CFrame = S.LastSafePosition end; task.wait(0.05); if hrp:IsDescendantOf(game) then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end end end)
    end
    saveConfig()
end, nil, false)
