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
local isLoading = false

local function syncModuleState(active)
    S.MusicPlayerActive = active
    if UI.moduleButtons and UI.moduleButtons["Music Player"] then
        pcall(function()
            UI.moduleButtons["Music Player"].SetActive(active)
        end)
    end
    saveConfig()
end

local function findMusicGui()
    local xp = type(getgenv) == "function" and getgenv().xzypPlayer or nil
    if xp and xp.Gui and xp.Gui.Parent then
        return xp.Gui
    end
    local containers = {}
    pcall(function()
        if type(gethui) == "function" then table.insert(containers, gethui()) end
        if type(get_hidden_gui) == "function" then table.insert(containers, get_hidden_gui()) end
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

local function getMusicSound()
    local xp = type(getgenv) == "function" and getgenv().xzypPlayer or nil
    if xp and xp.Sound and xp.Sound.Parent then
        return xp.Sound
    end
    local soundSvc = Services.SoundService or game:GetService("SoundService")
    return soundSvc:FindFirstChild("xzypAudio")
end

local function hookPlayerGui(gui)
    if not gui or gui:GetAttribute("VH_Hooked") then return end
    gui:SetAttribute("VH_Hooked", true)
    gui:GetPropertyChangedSignal("Enabled"):Connect(function()
        if gui.Parent then
            syncModuleState(gui.Enabled)
        end
    end)
    gui.AncestryChanged:Connect(function(_, parent)
        if not parent then
            if type(getgenv) == "function" then
                getgenv().xzypPlayer = nil
            end
            syncModuleState(false)
        end
    end)
end

local function unloadPlayer()
    pcall(function()
        local sound = getMusicSound()
        if sound then
            sound:Stop()
            sound:Destroy()
        end
        local gui = findMusicGui()
        if gui then
            gui:Destroy()
        end
        if type(getgenv) == "function" then
            getgenv().xzypPlayer = nil
        end
    end)
    syncModuleState(false)
end

local function runMusicPlayer()
    if isLoading then return end
    local existing = findMusicGui()
    if existing then
        existing.Enabled = true
        hookPlayerGui(existing)
        return
    end

    isLoading = true
    task.spawn(function()
        local code = nil
        pcall(function()
            if type(isfile) == "function" and type(readfile) == "function" then
                local localPaths = {
                    "MusicPlayer.lua",
                    "musicplayer.lua",
                    "xzyp/musicplayer.lua",
                    "xzyp/System/musicplayer.lua",
                }
                for _, p in ipairs(localPaths) do
                    if isfile(p) then
                        code = readfile(p)
                        if code and code ~= "" then break end
                    end
                end
            end
        end)

        if not code or code == "" then
            pcall(function()
                code = game:HttpGet(musicPlayerUrl, true)
            end)
        end

        if code and code ~= "" and type(loadstring) == "function" then
            local fn, err = loadstring(code)
            if fn then
                local ok, runErr = pcall(fn)
                if ok then
                    task.defer(function()
                        local gui = findMusicGui()
                        if gui then
                            gui.Enabled = S.MusicPlayerActive ~= false
                            hookPlayerGui(gui)
                        end
                    end)
                else
                    syncModuleState(false)
                    notify("Music Player run error: " .. tostring(runErr), Color3.fromRGB(245, 95, 105))
                end
            else
                syncModuleState(false)
                notify("Music Player parse error: " .. tostring(err), Color3.fromRGB(245, 95, 105))
            end
        else
            syncModuleState(false)
            notify("Could not load Music Player source!", Color3.fromRGB(245, 95, 105))
        end

        isLoading = false
    end)
end

registerModule("Misc", "Music Player", 720, 50, true, S.MusicPlayerActive, function(v)
    S.MusicPlayerActive = v
    local gui = findMusicGui()
    if v then
        if gui then
            gui.Enabled = true
            hookPlayerGui(gui)
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
            hookPlayerGui(gui)
            syncModuleState(gui.Enabled)
        else
            syncModuleState(true)
            runMusicPlayer()
        end
    end)

    addButtonOption(drawer, "Stop Audio", function()
        pcall(function()
            local sound = getMusicSound()
            if sound then sound:Stop() end
        end)
    end)

    addButtonOption(drawer, "Reload Player", function()
        unloadPlayer()
        task.wait(0.1)
        syncModuleState(true)
        runMusicPlayer()
    end)

    addButtonOption(drawer, "Unload Player", function()
        unloadPlayer()
    end)
end, false)

if S.MusicPlayerActive then
    runMusicPlayer()
end
