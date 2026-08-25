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

registerModule("World", "Fire CD Detectors", 580, 50, false, false, function()
    local count = 0
    local myHRP = Utils.getHRP()
    local filter = (S.FireCDFilter or ""):lower()
    local maxDist = S.FireCDDistance or 500
    
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ClickDetector") then
            local matches = (filter == "") or obj.Name:lower():find(filter, 1, true) or (obj.Parent and obj.Parent.Name:lower():find(filter, 1, true))
            if matches then
                if myHRP and obj.Parent and obj.Parent:IsA("BasePart") then
                    local dist = (obj.Parent.Position - myHRP.Position).Magnitude
                    if dist > maxDist then continue end
                end
                pcall(function() fireclickdetector(obj) end)
                count = count + 1
            end
        end
    end
    notify(string.format("Fired %d ClickDetectors!", count), Color3.fromRGB(50, 195, 75))
end, function(drawer)
    local tb = addTextboxOption(drawer, "Name Filter", "button/lever/etc", function(txt) S.FireCDFilter = txt; saveConfig() end)
    tb.Set(S.FireCDFilter or "")
    addSliderOption(drawer, "Max Distance (studs)", 10, 2000, S.FireCDDistance or 500, function(v) S.FireCDDistance = v; saveConfig() end)
end, false)
