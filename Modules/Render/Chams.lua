local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local Players = Services.Players
local LP = Services.LP

local registerModule = UI.registerModule

local addDropdownOption = UI.addDropdownOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Chams", 440, 50, true, S.Chams, function(v)
    S.Chams = v
    if not v then for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local hl = p.Character:FindFirstChild("VoidChams"); if hl then hl:Destroy() end end end end
    saveConfig()
end, function(drawer)
    addDropdownOption(drawer, "Chams Color", {"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, table.find({"Team Color", "Red", "Green", "Blue", "Yellow", "Cyan", "White"}, S.ChamsColor) or 1, function(_, opt) S.ChamsColor = opt; saveConfig() end)
end, false)
