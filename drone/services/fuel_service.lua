
--- @class FuelService
--- @field refuelFromBiomassBlockChest fun() : boolean

local FuelService = {}
FuelService.__index = FuelService

--- @param minLevel integer
--- @return boolean
function FuelService.hasEnoughFuel(minLevel)
    local fuel = turtle.getFuelLevel()
    return fuel >= (minLevel or 1)
end

function FuelService.getFuelLevel()
    return turtle.getFuelLevel()
end

function FuelService.refuelFromBiomassBlockChest()
    local chest = peripheral.wrap("bottom")
    if not chest or not chest.list or not chest.pullItems then
        error("Chest not found")
    end

    local turtleFreeSlot = nil
    for i = 1, 16 do
        if turtle.getItemCount(i) == 0 then
            turtleFreeSlot = i
            break
        end
    end
    if not turtleFreeSlot then
        error("No free slots")
    end
    turtle.select(turtleFreeSlot)
    turtle.suckDown(1)
    turtle.refuel(1)
    return true

end


return FuelService