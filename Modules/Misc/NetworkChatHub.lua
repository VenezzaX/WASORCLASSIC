local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local LP = Services.LP

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

registerModule("Misc", "Network Chat Hub", 720, 50, true, S.NetworkChat, function(v)
    S.NetworkChat = v
    if v then
        task.spawn(function()
            pcall(function()
                loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/detection.lua/refs/heads/main/sigma.lua'),true))()
            end)
        end)
    else
        local oldChat = game:GetService("CoreGui"):FindFirstChild("DiscordNetworkHub")
        if oldChat then oldChat:Destroy() end
        local oldChatPg = LP:WaitForChild("PlayerGui", 2):FindFirstChild("DiscordNetworkHub")
        if oldChatPg then oldChatPg:Destroy() end
    end
    saveConfig()
end)
