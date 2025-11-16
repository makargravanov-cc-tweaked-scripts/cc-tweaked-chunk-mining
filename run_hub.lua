local modemName = peripheral.getName(peripheral.find("modem"))

rednet.open(modemName)
if rednet.isOpen() == false then
    log("Turn on modem please!")
end

--- @return string
function getFileTimestamp()
    return os.date("%Y_%m_%d_%H_%M_%S.txt", os.epoch("local") / 1000)
end

local logFile = nil 

if fs.getFreeSpace(".") > 1000 then
    logFile = fs.open("log_" .. getFileTimestamp(), "a")
else
    print("WARN: out of space. File logging stopped")
end

--- @return string
function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S", os.epoch("local") / 1000)
end

--- @param text string
--- @return string
function log(text)
    print(text)
    if logFile then
        logFile.writeLine("[" .. getTimestamp() .. "]: " .. text)
    end

    if logFile and fs.getFreeSpace(".") < 1000 then
        print("WARN: out of space. File logging stopped")
        logFile.writeLine("[" .. getTimestamp() .. "]: " .. "Out of space for logging. Logging stopped.")
    end
end

local Main = require("hub.main")

Main.run()