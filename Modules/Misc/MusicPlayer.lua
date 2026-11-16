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
local cachePath = "xzyp/System/musicplayer.lua"
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

local function getGuiContainers()
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
    return containers
end

local function findMusicGui()
    local xp = type(getgenv) == "function" and getgenv().xzypPlayer or nil
    if xp and xp.Gui and xp.Gui.Parent then
        return xp.Gui
    end
    for _, c in ipairs(getGuiContainers()) do
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

local function purgeLegacyFilesAndGuis(includeCurrent)
    pcall(function()
        if type(isfile) == "function" and type(delfile) == "function" then
            local staleFiles = {
                "MusicPlayer.lua",
                "musicplayer.lua",
                "xzyp/MusicPlayer.lua",
                "xzyp/musicplayer.lua",
            }
            for _, f in ipairs(staleFiles) do
                if isfile(f) then
                    delfile(f)
                end
            end
        end
    end)

    local legacyNames = { "Orbitune", "OrbituneWidget", "OrbituneClientPlayer" }
    for _, c in ipairs(getGuiContainers()) do
        for _, name in ipairs(legacyNames) do
            local old = c:FindFirstChild(name)
            if old then old:Destroy() end
        end
        if includeCurrent then
            local cur = c:FindFirstChild("xzypMusicPlayer")
            if cur then cur:Destroy() end
        end
    end

    local soundSvc = Services.SoundService or game:GetService("SoundService")
    local oldSound = soundSvc:FindFirstChild("OrbituneAudio")
    if oldSound then oldSound:Destroy() end
    if includeCurrent then
        local curSound = soundSvc:FindFirstChild("xzypAudio")
        if curSound then
            curSound:Stop()
            curSound:Destroy()
        end
    end
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
    purgeLegacyFilesAndGuis(true)
    if type(getgenv) == "function" then
        getgenv().xzypPlayer = nil
    end
    syncModuleState(false)
end

local function fetchLatestSource()
    local bustUrl = musicPlayerUrl .. "?t=" .. tostring(os.time()) .. "_" .. tostring(math.random(1000, 9999))
    local code = nil

    pcall(function()
        code = game:HttpGet(bustUrl, true)
    end)

    if (not code or code == "") then
        local req = (syn and syn.request) or request or http_request or (http and http.request)
        if req then
            pcall(function()
                local res = req({ Url = bustUrl, Method = "GET" })
                if res and res.Body then
                    code = res.Body
                end
            end)
        end
    end

    if code and code:find("xzypPlayer", 1, true) then
        pcall(function()
            if type(isfolder) == "function" and type(makefolder) == "function" then
                if not isfolder("xzyp") then makefolder("xzyp") end
                if not isfolder("xzyp/System") then makefolder("xzyp/System") end
            end
            if type(writefile) == "function" then
                writefile(cachePath, code)
            end
        end)
        return code
    end

    pcall(function()
        if type(isfile) == "function" and type(readfile) == "function" and isfile(cachePath) then
            local cached = readfile(cachePath)
            if cached and cached:find("xzypPlayer", 1, true) then
                code = cached
            end
        end
    end)

    return code
end

local function runMusicPlayer(forceReload)
    if isLoading then return end
    purgeLegacyFilesAndGuis(forceReload == true)

    if not forceReload then
        local existing = findMusicGui()
        if existing then
            existing.Enabled = true
            hookPlayerGui(existing)
            return
        end
    end

    isLoading = true
    task.spawn(function()
        local code = fetchLatestSource()
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
            notify("Could not fetch updated Music Player!", Color3.fromRGB(245, 95, 105))
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
            runMusicPlayer(false)
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
            runMusicPlayer(false)
        end
    end)

    addButtonOption(drawer, "Stop Audio", function()
        pcall(function()
            local sound = getMusicSound()
            if sound then sound:Stop() end
        end)
    end)

    addButtonOption(drawer, "Force Update (GitHub)", function()
        pcall(function()
            if type(isfile) == "function" and type(delfile) == "function" and isfile(cachePath) then
                delfile(cachePath)
            end
        end)
        syncModuleState(true)
        runMusicPlayer(true)
        notify("Reloaded latest xzyp music player from GitHub!", Color3.fromRGB(64, 214, 114))
    end)

    addButtonOption(drawer, "Unload Player", function()
        unloadPlayer()
    end)
end, false)

if S.MusicPlayerActive then
    runMusicPlayer(false)
end