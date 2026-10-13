local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local LP = Services.LP
local processUISpoofText = Utils.processUISpoofText

local registerModule = UI.registerModule
local addTextboxOption = UI.addTextboxOption
local saveConfig = VH.Config.saveConfig

local spoofConns = {}
local sweepTask = nil

local function getSpoofContainers()
    local containers = {}
    pcall(function()
        if gethui then
            local h = gethui()
            if h and not table.find(containers, h) then table.insert(containers, h) end
        end
        if get_hidden_gui then
            local hg = get_hidden_gui()
            if hg and not table.find(containers, hg) then table.insert(containers, hg) end
        end
        local cg = Services.CoreGui or game:GetService("CoreGui")
        if cg and not table.find(containers, cg) then table.insert(containers, cg) end
        local pg = LP:FindFirstChild("PlayerGui") or LP:WaitForChild("PlayerGui", 5)
        if pg and not table.find(containers, pg) then table.insert(containers, pg) end
        local ws = Services.Workspace or game:GetService("Workspace")
        if ws and not table.find(containers, ws) then table.insert(containers, ws) end
    end)
    return containers
end

local function hookObject(obj)
    if not S.RandomizeUIText then return end
    S.UISpoofObjects = S.UISpoofObjects or {}
    if S.UISpoofObjects[obj] then return end

    local isText = false
    pcall(function()
        isText = obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")
    end)
    if not isText then return end

    local txt = ""
    pcall(function() txt = obj.Text end)
    if type(txt) ~= "string" or txt == "" then return end

    local lowerText = string.lower(txt)
    local username = string.lower(LP.Name)
    local displayName = string.lower(LP.DisplayName)

    if string.find(lowerText, username, 1, true) or string.find(lowerText, displayName, 1, true) then
        local data = {}
        pcall(function()
            data.Conn = obj:GetPropertyChangedSignal("Text"):Connect(function()
                if not S.RandomizeUIText or not obj or not obj.Parent then
                    if data.Conn then data.Conn:Disconnect() end
                    if data.DestConn then data.DestConn:Disconnect() end
                    S.UISpoofObjects[obj] = nil
                    return
                end
                processUISpoofText(obj)
            end)
            data.DestConn = obj.AncestryChanged:Connect(function(_, parent)
                if not parent then
                    if data.Conn then data.Conn:Disconnect() end
                    if data.DestConn then data.DestConn:Disconnect() end
                    S.UISpoofObjects[obj] = nil
                end
            end)
        end)
        S.UISpoofObjects[obj] = data
        processUISpoofText(obj)
    end
end

local function scanAllContainers()
    local containers = getSpoofContainers()
    for _, container in ipairs(containers) do
        pcall(function()
            for _, desc in ipairs(container:GetDescendants()) do
                hookObject(desc)
            end
        end)
    end
end

local function clearHooks()
    for _, conn in ipairs(spoofConns) do
        pcall(function() conn:Disconnect() end)
    end
    spoofConns = {}

    for obj, data in pairs(S.UISpoofObjects or {}) do
        if data.Conn then pcall(function() data.Conn:Disconnect() end) end
        if data.DestConn then pcall(function() data.DestConn:Disconnect() end) end
    end
    S.UISpoofObjects = {}

    if sweepTask then
        pcall(function() task.cancel(sweepTask) end)
        sweepTask = nil
    end
end

local function startSpoofer()
    clearHooks()
    S.SessionSpoofName = "Guest_" .. math.random(1000, 9999)
    State.SessionSpoofName = S.SessionSpoofName
    S.UISpoofObjects = S.UISpoofObjects or {}

    local containers = getSpoofContainers()
    for _, container in ipairs(containers) do
        pcall(function()
            local addedConn = container.DescendantAdded:Connect(function(desc)
                task.spawn(hookObject, desc)
            end)
            table.insert(spoofConns, addedConn)
            table.insert(S.Connections, addedConn)
        end)
    end

    scanAllContainers()

    sweepTask = task.spawn(function()
        while S.RandomizeUIText do
            task.wait(1.5)
            if not S.RandomizeUIText then break end
            scanAllContainers()
        end
    end)
end

registerModule("Player", "UI Name Spoof", 160, 50, true, S.RandomizeUIText, function(v)
    S.RandomizeUIText = v
    if v then
        startSpoofer()
    else
        clearHooks()
    end
    saveConfig()
end, function(drawer)
    addTextboxOption(drawer, "Custom Spoof Text (Blank for Guest)", S.CustomUIText, function(txt)
        S.CustomUIText = txt
        for obj, _ in pairs(S.UISpoofObjects or {}) do
            if obj and obj.Parent then processUISpoofText(obj) end
        end
        scanAllContainers()
        saveConfig()
    end)
end, false)

if S.RandomizeUIText then
    startSpoofer()
end

