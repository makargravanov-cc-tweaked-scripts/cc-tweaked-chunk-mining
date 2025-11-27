local FuelService = require("drone.services.fuel_service")

if not FuelService.hasEnoughFuel(2880) then
    print("FUEL LEVEL LESS THAN 2880. PLEASE REFUEL TURTLE !!!")
    return
end

local modemName = peripheral.getName(peripheral.find("modem"))

rednet.open(modemName)
if rednet.isOpen() == false then
    print("Turn on modem please!")
end

local Main = require("drone.main")

Main.run()
