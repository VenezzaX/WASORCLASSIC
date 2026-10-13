local VH = _G.VoidHub
local Services = VH.Services
local State = VH.State
local S = State.S
local Utils = VH.Utils
local UI = VH.UI

local Workspace = Services.Workspace
local LP = Services.LP

local notify = Utils.notify
local registerModule = UI.registerModule
local addButtonOption = UI.addButtonOption
local addToggleOption = UI.addToggleOption
local saveConfig = VH.Config.saveConfig

local autoDropConn = nil

local function dropAccessories()
    local char = Utils.getChar()
    if not char then
        notify("No character found to drop hats from!", Color3.fromRGB(218, 38, 38))
        return 0
    end

    local droppedCount = 0
    local hrp = Utils.getHRP()
    local hrpPos = hrp and hrp.Position or (char:GetPivot().Position)

    for _, item in ipairs(char:GetChildren()) do
        if item:IsA("Accessory") then
            local handle = item:FindFirstChild("Handle") or item:FindFirstChildWhichIsA("BasePart")
            if handle and handle:IsA("BasePart") then
                -- Break all joints and welds connected to this accessory
                pcall(function()
                    for _, joint in ipairs(handle:GetJoints()) do
                        pcall(function() joint:Destroy() end)
                    end
                    for _, desc in ipairs(handle:GetDescendants()) do
                        if desc:IsA("Weld") or desc:IsA("WeldConstraint") or desc:IsA("Motor6D") or desc:IsA("ManualWeld") or desc:IsA("Snap") then
                            pcall(function() desc:Destroy() end)
                        end
                    end
                end)

                -- Setup physical properties
                handle.CanCollide = true
                handle.Anchored = false
                
                if S.HatDropScatter then
                    local rx = (math.random() - 0.5) * 30
                    local rz = (math.random() - 0.5) * 30
                    local ry = math.random(15, 35)
                    handle.AssemblyLinearVelocity = Vector3.new(rx, ry, rz)
                    handle.AssemblyAngularVelocity = Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
                end

                pcall(function()
                    item.Parent = Workspace
                    handle.Parent = Workspace
                end)

                droppedCount = droppedCount + 1
            end
        end
    end

    return droppedCount
end

local function setupAutoDrop()
    if autoDropConn then
        autoDropConn:Disconnect()
        autoDropConn = nil
    end

    if S.AutoHatDropOnSpawn then
        autoDropConn = LP.CharacterAdded:Connect(function(char)
            task.wait(0.6)
            if S.AutoHatDropOnSpawn then
                local count = dropAccessories()
                if count > 0 then
                    notify("Auto-dropped " .. count .. " accessories!", Color3.fromRGB(50, 195, 75))
                end
            end
        end)
    end
end

registerModule("Player", "Hat Drop", 320, 50, true, S.HatDropActive, function(v)
    S.HatDropActive = v
    if v then
        local count = dropAccessories()
        if count > 0 then
            notify("Dropped " .. count .. " accessories!", Color3.fromRGB(50, 195, 75))
        else
            notify("No hats equipped to drop!", Color3.fromRGB(218, 170, 42))
        end
    else
        notify("Hat Drop deactivated", Color3.fromRGB(218, 170, 42))
    end
    saveConfig()
end, function(drawer)
    if addButtonOption then
        addButtonOption(drawer, "Drop All Hats Now", function()
            local count = dropAccessories()
            if count > 0 then
                notify("Dropped " .. count .. " accessories!", Color3.fromRGB(50, 195, 75))
            else
                notify("No hats equipped to drop!", Color3.fromRGB(218, 170, 42))
            end
        end)
    end

    addToggleOption(drawer, "Scatter Force Impulse", S.HatDropScatter or false, function(v)
        S.HatDropScatter = v
        saveConfig()
    end)

    addToggleOption(drawer, "Auto-Drop on Respawn", S.AutoHatDropOnSpawn or false, function(v)
        S.AutoHatDropOnSpawn = v
        setupAutoDrop()
        saveConfig()
    end)
end, false)
