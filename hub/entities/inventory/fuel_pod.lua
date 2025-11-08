
--- @class FuelPod
--- @field position Vec
--- @field isOccupied boolean
--- @field currentDroneId integer
--- @field new fun(position: Vec): FuelPod
--- @field changeOccupancy fun(self: FuelPod, value: boolean)
--- @field equals fun(self: FuelPod, other: FuelPod): boolean
--- @field subscribeDrone fun(self: FuelPod, droneId: integer) : boolean
--- @field unsubscribeDrone fun(self: FuelPod, droneId: integer)

local FuelPod
FuelPod.__index = FuelPod

--- @param position Vec
--- @construtor
--- @return FuelPod
function FuelPod.new(position)
    local self =  setmetatable({}, FuelPod)
    self.position = position
    self.isOccupied = false
    self.currentDroneId = -1
    return self
end

--- @param self FuelPod
function FuelPod:changeOccupancy(value)
    self.isOccupied = value
end

--- @param self FuelPod
--- @param other FuelPod
--- @return boolean
function FuelPod:equals(other)
    --- @type Vec
    local otherPos = other.position
    return self.position.x == otherPos.x and self.position.y == otherPos.y and self.position.z == otherPos.z
end

--- @param self FuelPod
--- @param droneId integer
--- @return boolean
function FuelPod:subscribeDrone(droneId)
    if self.isOccupied then
        return false
    else
        self.isOccupied = true
    end
    self.currentDroneId = droneId
    return true
end

--- @param self FuelPod
--- @param droneId integer
function FuelPod:unsubscribeDrone(droneId)
    if self.currentDroneId == droneId then
        self.isOccupied = false
        self.currentDroneId = -1
    end
end

return FuelPod