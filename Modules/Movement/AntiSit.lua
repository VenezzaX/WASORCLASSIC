local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local getHum = Utils.getHum
local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Movement", "Anti-Sit", 300, 50, true, S.AntiSit, function(v) S.AntiSit = v; if v then local hum = getHum(); if hum then hum.Sit = false end end; saveConfig() end)
