local VH = _G.VoidHub
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule

local addToggleOption = UI.addToggleOption
local addTextboxOption = UI.addTextboxOption
local addButtonOption = UI.addButtonOption
local addScrollFeedOption = UI.addScrollFeedOption

local saveConfig = VH.Config.saveConfig

local activeChatFeed = State.activeChatFeed

registerModule("Misc", "Chat Logger", 720, 50, false, false, nil, function(drawer)
    local filter = ""; local chatFeed = addScrollFeedOption(drawer, 80); activeChatFeed = chatFeed
    addTextboxOption(drawer, "Filter chat logs text", "Filter text", function(txt)
        filter = txt; chatFeed:Clear()
        for _, log in ipairs(S.ChatHistory) do local matches = true; if filter ~= "" then matches = log.Speaker:lower():find(filter:lower()) or log.Message:lower():find(filter:lower()) end; if matches then chatFeed:AddEntry(string.format("[%s] [%s]: %s", log.Timestamp, log.Speaker, log.Message), log.Color) end end
    end)
    addButtonOption(drawer, "Copy Entire Chat Logs", function()
        local text = ""; for _, log in ipairs(S.ChatHistory) do text = text .. string.format("[%s] [%s]: %s\n", log.Timestamp, log.Speaker, log.Message) end
        local write = setclipboard or writeclipboard or toclipboard or print
        if pcall(function() write(text) end) then notify("Logs copied to clipboard!", Color3.fromRGB(50, 195, 75)) else notify("Clipboard write failed", Color3.fromRGB(218, 38, 38)) end
    end)
    addToggleOption(drawer, "Toast notifications on chat", S.ToastChatEnabled, function(v) S.ToastChatEnabled = v; saveConfig() end)
    for _, log in ipairs(S.ChatHistory) do chatFeed:AddEntry(string.format("[%s] [%s]: %s", log.Timestamp, log.Speaker, log.Message), log.Color) end
end, true, 240, 220)
