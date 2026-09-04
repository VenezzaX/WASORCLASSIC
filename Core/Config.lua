local VH = _G.VoidHub
local Config = {}

local Services = VH.Services
local State = VH.State

Config.saveFavorites = function()
    pcall(function()
        if writefile then
            writefile("utility_hub_favorites.json", Services.HttpService:JSONEncode(State.S.FavoriteMaps))
        end
    end)
end

Config.loadFavorites = function()
    pcall(function()
        if readfile and isfile and isfile("utility_hub_favorites.json") then
            local data = readfile("utility_hub_favorites.json")
            State.S.FavoriteMaps = Services.HttpService:JSONDecode(data) or {}
        end
    end)
end

Config.saveConfig = function()
    pcall(function()
        if writefile then
            local configData = {}
            for k, v in pairs(State.S) do
                if type(v) == "boolean" or type(v) == "number" or type(v) == "string" then
                    configData[k] = v
                elseif typeof(v) == "EnumItem" then
                    configData[k] = {__type = "EnumItem", Value = tostring(v)}
                end
            end
            writefile("utility_hub_config.json", Services.HttpService:JSONEncode(configData))
        end
    end)
end

Config.loadConfig = function()
    pcall(function()
        if readfile and isfile and isfile("utility_hub_config.json") then
            local data = readfile("utility_hub_config.json")
            local configData = Services.HttpService:JSONDecode(data)
            if configData then
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
            end
        end
    end)
    
    local S = State.S
    S.Fly = false; S.NoClip = false; S.BHop = false; S.AirWalk = false; S.GhostMode = false
    S.Float = false; S.WaterWalk = false; S.TallAnim = false; S.Spin = false; S.GravityEnabled = false
    S.GodMode = false; S.KillAura = false; S.AutoClicker = false; S.FlingActive = false; S.FlingAllActive = false; S.WalkFling = false
    S.FollowActive = false; S.AntiAnchor = false; S.No3DRender = false; S.ClickTeleport = false; S.SprintEnabled = false
    S.GraphicsReducer = false; S.ForceWalkSpeed = false; S.ForceJumpPower = false; S.Climb = false
    S.AimbotActive = false; S.AimlockActive = false; S.SilentAim = false; S.TriggerbotActive = false; S.AutoplayBot = false; S.TouchAura = false
    S.WallRun = false; S.FlyBypass = false; S.PathfindingWalk = false
    S.MinimapActive = false; S.OutOfViewIndicators = false; S.ESPPreviewActive = false
    pcall(function()
        if setfpscap then
            setfpscap(S.FPSCap or 144)
        end
    end)
end

Config.loadConfig()
Config.loadFavorites()

VH.Config = Config
return Config
