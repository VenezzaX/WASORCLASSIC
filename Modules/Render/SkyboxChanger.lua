local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Lighting = Services.Lighting
local HttpService = Services.HttpService
local registerModule = UI.registerModule
local saveConfig = VH.Config.saveConfig
local notify = Utils.notify

local requestFunc = (syn and syn.request) or (http and http.request) or http_request or request
local getCustomAsset = getcustomasset or getsynasset

local activeLoop = nil
local originalSky = nil

local function cleanupSky()
    if activeLoop then
        pcall(function() task.cancel(activeLoop) end)
        activeLoop = nil
    end
    local customSky = Lighting:FindFirstChild("CustomExecutorSky")
    if customSky then
        pcall(function() customSky:Destroy() end)
    end
end

local function resolveTexture(input)
    input = tostring(input or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if input == "" then return "" end

    if tonumber(input) then
        return "rbxassetid://" .. input
    end

    if input:find("rbxassetid://") or input:find("rbxasset://") then
        return input
    end

    if input:find("^http://") or input:find("^https://") then
        if not requestFunc or not getCustomAsset or not writefile then
            notify("Skybox Changer: Missing HTTP/writefile executor functions", Color3.fromRGB(218, 38, 38))
            return ""
        end

        local filename = "sky_cache_" .. math.floor(tick()) .. ".png"
        local success, response = pcall(function()
            return requestFunc({
                Url = input,
                Method = "GET"
            })
        end)

        if success and response and response.StatusCode == 200 then
            pcall(function() writefile(filename, response.Body) end)
            local ok, asset = pcall(function() return getCustomAsset(filename) end)
            if ok and asset then
                return asset
            end
        else
            notify("Skybox Changer: Failed to download texture from URL", Color3.fromRGB(218, 38, 38))
            return ""
        end
    end

    return input
end

local function setStaticSkybox(assetUri)
    cleanupSky()
    local resolved = resolveTexture(assetUri)
    if resolved == "" then return end

    local sky = Instance.new("Sky")
    sky.Name = "CustomExecutorSky"
    sky.SkyboxBk = resolved
    sky.SkyboxDn = resolved
    sky.SkyboxFt = resolved
    sky.SkyboxLf = resolved
    sky.SkyboxRt = resolved
    sky.SkyboxUp = resolved
    sky.Parent = Lighting
    notify("Skybox applied successfully!", Color3.fromRGB(50, 195, 75))
end

local function setVariousSkybox()
    cleanupSky()
    local defaultTex = resolveTexture(S.SkyboxAsset)

    local ft = resolveTexture(S.SkyboxFt ~= "" and S.SkyboxFt or S.SkyboxAsset)
    local bk = resolveTexture(S.SkyboxBk ~= "" and S.SkyboxBk or S.SkyboxAsset)
    local lf = resolveTexture(S.SkyboxLf ~= "" and S.SkyboxLf or S.SkyboxAsset)
    local rt = resolveTexture(S.SkyboxRt ~= "" and S.SkyboxRt or S.SkyboxAsset)
    local up = resolveTexture(S.SkyboxUp ~= "" and S.SkyboxUp or S.SkyboxAsset)
    local dn = resolveTexture(S.SkyboxDn ~= "" and S.SkyboxDn or S.SkyboxAsset)

    if ft == "" and bk == "" and lf == "" and rt == "" and up == "" and dn == "" then
        notify("Skybox Changer: Please enter at least one valid face texture", Color3.fromRGB(218, 170, 42))
        return
    end

    local sky = Instance.new("Sky")
    sky.Name = "CustomExecutorSky"
    sky.SkyboxFt = ft ~= "" and ft or defaultTex
    sky.SkyboxBk = bk ~= "" and bk or defaultTex
    sky.SkyboxLf = lf ~= "" and lf or defaultTex
    sky.SkyboxRt = rt ~= "" and rt or defaultTex
    sky.SkyboxUp = up ~= "" and up or defaultTex
    sky.SkyboxDn = dn ~= "" and dn or defaultTex
    sky.Parent = Lighting
    notify("Various Skybox faces applied successfully!", Color3.fromRGB(50, 195, 75))
end

local function setAnimatedSkybox(frameList, fps)
    cleanupSky()
    fps = math.clamp(tonumber(fps) or 15, 1, 60)
    local delayTime = 1 / fps
    local resolvedFrames = {}

    for _, frame in ipairs(frameList) do
        local resolved = resolveTexture(frame)
        if resolved ~= "" then
            table.insert(resolvedFrames, resolved)
        end
    end

    if #resolvedFrames == 0 then
        notify("Skybox Changer: No valid frames found", Color3.fromRGB(218, 38, 38))
        return
    end

    local sky = Instance.new("Sky")
    sky.Name = "CustomExecutorSky"
    sky.Parent = Lighting

    local faces = {
        "SkyboxBk", "SkyboxDn", "SkyboxFt",
        "SkyboxLf", "SkyboxRt", "SkyboxUp"
    }

    activeLoop = task.spawn(function()
        local index = 1
        local total = #resolvedFrames
        while true do
            local currentAsset = resolvedFrames[index]
            for _, face in ipairs(faces) do
                sky[face] = currentAsset
            end
            index = (index % total) + 1
            task.wait(delayTime)
        end
    end)
    notify("Animated skybox running (" .. #resolvedFrames .. " frames @ " .. fps .. " FPS)", Color3.fromRGB(50, 195, 75))
end

local function applyCurrentInput()
    if S.SkyboxMode == "Various" then
        setVariousSkybox()
        return
    end

    local text = tostring(S.SkyboxAsset or ""):gsub("^%s+", ""):gsub("%s+$", "")
    if text == "" then
        notify("Skybox Changer: Please enter an Asset ID, URL, or JSON array", Color3.fromRGB(218, 170, 42))
        return
    end

    if text:sub(1, 1) == "[" and text:sub(-1, -1) == "]" then
        local success, frames = pcall(function()
            return HttpService:JSONDecode(text)
        end)
        if success and type(frames) == "table" then
            setAnimatedSkybox(frames, S.SkyboxFPS or 15)
            return
        end
    end

    setStaticSkybox(text)
end

registerModule("Render", "Skybox Changer", 665, 50, true, S.SkyboxChangerActive, function(v)
    S.SkyboxChangerActive = v
    if v then
        applyCurrentInput()
    else
        cleanupSky()
        notify("Skybox reset to default", Color3.fromRGB(218, 170, 42))
    end
    saveConfig()
end, function(drawer)
    local modeOptions = {"All the Same", "Various (Individual Sides)"}
    local defaultModeIdx = (S.SkyboxMode == "Various") and 2 or 1
    UI.addDropdownOption(drawer, "Skybox Mode", modeOptions, defaultModeIdx, function(_, opt)
        S.SkyboxMode = opt:find("Various") and "Various" or "All Same"
        saveConfig()
        if S.SkyboxChangerActive then
            applyCurrentInput()
        end
    end)

    local tb = UI.addTextboxOption(drawer, "All Sides Texture / Fallback", "ID, image URL, or [frames]", function(txt)
        S.SkyboxAsset = txt
        saveConfig()
    end)
    tb.Set(S.SkyboxAsset or "")

    UI.addSectionHeader(drawer, "Various Sides (Front, Back, etc.)")

    local tbFt = UI.addTextboxOption(drawer, "Front Face (Ft)", "Asset ID or Image URL", function(txt)
        S.SkyboxFt = txt
        saveConfig()
    end)
    tbFt.Set(S.SkyboxFt or "")

    local tbBk = UI.addTextboxOption(drawer, "Back Face (Bk)", "Asset ID or Image URL", function(txt)
        S.SkyboxBk = txt
        saveConfig()
    end)
    tbBk.Set(S.SkyboxBk or "")

    local tbLf = UI.addTextboxOption(drawer, "Left Face (Lf)", "Asset ID or Image URL", function(txt)
        S.SkyboxLf = txt
        saveConfig()
    end)
    tbLf.Set(S.SkyboxLf or "")

    local tbRt = UI.addTextboxOption(drawer, "Right Face (Rt)", "Asset ID or Image URL", function(txt)
        S.SkyboxRt = txt
        saveConfig()
    end)
    tbRt.Set(S.SkyboxRt or "")

    local tbUp = UI.addTextboxOption(drawer, "Up Face (Top)", "Asset ID or Image URL", function(txt)
        S.SkyboxUp = txt
        saveConfig()
    end)
    tbUp.Set(S.SkyboxUp or "")

    local tbDn = UI.addTextboxOption(drawer, "Down Face (Bottom)", "Asset ID or Image URL", function(txt)
        S.SkyboxDn = txt
        saveConfig()
    end)
    tbDn.Set(S.SkyboxDn or "")

    UI.addSliderOption(drawer, "Animation FPS", 1, 60, S.SkyboxFPS or 15, function(v)
        S.SkyboxFPS = v
        saveConfig()
        if S.SkyboxChangerActive and activeLoop then
            applyCurrentInput()
        end
    end)

    UI.addButtonOption(drawer, "Apply Skybox", function()
        S.SkyboxChangerActive = true
        local mod = UI.moduleButtons["Skybox Changer"]
        if mod and mod.SetActive then mod.SetActive(true) else applyCurrentInput() end
    end)

    UI.addButtonOption(drawer, "Reset to Default", function()
        cleanupSky()
        S.SkyboxChangerActive = false
        local mod = UI.moduleButtons["Skybox Changer"]
        if mod and mod.SetActive then mod.SetActive(false) end
        notify("Skybox reset", Color3.fromRGB(218, 170, 42))
    end)

    UI.addSectionHeader(drawer, "Popular Presets")
    UI.addButtonOption(drawer, "Preset: Purple Nebula", function()
        S.SkyboxMode = "All Same"
        S.SkyboxAsset = "rbxassetid://159454299"
        tb.Set(S.SkyboxAsset)
        saveConfig()
        S.SkyboxChangerActive = true
        local mod = UI.moduleButtons["Skybox Changer"]
        if mod and mod.SetActive then mod.SetActive(true) else applyCurrentInput() end
    end)

    UI.addButtonOption(drawer, "Preset: Deep Space & Stars", function()
        S.SkyboxMode = "All Same"
        S.SkyboxAsset = "rbxassetid://6444884337"
        tb.Set(S.SkyboxAsset)
        saveConfig()
        S.SkyboxChangerActive = true
        local mod = UI.moduleButtons["Skybox Changer"]
        if mod and mod.SetActive then mod.SetActive(true) else applyCurrentInput() end
    end)

    UI.addButtonOption(drawer, "Preset: Aesthetic Sunset", function()
        S.SkyboxMode = "All Same"
        S.SkyboxAsset = "rbxassetid://266070138"
        tb.Set(S.SkyboxAsset)
        saveConfig()
        S.SkyboxChangerActive = true
        local mod = UI.moduleButtons["Skybox Changer"]
        if mod and mod.SetActive then mod.SetActive(true) else applyCurrentInput() end
    end)
end, false)

