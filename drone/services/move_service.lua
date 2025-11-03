--- @class MoveService
--- @field droneState DroneState
--- @field new fun(droneState: DroneState): MoveService
--- @field getDistanceTo fun(self: MoveService, to: Vec): number
--- @field moveVertical fun(self: MoveService, targetY: number): boolean
--- @field calibrateDirection fun(self: MoveService): boolean
--- @field turnLeft fun(self: MoveService): boolean
--- @field turnRight fun(self: MoveService): boolean
--- @field turnTo fun(self: MoveService, targetDir: number)
--- @field moveHorizontal fun(self: MoveService, targetX: number, targetZ: number): boolean

local Vec = require("lib.vec")
local GpsUtil = require("lib.gps_util")

local MoveService = {}
MoveService.__index = MoveService

--- @param droneState DroneState
--- @return MoveService
function MoveService.new(droneState)
    local self = setmetatable({}, MoveService)
    self.droneState = droneState
    return self
end

--- @param self MoveService
--- @param to Vec
--- @return number
function MoveService:getDistanceTo(to)
    self.droneState:updatePosition()
    return Vec.dist(self.droneState:getPosition(), to)
end

--- @param self MoveService
--- @param targetY number
--- @return boolean
function MoveService:moveVertical(targetY)
    self.droneState:updatePosition()
    local currentPos = self.droneState:getPosition()

    if targetY > currentPos.y then
        local diff = targetY - currentPos.y
        for _ = 1, diff do
            if not turtle.up() then
                self.droneState:updatePosition()
                return false
            end
        end
    elseif targetY < currentPos.y then
        local diff = currentPos.y - targetY
        for _ = 1, diff do
            if not turtle.down() then
                self.droneState:updatePosition()
                return false
            end
        end
    end

    self.droneState:updatePosition()
    return true
end

--- @param self MoveService
--- @return boolean 
function MoveService:calibrateDirection()
    print("Direction calibrating...")
    local pos1 = GpsUtil.position()
    if not pos1 then
        print("Error: no GPS.")
        return false
    end

    if not turtle.forward() then
        turtle.turnRight()
        turtle.turnRight()
        if not turtle.forward() then
            turtle.turnRight()
            turtle.turnRight()
            print("Calibrating error. Path blocked")
            return false
        end
    end

    local pos2 = GpsUtil.position()
    turtle.back()

    local delta = Vec.sub(pos2, pos1)
    local newDirection

    if     delta.z == -1 then newDirection = 0 -- (-Z)
    elseif delta.x == 1  then newDirection = 1 -- (+X)
    elseif delta.z == 1  then newDirection = 2 -- (+Z)
    elseif delta.x == -1 then newDirection = 3 -- (-X)
    else
        print("Calibrating error. Invalid delta.")
        return false
    end
    self.droneState:updateDirection(newDirection)
    print("Calibrating success, direction: " .. newDirection)
    return true
end

--- @param self MoveService
--- @return boolean
function MoveService:turnLeft()
    if turtle.turnLeft() then
        local newDir = (self.droneState:getDirection() + 3) % 4
        self.droneState:updateDirection(newDir)
        return true
    end
    return false
end

--- @param self MoveService
--- @return boolean
function MoveService:turnRight()
    if turtle.turnRight() then
        local newDir = (self.droneState:getDirection() + 1) % 4
        self.droneState:updateDirection(newDir)
        return true
    end
    return false
end

--- @param self MoveService
--- @param targetDir number (0: -Z, 1: +X, 2: +Z, 3: -X)
function MoveService:turnTo(targetDir)
    local currentDir = self.droneState:getDirection()
    local diff = (targetDir - currentDir + 4) % 4

    if diff == 1 then
        self:turnRight()
    elseif diff == 2 then
        self:turnRight()
        self:turnRight()
    elseif diff == 3 then
        self:turnLeft()
    end
end

--- @param self MoveService
--- @param targetX number
--- @param targetZ number
--- @return boolean
function MoveService:moveHorizontal(targetX, targetZ)
    self.droneState:updatePosition()
    local currentPos = self.droneState:getPosition()

    -- X
    local diffX = targetX - currentPos.x
    if diffX ~= 0 then
        if diffX > 0 then
            self:turnTo(1) -- (+X)
        else
            self:turnTo(3) -- (-X)
        end
        for _ = 1, math.abs(diffX) do
            if not turtle.forward() then
                self.droneState:updatePosition()
                return false
            end
        end
    end

    self.droneState:updatePosition()
    currentPos = self.droneState:getPosition()

    -- Z
    local diffZ = targetZ - currentPos.z
    if diffZ ~= 0 then
        if diffZ > 0 then
            self:turnTo(2) -- (+Z)
        else
            self:turnTo(0) -- (-Z)
        end
        for _ = 1, math.abs(diffZ) do
            if not turtle.forward() then
                self.droneState:updatePosition()
                return false
            end
        end
    end

    self.droneState:updatePosition()
    return true
end

return MoveService