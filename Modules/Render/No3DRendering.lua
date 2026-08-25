local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local registerModule = UI.registerModule
local addToggleOption = UI.addToggleOption
local addTextboxOption = UI.addTextboxOption
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

    addTextboxOption(drawer, "Custom Cover ID (e.g. 6723684726)", S.No3DRenderCustomCover or "", function(txt)
        S.No3DRenderCustomCover = txt
        if S.No3DRender and Utils.toggleNo3DRenderCover then
            Utils.toggleNo3DRenderCover(true)
        end
        saveConfig()
    end)
end, false)
