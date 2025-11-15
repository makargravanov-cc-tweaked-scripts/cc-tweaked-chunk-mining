local modemName = peripheral.getName(peripheral.find("modem"))

rednet.open(modemName)
if rednet.isOpen() == false then
    log("Turn on modem please!")
end

--- @return string
function getFileTimestamp()
    return os.date("%Y_%m_%d_%H_%M_%S.txt", os.epoch("local") / 1000)
end

local logFile = fs.open("log_" .. getFileTimestamp(), "a")

--- @return string
function getTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S", os.epoch("local") / 1000)
end

--- @param text string
--- @return string
function log(text)
    print(text)
    logFile.writeLine("[" .. getTimestamp() .. "]: " .. text)
end

local Main = require("hub.main")

Main.run()