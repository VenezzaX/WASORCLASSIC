local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP
local notify = Utils.notify
local registerModule = UI.registerModule
local addButtonOption = UI.addButtonOption
local saveConfig = VH.Config.saveConfig

local musicPlayerUrl = "https://raw.githubusercontent.com/VenezzaX/xzypmusicplayerfun/refs/heads/main/musicplayer.lua"

local function findMusicGui()
    local containers = {}
    pcall(function()
        if gethui then table.insert(containers, gethui()) end
        if get_hidden_gui then table.insert(containers, get_hidden_gui()) end
        if Services.CoreGui then table.insert(containers, Services.CoreGui) end
        if LP then
            local pg = LP:FindFirstChild("PlayerGui")
            if pg then table.insert(containers, pg) end
        end
    end)
    for _, c in ipairs(containers) do
        local g = c:FindFirstChild("xzypMusicPlayer")
        if g then return g end
    end
    return nil
end

local function runMusicPlayer()
    task.spawn(function()
        local code = nil
        pcall(function()
            if isfile and isfile("MusicPlayer.lua") and readfile then
                code = readfile("MusicPlayer.lua")
            elseif isfile and isfile("xzyp/MusicPlayer.lua") and readfile then
                code = readfile("xzyp/MusicPlayer.lua")
            end
        end)
        if not code or code == "" then
            pcall(function()
                code = game:HttpGet(musicPlayerUrl, true)
            end)
        end
        if code and code ~= "" and loadstring then
            local fn, err = loadstring(code)
            if fn then
                local ok, runErr = pcall(fn)
                if not ok then
                    notify("Music Player run error: " .. tostring(runErr), Color3.fromRGB(245, 95, 105))
                end
            else
                notify("Music Player parse error: " .. tostring(err), Color3.fromRGB(245, 95, 105))
            end
        else
            notify("Could not load Music Player source!", Color3.fromRGB(245, 95, 105))
        end
    end)
end

registerModule("Misc", "Music Player", 720, 50, true, S.MusicPlayerActive, function(v)
    S.MusicPlayerActive = v
    local gui = findMusicGui()
    if v then
        if gui then
            gui.Enabled = true
        else
            runMusicPlayer()
        end
    else
        if gui then
            gui.Enabled = false
        end
    end
    saveConfig()
end, function(drawer)
    addButtonOption(drawer, "Toggle Player UI", function()
        local gui = findMusicGui()
        if gui then
            gui.Enabled = not gui.Enabled
            S.MusicPlayerActive = gui.Enabled
            if UI.moduleButtons and UI.moduleButtons["Music Player"] then
                UI.moduleButtons["Music Player"].SetActive(gui.Enabled)
            end
            saveConfig()
        else
            runMusicPlayer()
            S.MusicPlayerActive = true
            if UI.moduleButtons and UI.moduleButtons["Music Player"] then
                UI.moduleButtons["Music Player"].SetActive(true)
            end
            saveConfig()
        end
    end)

    addButtonOption(drawer, "Stop Audio", function()
        pcall(function()
            local sound = game:GetService("SoundService"):FindFirstChild("xzypAudio")
            if sound then sound:Stop() end
        end)
    end)

    addButtonOption(drawer, "Unload Player", function()
        pcall(function()
            local sound = game:GetService("SoundService"):FindFirstChild("xzypAudio")
            if sound then sound:Destroy() end
            local gui = findMusicGui()
            if gui then gui:Destroy() end
        end)
        S.MusicPlayerActive = false
        if UI.moduleButtons and UI.moduleButtons["Music Player"] then
            UI.moduleButtons["Music Player"].SetActive(false)
        end
        saveConfig()
    end)
end, false)
