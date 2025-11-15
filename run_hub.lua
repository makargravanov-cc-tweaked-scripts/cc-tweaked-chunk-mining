local modemName = peripheral.getName(peripheral.find("modem"))

rednet.open(modemName)
if rednet.isOpen() == false then
    log("Turn on modem please!")
end

local Main = require("hub.main")

Main.run()