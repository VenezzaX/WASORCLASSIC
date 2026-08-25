local VH = _G.VoidHub
local State = VH.State
local UI = VH.UI

local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addButtonOption = UI.addButtonOption
local addScrollFeedOption = UI.addScrollFeedOption

local activeConsoleFeed = State.activeConsoleFeed

local consoleLogs = State.consoleLogs
local consoleLogsMap = State.consoleLogsMap

registerModule("Misc", "Console Viewer", 720, 50, false, false, nil, function(drawer)
    local conFeed = addScrollFeedOption(drawer, 80); activeConsoleFeed = conFeed; local showI, showW, showE = true, true, true
    local function rebuildConsole()
        conFeed:Clear()
        for _, log in ipairs(consoleLogs) do
            local msg = log.message; local mType = log.messageType; local col = Color3.fromRGB(220, 220, 220); local prefix = ""; local show = false
            if mType == Enum.MessageType.MessageOutput or mType == Enum.MessageType.MessageInfo then if mType == Enum.MessageType.MessageInfo then col = Color3.fromRGB(80, 180, 240); prefix = "[INFO] " end; show = showI
            elseif mType == Enum.MessageType.MessageWarning then col = Color3.fromRGB(240, 200, 50); prefix = "[WARN] "; show = showW
            elseif mType == Enum.MessageType.MessageError then col = Color3.fromRGB(240, 70, 70); prefix = "[ERROR] "; show = showE end
            if show then conFeed:AddEntry(prefix .. msg, col, log.count) end
        end
    end
    addToggleOption(drawer, "Show Prints & Info", showI, function(v) showI = v; rebuildConsole() end)
    addToggleOption(drawer, "Show Warnings", showW, function(v) showW = v; rebuildConsole() end)
    addToggleOption(drawer, "Show Errors", showE, function(v) showE = v; rebuildConsole() end)
    addButtonOption(drawer, "Clear Console Log", function() consoleLogs = {}; consoleLogsMap = {}; conFeed:Clear() end)
    rebuildConsole()
end, true, 240, 220)
