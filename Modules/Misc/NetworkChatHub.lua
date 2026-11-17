local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI

local LP = Services.LP

local registerModule = UI.registerModule

local saveConfig = VH.Config.saveConfig

local function launchChatHub()
    if _G.ChatHub_Loaded and _G.ChatHub_SetVisible then
        _G.ChatHub_SetVisible(true)
        return
    end
    local loaded = false
    if isfile and readfile and loadstring then
        local candidates = {
            "Chathub.lua",
            "WASOR/Chathub.lua",
            "WASORCLASSIC/Chathub.lua",
            "chatroom_cache.lua"
        }
        for _, path in ipairs(candidates) do
            if isfile(path) then
                local code = readfile(path)
                if code and #code > 100 then
                    local fn = loadstring(code, path)
                    if fn then
                        task.spawn(fn)
                        loaded = true
                        break
                    end
                end
            end
        end
    end
    if not loaded then
        task.spawn(function()
            local success, remoteCode = pcall(function()
                return game:HttpGet("https://raw.githubusercontent.com/VenezzaX/detection.lua/refs/heads/main/sigma.lua", true)
            end)
            if success and remoteCode and #remoteCode > 100 then
                pcall(function()
                    if writefile then
                        writefile("chatroom_cache.lua", remoteCode)
                    end
                end)
                local fn = loadstring(remoteCode, "sigma.lua")
                if fn then
                    task.spawn(fn)
                end
            end
        end)
    else
        task.spawn(function()
            pcall(function()
                local remoteCode = game:HttpGet("https://raw.githubusercontent.com/VenezzaX/detection.lua/refs/heads/main/sigma.lua", true)
                if remoteCode and #remoteCode > 100 and writefile then
                    writefile("chatroom_cache.lua", remoteCode)
                end
            end)
        end)
    end
end

VH.launchNetworkChatHub = launchChatHub

registerModule("Misc", "Network Chat Hub", 720, 50, true, S.NetworkChat, function(v)
    S.NetworkChat = v
    if v then
        if _G.ChatHub_Loaded and _G.ChatHub_SetVisible then
            _G.ChatHub_SetVisible(true)
        else
            task.spawn(function()
                pcall(launchChatHub)
            end)
        end
    else
        if _G.ChatHub_SetVisible then
            _G.ChatHub_SetVisible(false)
        else
            local CoreGui = game:GetService("CoreGui")
            local oldChat = CoreGui:FindFirstChild("DiscordNetworkHub") or CoreGui:FindFirstChild("ChatRoom")
            if oldChat then
                local mw = oldChat:FindFirstChild("MainWindow")
                if mw then mw.Visible = false else oldChat:Destroy() end
            end
            local pg = LP:WaitForChild("PlayerGui", 2)
            if pg then
                local oldChatPg = pg:FindFirstChild("DiscordNetworkHub") or pg:FindFirstChild("ChatRoom")
                if oldChatPg then
                    local mw = oldChatPg:FindFirstChild("MainWindow")
                    if mw then mw.Visible = false else oldChatPg:Destroy() end
                end
            end
        end
    end
    saveConfig()
end)
