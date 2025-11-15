local modemName = peripheral.getName(peripheral.find("modem"))

rednet.open(modemName)
if rednet.isOpen() == false then
    log("Turn on modem please!")
end

local LogFile = fs.open("log_" .. GetFileTimestamp(), "a")

--- @param text string
--- @return string
function log(text)
    print(text)
    LogFile.write("[" .. GetTimestamp() .. "]: " .. text)
end

--- @return string
function GetFileTimestamp()
    return os.date("%Y_%m_%d_%H_%M_%S.txt", os.epoch("local") / 1000)
end

--- @return string
function GetTimestamp()
    return os.date("%Y-%m-%d %H:%M:%S", os.epoch("local") / 1000)
end

local Main = require("hub.main")

Main.run()