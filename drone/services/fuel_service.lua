
--- @class FuelService
--- @

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

return FuelService