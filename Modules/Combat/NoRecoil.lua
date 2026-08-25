local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule

local addInfoRowOption = UI.addInfoRowOption

local saveConfig = VH.Config.saveConfig

registerModule("Combat", "No Recoil", 20, 50, true, S.NoRecoil, function(v) S.NoRecoil = v; saveConfig() end, function(drawer)
    local warning = addInfoRowOption(drawer, "Status", "BROKEN / DOESN'T WORK")
    warning:SetColor(Color3.fromRGB(255, 50, 50))
end, false)
