local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local toggleGraphicsReducer = Utils.toggleGraphicsReducer

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addSliderOption = UI.addSliderOption

local saveConfig = VH.Config.saveConfig

registerModule("Render", "Lag Reducer", 440, 50, true, S.GraphicsReducer, function(v)
    toggleGraphicsReducer(v)
    saveConfig()
end, function(drawer)
    addSliderOption(drawer, "FPS Limit Cap", 15, 360, S.FPSCap, function(v)
        S.FPSCap = v
        pcall(function() if setfpscap then setfpscap(v) end end)
        saveConfig()
    end)
    addToggleOption(drawer, "Potato Materials (Global)", S.LagReducePotatoMode, function(v)
        S.LagReducePotatoMode = v
        if S.GraphicsReducer then toggleGraphicsReducer(true) end
        saveConfig()
    end)
    addToggleOption(drawer, "Disable Game Shadows", S.LagReduceShadows, function(v)
        S.LagReduceShadows = v
        if S.GraphicsReducer then toggleGraphicsReducer(true) end
        saveConfig()
    end)
    addToggleOption(drawer, "Disable Decals & Textures", S.LagReduceDecals, function(v)
        S.LagReduceDecals = v
        if S.GraphicsReducer then toggleGraphicsReducer(true) end
        saveConfig()
    end)
    addToggleOption(drawer, "Disable Particles & Sparks", S.LagReduceParticles, function(v)
        S.LagReduceParticles = v
        if S.GraphicsReducer then toggleGraphicsReducer(true) end
        saveConfig()
    end)
    addToggleOption(drawer, "Disable Lighting Post-FX", S.LagReduceEffects, function(v)
        S.LagReduceEffects = v
        if S.GraphicsReducer then toggleGraphicsReducer(true) end
        saveConfig()
    end)
end, false)
