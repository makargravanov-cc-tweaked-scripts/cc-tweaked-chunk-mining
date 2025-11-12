
rednet.open("right")
if rednet.isOpen("right") == false then
    print("Turn on modem please!")
end


local Main = require("hub.main")

Main.run()