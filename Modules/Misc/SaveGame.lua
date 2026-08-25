local VH = _G.VoidHub
local Utils = VH.Utils
local UI = VH.UI

local notify = Utils.notify
local registerModule = UI.registerModule
local addButtonOption = UI.addButtonOption

local function runSaveGame(decompile)
    local modeText = decompile and " (Decompiled)" or ""
    notify("Initializing Save Game" .. modeText .. "...", Color3.fromRGB(218, 170, 42))
    task.spawn(function()
        local success, err = pcall(function()
            local SaveInstance = saveinstance or (getgenv and getgenv().saveinstance)
            if not SaveInstance then
                SaveInstance = loadstring(game:HttpGet("https://raw.githubusercontent.com/luau/UniversalSynSaveInstance/main/saveinstance.lua"))()
                if type(SaveInstance) == "table" and SaveInstance.Save then
                    SaveInstance = SaveInstance.Save
                end
            end

            if type(SaveInstance) == "function" then
                if decompile then
                    SaveInstance({Decompile = true, DecompileTimeout = 10})
                else
                    SaveInstance()
                end
            else
                error("saveinstance API not available on executor")
            end
        end)

        if success then
            notify("Save Game completed successfully!", Color3.fromRGB(50, 195, 75))
        else
            notify("Save Game error: " .. tostring(err), Color3.fromRGB(218, 38, 38))
        end
    end)
end

registerModule("Misc", "Save Game", 720, 50, false, false, function()
    runSaveGame(false)
end, function(drawer)
    addButtonOption(drawer, "Save Place (Standard)", function() runSaveGame(false) end)
    addButtonOption(drawer, "Save Place (Decompile Scripts)", function() runSaveGame(true) end)
end, false)
