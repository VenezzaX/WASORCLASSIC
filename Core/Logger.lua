local VH = _G.VoidHub
local Logger = {}

local Services = VH.Services
local State = VH.State

Logger.logCrash = function(context, err, stack)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local crashHeader = string.format("==================== CRASH LOG [%s] ====================\nContext: %s\nError: %s\nTraceback:\n%s\n=================================================================\n\n", timestamp, tostring(context), tostring(err), tostring(stack or "N/A"))
    
    warn(string.format("[WASOR CRASH] [%s] Error: %s\nTraceback: %s", tostring(context), tostring(err), tostring(stack or "")))
    
    pcall(function()
        if writefile then
            local filename = "WASOR_crash.log"
            if isfile and isfile(filename) then
                if appendfile then
                    appendfile(filename, crashHeader)
                else
                    local cur = readfile(filename)
                    writefile(filename, cur .. crashHeader)
                end
            else
                writefile(filename, crashHeader)
            end
        end
    end)
end

Logger.logMessage = function(sender, text, color)
    local logObj = {
        message = string.format("[%s]: %s", sender, text),
        messageType = Enum.MessageType.MessageOutput,
        timestamp = os.date("%H:%M:%S")
    }
    table.insert(State.consoleLogs, logObj)
    if #State.consoleLogs > 500 then table.remove(State.consoleLogs, 1) end
    if State.activeConsoleFeed then
        State.activeConsoleFeed:AddEntry(logObj.message, color or Color3.fromRGB(200, 200, 200))
    end
end

Logger.connectConsoleLogger = function()
    local LogService = game:GetService("LogService")
    pcall(function()
        local history = LogService:GetLogHistory()
        for _, log in ipairs(history) do
            local msg = log.message; local msgType = log.messageType; local rawTime = log.timestamp
            if rawTime and rawTime > 1e11 then rawTime = rawTime / 1000 end
            local timestamp = os.date("%H:%M:%S", rawTime)
            local key = msgType.Value .. "_" .. msg
            local existingLog = State.consoleLogsMap[key]
            if existingLog then
                existingLog.count = (existingLog.count or 1) + 1; existingLog.timestamp = timestamp
                for idx, item in ipairs(State.consoleLogs) do
                    if item == existingLog then table.remove(State.consoleLogs, idx); break end
                end
                table.insert(State.consoleLogs, existingLog)
            else
                local logObj = { message = msg, messageType = msgType, timestamp = timestamp, count = 1 }
                table.insert(State.consoleLogs, logObj); State.consoleLogsMap[key] = logObj
                if #State.consoleLogs > 500 then
                    local removed = table.remove(State.consoleLogs, 1)
                    if removed then State.consoleLogsMap[removed.messageType.Value .. "_" .. removed.message] = nil end
                end
            end
        end
    end)
    
    local con = LogService.MessageOut:Connect(function(msg, msgType)
        local timestamp = os.date("%H:%M:%S"); local key = msgType.Value .. "_" .. msg
        local existingLog = State.consoleLogsMap[key]
        if existingLog then
            existingLog.count = (existingLog.count or 1) + 1; existingLog.timestamp = timestamp
            for idx, item in ipairs(State.consoleLogs) do
                if item == existingLog then table.remove(State.consoleLogs, idx); break end
            end
            table.insert(State.consoleLogs, existingLog)
        else
            local logObj = { message = msg, messageType = msgType, timestamp = timestamp, count = 1 }
            table.insert(State.consoleLogs, logObj); State.consoleLogsMap[key] = logObj
            if #State.consoleLogs > 500 then
                local removed = table.remove(State.consoleLogs, 1)
                if removed then State.consoleLogsMap[removed.messageType.Value .. "_" .. removed.message] = nil end
            end
        end
        if State.activeConsoleFeed then
            local col = Color3.fromRGB(220, 220, 220); local prefix = ""
            if msgType == Enum.MessageType.MessageInfo then col = Color3.fromRGB(80, 180, 240); prefix = "[INFO] "
            elseif msgType == Enum.MessageType.MessageWarning then col = Color3.fromRGB(240, 200, 50); prefix = "[WARN] "
            elseif msgType == Enum.MessageType.MessageError then col = Color3.fromRGB(240, 70, 70); prefix = "[ERROR] " end
            State.activeConsoleFeed:AddEntry(prefix .. msg, col)
        end
    end)
    table.insert(State.S.Connections, con)
end

local lastChats = {}
local function isDuplicateChat(speaker, message)
    local t = tick(); local last = lastChats[speaker]
    if last and last.message == message and (t - last.time) < 0.2 then return true end
    lastChats[speaker] = {message = message, time = t}; return false
end

local function appendToChatLogFile(timestamp, speaker, message)
    pcall(function()
        if writefile and readfile then
            local filename = "utility_hub_chat_logs.txt"
            local logLine = string.format("[%s] [%s]: %s\n", timestamp, speaker, message)
            if isfile(filename) then
                if appendfile then appendfile(filename, logLine)
                else local current = readfile(filename); writefile(filename, current .. logLine) end
            else writefile(filename, logLine) end
        end
    end)
end

Logger.connectChatLogger = function()
    local chatService = game:GetService("TextChatService"); local useModern = false
    local S = State.S
    pcall(function() if chatService.ChatVersion == Enum.ChatVersion.TextChatService then useModern = true end end)
    
    if useModern then
        pcall(function()
            local modernCon = chatService.MessageReceived:Connect(function(msgObj)
                local speaker = "System"
                if msgObj.TextSource then
                    local p = Services.Players:GetPlayerByUserId(msgObj.TextSource.UserId)
                    if p then speaker = p.DisplayName else speaker = msgObj.TextSource.DisplayName or "System" end
                end
                local text = msgObj.Text
                if isDuplicateChat(speaker, text) then return end
                local timestamp = os.date("%H:%M:%S")
                local log = { Speaker = speaker, Message = text, Timestamp = timestamp, Color = Color3.fromRGB(200, 200, 200) }
                table.insert(S.ChatHistory, log)
                if #S.ChatHistory > 200 then table.remove(S.ChatHistory, 1) end
                if State.activeChatFeed then State.activeChatFeed:AddEntry(string.format("[%s] [%s]: %s", timestamp, speaker, text), log.Color) end
                appendToChatLogFile(timestamp, speaker, text)
                if S.ToastChatEnabled and speaker ~= Services.LP.DisplayName then
                    if VH.UI and VH.UI.showToast then VH.UI.showToast(speaker .. ": " .. text, State.currentThemeColor) end
                end
            end)
            table.insert(S.Connections, modernCon)
        end)
    else
        pcall(function()
            for _, p in ipairs(Services.Players:GetPlayers()) do
                S.ChatConnections[p] = p.Chatted:Connect(function(msg)
                    local speaker = p.DisplayName
                    if isDuplicateChat(speaker, msg) then return end
                    local timestamp = os.date("%H:%M:%S")
                    local log = { Speaker = speaker, Message = msg, Timestamp = timestamp, Color = Color3.fromRGB(200, 200, 200) }
                    table.insert(S.ChatHistory, log)
                    if #S.ChatHistory > 200 then table.remove(S.ChatHistory, 1) end
                    if State.activeChatFeed then State.activeChatFeed:AddEntry(string.format("[%s] [%s]: %s", timestamp, speaker, msg), log.Color) end
                    appendToChatLogFile(timestamp, speaker, msg)
                    if S.ToastChatEnabled and p ~= Services.LP then
                        if VH.UI and VH.UI.showToast then VH.UI.showToast(speaker .. ": " .. msg, State.currentThemeColor) end
                    end
                end)
            end
            local playerAddedCon = Services.Players.PlayerAdded:Connect(function(p)
                S.ChatConnections[p] = p.Chatted:Connect(function(msg)
                    local speaker = p.DisplayName
                    if isDuplicateChat(speaker, msg) then return end
                    local timestamp = os.date("%H:%M:%S")
                    local log = { Speaker = speaker, Message = msg, Timestamp = timestamp, Color = Color3.fromRGB(200, 200, 200) }
                    table.insert(S.ChatHistory, log)
                    if #S.ChatHistory > 200 then table.remove(S.ChatHistory, 1) end
                    if State.activeChatFeed then State.activeChatFeed:AddEntry(string.format("[%s] [%s]: %s", timestamp, speaker, msg), log.Color) end
                    appendToChatLogFile(timestamp, speaker, msg)
                    if S.ToastChatEnabled and p ~= Services.LP then
                        if VH.UI and VH.UI.showToast then VH.UI.showToast(speaker .. ": " .. msg, State.currentThemeColor) end
                    end
                end)
            end)
            table.insert(S.Connections, playerAddedCon)
        end)
    end
end

VH.Logger = Logger
return Logger
