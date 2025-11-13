
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


    for slot, detail in pairs(chest.list()) do
        if detail.name == "createaddition:biomass_pellet_block" then
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

            if chest.pullItems("up", slot, 1, turtleFreeSlot) > 0 then
                turtle.select(turtleFreeSlot)
                if turtle.refuel(1) then
                    turtle.select(1)
                    return true
                end
            end
        end
    end
    return false
end


return FuelService