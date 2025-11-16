
--- @class CargoPod
--- @field position Vec
--- @field isOccupied boolean
--- @field currentDroneId integer
--- @field new fun(position: Vec): CargoPod
--- @field changeOccupancy fun(self: CargoPod, value: boolean)
--- @field equals fun(self: CargoPod, other: CargoPod): boolean
--- @field subscribeDrone fun(self: CargoPod, droneId: integer) : boolean
--- @field unsubscribeDrone fun(self: CargoPod, droneId: integer)

local CargoPod = {}
CargoPod.__index = CargoPod

--- @param position Vec
--- @construtor
--- @return CargoPod
function CargoPod.new(position)
    local self =  setmetatable({}, CargoPod)
    self.position = position
    self.isOccupied = false
    return self
end

--- @param self CargoPod
function CargoPod:changeOccupancy(value)
    self.isOccupied = value
end

--- @param self CargoPod
--- @param other CargoPod
--- @return boolean
function CargoPod:equals(other)
    --- @type Vec
    local otherPos = other.position
    return self.position.x == otherPos.x and self.position.y == otherPos.y and self.position.z == otherPos.z
end

--- @param self CargoPod
--- @param droneId integer
--- @return boolean
function CargoPod:subscribeDrone(droneId)
    log(droneId .. " subscribeDrone")
    if self.isOccupied then
        log(droneId .. " subscribeDrone: Fail to subscribe because isOccupied is true")
        return false
    else
        log(droneId .. " subscribeDrone: change isOccupied to true")
        self.isOccupied = true
    end
    self.currentDroneId = droneId
    log(droneId .. " subscribeDrone: succesfully subscribed to pod: " .. self.position.x .. "; " .. self.position.y .. "; " .. self.position.z)
    return true
end

--- @param self CargoPod
--- @param droneId integer
function CargoPod:unsubscribeDrone(droneId)
    log(droneId .. " unsubscribeDrone isOccupied = " .. self.isOccupied)
    if self.currentDroneId == droneId then
        self.isOccupied = false
        self.currentDroneId = -1
        log(droneId .. " subscribeDrone: succesfully unsubscribed")
    end
end

return CargoPod