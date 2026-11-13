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
                if isfile and isfile("Chathub.lua") and readfile and loadstring then
                    loadstring(readfile("Chathub.lua"))()
                else
                    loadstring(game:HttpGet(('https://raw.githubusercontent.com/VenezzaX/detection.lua/refs/heads/main/sigma.lua'),true))()
                end
            end)
        end)
    else
        if _G.ChatHub_Cleanup then
            pcall(_G.ChatHub_Cleanup)
        end
        local oldChat = game:GetService("CoreGui"):FindFirstChild("DiscordNetworkHub") or game:GetService("CoreGui"):FindFirstChild("ChatRoom")
        if oldChat then oldChat:Destroy() end
        local pg = LP:WaitForChild("PlayerGui", 2)
        if pg then
            local oldChatPg = pg:FindFirstChild("DiscordNetworkHub") or pg:FindFirstChild("ChatRoom")
            if oldChatPg then oldChatPg:Destroy() end
        end
    end
    saveConfig()
end)
