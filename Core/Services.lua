local VH = _G.VoidHub
local Services = {}

Services.Players            = game:GetService("Players")
Services.RunService         = game:GetService("RunService")
Services.UserInputService   = game:GetService("UserInputService")
Services.HttpService        = game:GetService("HttpService")
Services.TeleportService    = game:GetService("TeleportService")
Services.Workspace          = game:GetService("Workspace")
Services.CoreGui            = game:GetService("CoreGui")
Services.MarketplaceService = game:GetService("MarketplaceService")
Services.Lighting           = game:GetService("Lighting")
Services.VirtualUser        = game:GetService("VirtualUser")
Services.TweenService       = game:GetService("TweenService")
Services.PathfindingService = game:GetService("PathfindingService")

local LP = Services.Players.LocalPlayer
Services.LP = LP

setmetatable(Services, {
    __index = function(t, k)
        if k == "Camera" then
            return Services.Workspace.CurrentCamera or Services.Workspace:FindFirstChildOfClass("Camera")
        elseif k == "LP" then
            local p = rawget(t, "LP")
            if not p then
                p = Services.Players.LocalPlayer
                rawset(t, "LP", p)
            end
            return p or Services.Players.LocalPlayer
        elseif k == "Mouse" then
            local lp = t.LP
            if lp then
                local s, m = pcall(function() return lp:GetMouse() end)
                if s and m then return m end
            end
            return nil
        end
        return rawget(t, k)
    end
})

VH.Services = Services
return Services

