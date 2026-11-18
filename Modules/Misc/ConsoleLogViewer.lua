local VH = _G.VoidHub
local State = VH.State
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addTextboxOption = UI.addTextboxOption
local addButtonOption = UI.addButtonOption
local addScrollFeedOption = UI.addScrollFeedOption

local StudioTheme = UI.StudioTheme or {
    green = Color3.fromRGB(76, 175, 80),
    yellow = Color3.fromRGB(220, 170, 50),
    red = Color3.fromRGB(215, 60, 60)
}

registerModule("Misc", "Console Viewer", 720, 50, false, false, nil, function(drawer)
    local conFeed = addScrollFeedOption(drawer, 185)
    State.activeConsoleFeed = conFeed

    local showI, showW, showE = true, true, true
    local searchFilter = ""

    local function rebuildConsole()
        conFeed:Clear()
        local logs = State.consoleLogs or {}
        local filterLower = searchFilter:lower()

        for _, log in ipairs(logs) do
            local msg = log.message or ""
            local mType = log.messageType
            local col = Color3.fromRGB(220, 220, 220)
            local prefix = ""
            local show = false

            if mType == Enum.MessageType.MessageOutput or mType == Enum.MessageType.MessageInfo then
                if mType == Enum.MessageType.MessageInfo then
                    col = Color3.fromRGB(80, 180, 240)
                    prefix = "[INFO] "
                end
                show = showI
            elseif mType == Enum.MessageType.MessageWarning then
                col = Color3.fromRGB(240, 200, 50)
                prefix = "[WARN] "
                show = showW
            elseif mType == Enum.MessageType.MessageError then
                col = Color3.fromRGB(240, 70, 70)
                prefix = "[ERROR] "
                show = showE
            end

            if show then
                local fullText = prefix .. msg
                if filterLower == "" or fullText:lower():find(filterLower, 1, true) then
                    conFeed:AddEntry(fullText, col, log.count)
                end
            end
        end
    end

    addTextboxOption(drawer, "Filter Console Logs", "Search logs...", function(txt)
        searchFilter = txt or ""
        rebuildConsole()
    end)

    addToggleOption(drawer, "Show Prints & Info", showI, function(v)
        showI = v
        rebuildConsole()
    end)

    addToggleOption(drawer, "Show Warnings", showW, function(v)
        showW = v
        rebuildConsole()
    end)

    addToggleOption(drawer, "Show Errors", showE, function(v)
        showE = v
        rebuildConsole()
    end)

    addButtonOption(drawer, "Copy Filtered Logs", function()
        local text = ""
        local logs = State.consoleLogs or {}
        local filterLower = searchFilter:lower()

        for _, log in ipairs(logs) do
            local msg = log.message or ""
            local mType = log.messageType
            local prefix = ""
            local show = false

            if mType == Enum.MessageType.MessageOutput or mType == Enum.MessageType.MessageInfo then
                if mType == Enum.MessageType.MessageInfo then prefix = "[INFO] " end
                show = showI
            elseif mType == Enum.MessageType.MessageWarning then
                prefix = "[WARN] "
                show = showW
            elseif mType == Enum.MessageType.MessageError then
                prefix = "[ERROR] "
                show = showE
            end

            if show then
                local fullText = prefix .. msg
                if filterLower == "" or fullText:lower():find(filterLower, 1, true) then
                    text = text .. fullText .. (log.count and log.count > 1 and (" (x" .. log.count .. ")\n") or "\n")
                end
            end
        end

        local write = setclipboard or writeclipboard or toclipboard or print
        local s = pcall(function() write(text) end)
        if s then
            notify("Console logs copied to clipboard!", StudioTheme.green)
        else
            notify("Clipboard write failed", StudioTheme.red)
        end
    end)

    addButtonOption(drawer, "Clear Console Log", function()
        State.consoleLogs = {}
        State.consoleLogsMap = {}
        conFeed:Clear()
        notify("Console logs cleared", StudioTheme.yellow)
    end)

    rebuildConsole()
end, true, 380, 360)
