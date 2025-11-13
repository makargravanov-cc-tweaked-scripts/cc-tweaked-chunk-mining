
rednet.open("left")
if rednet.isOpen("left") == false then
    rednet.open("right")
    if rednet.isOpen("right") == false then
        print("Turn on modem please!")
    end
end

local Main = require("hub.main")

Main.run()