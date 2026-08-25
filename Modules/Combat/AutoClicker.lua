local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local UI = VH.UI
local Utils = VH.Utils

local Mouse = Services.Mouse
local VirtualUser = Services.VirtualUser

local registerModule = UI.registerModule
local addSliderOption = UI.addSliderOption
local addKeybindOption = UI.addKeybindOption

local saveConfig = VH.Config.saveConfig

local clickerSession = 0

registerModule("Combat", "Auto Clicker", 20, 50, true, S.AutoClicker, function(v)
    S.AutoClicker = v
    clickerSession = clickerSession + 1
    local currentSession = clickerSession
    if v then
        task.spawn(function()
            local delayTime = S.AutoClickerDelay or 2
            if delayTime > 0 then
                task.wait(delayTime)
            end
            while S.AutoClicker and State.uiRunning and clickerSession == currentSession do
                if not Utils.isMouseOverHubUI() then
                    if mouse1press and mouse1release then
                        mouse1press()
                        task.wait(0.01)
                        mouse1release()
                        task.wait(S.AutoClickerInterval or 0.1)
                    elseif mouse1click then
                        mouse1click()
                        task.wait(S.AutoClickerInterval or 0.1)
                    else
                        pcall(function()
                            VirtualUser:CaptureController()
                            VirtualUser:ClickButton1(Vector2.new(Mouse.X, Mouse.Y))
                        end)
                        task.wait(S.AutoClickerInterval or 0.1)
                    end
                else
                    task.wait(0.1)
                end
            end
        end)
    end
    saveConfig()
end, function(drawer)
    addKeybindOption(drawer, "Auto Clicker Bind", S.AutoClickerKey or Enum.KeyCode.Unknown, function(k) S.AutoClickerKey = k; saveConfig() end)
    addSliderOption(drawer, "Start Delay (sec)", 0, 5, S.AutoClickerDelay or 2, function(v) S.AutoClickerDelay = v; saveConfig() end)
    addSliderOption(drawer, "Click Interval (sec)", 1, 100, math.round((S.AutoClickerInterval or 0.1) * 100), function(v) S.AutoClickerInterval = v / 100; saveConfig() end)
end, false)
