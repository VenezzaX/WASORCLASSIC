local VH = _G.VoidHub or {}
local Config = {}

local Services = VH.Services or {
    HttpService = game:GetService("HttpService")
}
local State = VH.State or {}

Config.saveFavorites = function()
    pcall(function()
        if writefile and State.S then
            writefile("utility_hub_favorites.json", Services.HttpService:JSONEncode(State.S.FavoriteMaps or {}))
        end
    end)
end

Config.loadFavorites = function()
    pcall(function()
        if readfile and isfile and isfile("utility_hub_favorites.json") and State.S then
            local data = readfile("utility_hub_favorites.json")
            State.S.FavoriteMaps = Services.HttpService:JSONDecode(data) or {}
        end
    end)
end

Config.saveConfig = function()
    pcall(function()
        if writefile and State.S then
            local configData = {}
            for k, v in pairs(State.S) do
                if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                    configData[k] = v
                elseif type(v) == "table" and (k == "DisabledModules" or k == "ModuleBinds") then
                    configData[k] = v
                elseif typeof(v) == "EnumItem" then
                    configData[k] = {__type = "EnumItem", Value = tostring(v)}
                end
            end
            writefile("utility_hub_config.json", Services.HttpService:JSONEncode(configData))
        end
    end)
end

Config.resetTogglesForTeleport = function()
    local S = State.S
    if not S then return end
    if S.SaveConfigBetweenTeleports ~= true then
        S.Fly = false; S.NoClip = false; S.BHop = false; S.AirWalk = false; S.GhostMode = false
        S.Float = false; S.WaterWalk = false; S.TallAnim = false; S.Spin = false; S.GravityEnabled = false
        S.GodMode = false; S.KillAura = false; S.AutoClicker = false; S.FlingActive = false; S.FlingAllActive = false; S.WalkFling = false
        S.FollowActive = false; S.AntiAnchor = false; S.No3DRender = false; S.ClickTeleport = false; S.SprintEnabled = false
        S.GraphicsReducer = false; S.ForceWalkSpeed = false; S.ForceJumpPower = false; S.Climb = false
        S.AimbotActive = false; S.AimlockActive = false; S.SilentAim = false; S.TriggerbotActive = false; S.AutoplayBot = false; S.TouchAura = false
        S.WallRun = false; S.WallWalk = false; S.FlyBypass = false; S.PathfindingWalk = false
        S.MinimapActive = false; S.OutOfViewIndicators = false; S.ESPPreviewActive = false
        S.ClickDelete = false; S.CameraMaxZoomEnabled = false
    end
end

Config.loadConfig = function()
    pcall(function()
        if readfile and isfile and isfile("utility_hub_config.json") then
            local data = readfile("utility_hub_config.json")
            local configData = Services.HttpService:JSONDecode(data)
            if configData and State.S then
                for k, v in pairs(configData) do
                    if type(v) == "table" and v.__type == "EnumItem" then
                        local enumType, enumName = v.Value:match("^Enum%.([^%.]+)%.([^%.]+)$")
                        if enumType and enumName and Enum[enumType] and Enum[enumType][enumName] then
                            State.S[k] = Enum[enumType][enumName]
                        end
                    else
                        State.S[k] = v
                    end
                end
                if VH.UI and VH.UI.updateAllModuleVisuals then
                    pcall(VH.UI.updateAllModuleVisuals)
                end
            end
        end
    end)

    local S = State.S or {}
    pcall(function()
        if setfpscap and S.FPSCap then
            setfpscap(S.FPSCap)
        end
    end)
end

Config.loadConfig()
Config.loadFavorites()

VH.Config = Config
return Config