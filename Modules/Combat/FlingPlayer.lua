local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local moduleButtons = UI.moduleButtons

local Players = Services.Players
local LP = Services.LP

local getHRP = Utils.getHRP
local notify = Utils.notify
local registerModule = UI.registerModule

local addTextboxOption = UI.addTextboxOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "Fling Player", 20, 50, true, S.FlingActive, function(v)
    S.FlingActive = v
    if v then S.FlingAllActive = false; local mod = moduleButtons["Fling All"]; if mod then mod.SetActive(false) end
    else
        S.FlingTarget = nil
        task.spawn(function() local hrp = getHRP(); if hrp then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero; if S.LastSafePosition then hrp.CFrame = S.LastSafePosition end; task.wait(0.05); if hrp:IsDescendantOf(game) then hrp.AssemblyLinearVelocity = Vector3.zero; hrp.AssemblyAngularVelocity = Vector3.zero end end end)
    end
    saveConfig()
end, function(drawer)
    addTextboxOption(drawer, "Fling Target Player", "Username", function(txt)
        if txt == "" then S.FlingTarget = nil; notify("Fling target cleared", Color3.fromRGB(218, 38, 38)); return end
        local found = nil
        for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and (p.Name:lower():find(txt:lower()) or p.DisplayName:lower():find(txt:lower())) then found = p; break end end
        if found then S.FlingTarget = found; notify("Fling target set to: " .. found.DisplayName, Color3.fromRGB(50, 195, 75))
        else S.FlingTarget = nil; notify("Player not found: " .. txt, Color3.fromRGB(218, 38, 38)) end
    end)
end, false)
