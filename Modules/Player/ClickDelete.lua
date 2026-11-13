local VH = _G.VoidHub
local State = VH.State
local S = State.S
local UI = VH.UI

local registerModule = UI.registerModule
local addDropdownOption = UI.addDropdownOption
local saveConfig = VH.Config.saveConfig

registerModule("Player", "Click-Delete", 160, 50, true, S.ClickDelete, function(v)
    S.ClickDelete = v
    saveConfig()
end, function(drawer)
    local comboLabel = Instance.new("TextLabel")
    comboLabel.Size = UDim2.new(1, -8, 0, 28)
    comboLabel.Position = UDim2.new(0, 4, 0, 0)
    comboLabel.BackgroundTransparency = 1
    comboLabel.Font = Enum.Font.GothamMedium
    comboLabel.TextSize = 10
    comboLabel.TextColor3 = Color3.fromRGB(220, 220, 100)
    comboLabel.TextWrapped = true
    comboLabel.TextXAlignment = Enum.TextXAlignment.Left
    comboLabel.Text = "Combo: Hold [Alt] + Left Click on any part to delete it immediately."
    comboLabel.Parent = drawer

    local modifiers = {"LeftAlt", "RightAlt", "LeftControl", "LeftShift"}
    local defaultIdx = table.find(modifiers, S.ClickDeleteModifier or "LeftAlt") or 1
    addDropdownOption(drawer, "Modifier Key", modifiers, defaultIdx, function(idx, opt)
        S.ClickDeleteModifier = opt
        saveConfig()
    end)
end, false)
