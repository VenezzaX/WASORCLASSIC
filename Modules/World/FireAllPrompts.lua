local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule
local addTextboxOption = UI.addTextboxOption
local addSliderOption = UI.addSliderOption
local saveConfig = VH.Config.saveConfig

registerModule("World", "Fire All Prompts", 580, 50, false, false, function()
    local count = 0
    local myHRP = Utils.getHRP()
    local filter = (S.FirePromptsFilter or ""):lower()
    local maxDist = S.FirePromptsDistance or 500
    
    for _, p in ipairs(workspace:GetDescendants()) do
        if p:IsA("ProximityPrompt") then
            local matches = (filter == "") or p.Name:lower():find(filter, 1, true) or (p.Parent and p.Parent.Name:lower():find(filter, 1, true))
            if matches then
                if myHRP and p.Parent and p.Parent:IsA("BasePart") then
                    local dist = (p.Parent.Position - myHRP.Position).Magnitude
                    if dist > maxDist then continue end
                end
                pcall(function() fireproximityprompt(p) end)
                count = count + 1
            end
        end
    end
    notify(string.format("Fired %d Proximity Prompts!", count), Color3.fromRGB(50, 195, 75))
end, function(drawer)
    local tb = addTextboxOption(drawer, "Name Filter", "chest/door/etc", function(txt) S.FirePromptsFilter = txt; saveConfig() end)
    tb.Set(S.FirePromptsFilter or "")
    addSliderOption(drawer, "Max Distance (studs)", 10, 2000, S.FirePromptsDistance or 500, function(v) S.FirePromptsDistance = v; saveConfig() end)
end, false)
