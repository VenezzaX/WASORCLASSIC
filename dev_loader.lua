local function writeCrashLog(context, err, stack)
    local timestamp = os.date("%Y-%m-%d %H:%M:%S")
    local crashMsg = string.format("==================== CRASH LOG [%s] ====================\nContext: %s\nError: %s\nTraceback:\n%s\n=================================================================\n\n", timestamp, tostring(context), tostring(err), tostring(stack or "N/A"))
    warn(string.format("[WASOR CRASH] [%s] Error: %s\nTraceback:\n%s", tostring(context), tostring(err), tostring(stack or "")))
    pcall(function()
        if writefile then
            local filename = "WASOR_crash.log"
            if isfile and isfile(filename) then
                if appendfile then
                    appendfile(filename, crashMsg)
                else
                    local cur = readfile(filename)
                    writefile(filename, cur .. crashMsg)
                end
            else
                writefile(filename, crashMsg)
            end
        end
    end)
end

if isfile and readfile and loadstring then
    if isfile("WASOR/init.lua") then
        local code = readfile("WASOR/init.lua")
        local fn, parseErr = loadstring(code, "WASOR/init.lua")
        if fn then
            local errTrace = nil
            local success, err = xpcall(fn, function(e)
                errTrace = debug.traceback(tostring(e), 2)
                return e
            end)
            if not success then
                writeCrashLog("Dev Loader Execution", err, errTrace)
            end
        else
            writeCrashLog("Dev Loader Parsing", parseErr, debug.traceback())
        end
    else
        warn("[WASOR Dev Loader] init.lua not found! Make sure 'WASOR' is inside your workspace folder.")
    end
else
    warn("[WASOR Dev Loader] Executor does not support standard file operations (isfile, readfile, loadstring).")
end
