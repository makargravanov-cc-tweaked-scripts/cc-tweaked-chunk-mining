
local modemName = peripheral.getName(peripheral.find("modem"))

rednet.open(modemName)
if rednet.isOpen() == false then
    print("Turn on modem please!")
end

local Main = require("drone.main")

Main.run()