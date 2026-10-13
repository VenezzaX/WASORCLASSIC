local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addTextboxOption = UI.addTextboxOption
local addSliderOption = UI.addSliderOption
local saveConfig = VH.Config.saveConfig

registerModule("Render", "No 3D Rendering", 440, 50, true, S.No3DRender, function(v)
    S.No3DRender = v
    if Utils.toggleNo3DRenderCover then
        Utils.toggleNo3DRenderCover(v)
    else
        pcall(function() Services.RunService:Set3dRenderingEnabled(not v) end)
    end
    saveConfig()
end, function(drawer)
    addToggleOption(drawer, "Disable Cover", S.No3DRenderDisableCover or false, function(v)
        S.No3DRenderDisableCover = v
        if S.No3DRender and Utils.toggleNo3DRenderCover then
            Utils.toggleNo3DRenderCover(true)
        end
        saveConfig()
    end)

    addToggleOption(drawer, "Ultra Low Power (Cap FPS)", S.No3DRenderCapFPS ~= false, function(v)
        S.No3DRenderCapFPS = v
        if S.No3DRender and Utils.toggleNo3DRenderCover then
            Utils.toggleNo3DRenderCover(true)
        end
        saveConfig()
    end)

    if addSliderOption then
        addSliderOption(drawer, "Target Idle FPS", 5, 60, S.No3DRenderTargetFPS or 15, function(val)
            S.No3DRenderTargetFPS = val
            if S.No3DRender and S.No3DRenderCapFPS and setfpscap then
                pcall(function() setfpscap(val) end)
            end
            saveConfig()
        end)
    end

    addToggleOption(drawer, "Reduce Quality to Min", S.No3DRenderReduceQuality ~= false, function(v)
        S.No3DRenderReduceQuality = v
        saveConfig()
    end)

    addTextboxOption(drawer, "Custom Cover ID (e.g. 6723684726)", S.No3DRenderCustomCover or "", function(txt)
        S.No3DRenderCustomCover = txt
        if S.No3DRender and Utils.toggleNo3DRenderCover then
            Utils.toggleNo3DRenderCover(true)
        end
        saveConfig()
    end)
end, false)
