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
--- @field droneNet DroneNet
--- @field moveTo fun(self: MoveService, target: Vec)
--- @field moveToWithFunction fun(self: MoveService, target: Vec, func: function)
--- @field startUpStatus fun(self: MoveService, message: Message)
--- @field finishUpdate fun(self: MoveService, message: Message)
--- @field currentDirection ECurrentDirection
--- @field currentMoveState EMoveState
--- @field moveTest fun(self: MoveService)

local Vec               = require("lib.vec")
local GpsUtil           = require("lib.gps_util")
local Message           = require("lib.net.msg")
local EMoveState        = require("lib.move_status_enum").EMoveState
local ECurrentDirection = require("lib.move_status_enum").ECurrentDirection

local MoveService       = {}
MoveService.__index     = MoveService

--- @param droneState DroneState
--- @return MoveService
function MoveService.new(droneState)
    local self = setmetatable({}, MoveService)
    self.droneState = droneState
    self.droneNet = nil
    self.currentDirection = ECurrentDirection.VERTICAL
    self.currentMoveState = EMoveState.WAIT
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

    if delta.z == -1 then
        newDirection = 0                       -- (-Z)
    elseif delta.x == 1 then
        newDirection = 1                       -- (+X)
    elseif delta.z == 1 then
        newDirection = 2                       -- (+Z)
    elseif delta.x == -1 then
        newDirection = 3                       -- (-X)
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

--- @param self MoveService
--- @param message Message
function MoveService:startUpStatus(message)
    local state = message.payload.state
    local direction = message.payload.direction
    print("startUpStatus: state: " .. state .. ", dir: " .. direction)
    self.currentMoveState = state
    self.currentDirection = direction
end

--- @param self MoveService
--- @param message Message
function MoveService:finishUpdate(message)
    if self.currentMoveState == EMoveState.FINISH_OUT then
        print("finishUpdate: currentMoveState is FINISH_OUT")
        return
    end
    local state = message.payload.state
    local direction = message.payload.direction
    print("finishUpdate: state: " .. state .. ", dir: " .. direction)
    self.currentMoveState = state
    self.currentDirection = direction
end

--- @param self MoveService
--- @param target Vec
function MoveService:moveTo(target)
    self.currentMoveState = EMoveState.WAIT
    self.currentDirection = ECurrentDirection.VERTICAL
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/start/up", "", self.droneState.id, {}))
    print("1) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    while self.currentMoveState == EMoveState.WAIT do
        sleep(1)
    end
    print("1) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    self:moveVertical(self.droneState.baseY + self.droneState.delta)
    self.currentMoveState = EMoveState.FINISH
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/finish/up", "", self.droneState.id, {}))
    print("2) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    while self.currentMoveState == EMoveState.FINISH and self.currentDirection == ECurrentDirection.VERTICAL do
        sleep(1)
    end
    print("2) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    self:moveHorizontal(target.x, target.z)
    self.currentMoveState = EMoveState.FINISH
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/finish/horizontal", "", self.droneState.id, {}))
    print("3) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    while self.currentMoveState == EMoveState.FINISH and self.currentDirection == ECurrentDirection.HORIZONTAL do
        sleep(1)
    end
    print("3) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    self:moveVertical(target.y)
    self.currentMoveState = EMoveState.FINISH_OUT
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/finish/down", "", self.droneState.id, {}))
end

--- @param self MoveService
--- @param target Vec
--- @param func function
function MoveService:moveToWithFunction(target, func)
    print("moveToWithFunction")
    self.currentMoveState = EMoveState.WAIT
    self.currentDirection = ECurrentDirection.VERTICAL
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/start/up", "", self.droneState.id, {}))
    print("F1) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    while self.currentMoveState == EMoveState.WAIT do
        sleep(1)
    end
    print("F1) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    func()
    self:moveVertical(self.droneState.baseY + self.droneState.delta)
    self.currentMoveState = EMoveState.FINISH
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/finish/up", "", self.droneState.id, {}))
    print("F2) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    while self.currentMoveState == EMoveState.FINISH and self.currentDirection == ECurrentDirection.VERTICAL do
        sleep(1)
    end
    print("F2) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    self:moveHorizontal(target.x, target.z)
    self.currentMoveState = EMoveState.FINISH
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/finish/horizontal", "", self.droneState.id, {}))
    print("F3) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    while self.currentMoveState == EMoveState.FINISH and self.currentDirection == ECurrentDirection.HORIZONTAL do
        sleep(1)
    end
    print("F3) Move state: " .. self.currentMoveState .. ", direction: " .. self.currentDirection)
    self:moveVertical(target.y)
    self.currentMoveState = EMoveState.FINISH_OUT
    self.droneNet:sendToHub(Message.new(
        "/hub/requests/drone/move/finish/down", "", self.droneState.id, {}))
end

--- @param self MoveService
function MoveService:moveTest()
    self:moveTo(self.droneState.targetPosition)
    self:moveTo(self.droneState.initialPos)
end

return MoveService
