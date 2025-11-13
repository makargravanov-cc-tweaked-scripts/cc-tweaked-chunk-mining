
---@class DroneState
---@field id integer
---@field hubId integer
---@field registered boolean
---@field position Vec
---@field currentTask EDroneTask|nil
---@field lock boolean
---@field new fun(): DroneState
---@field getId fun(self: DroneState): integer
---@field getHubId fun(self: DroneState): integer
---@field isRegistered fun(self: DroneState): boolean
---@field register fun(self: DroneState, hubId: integer)
---@field unregister fun(self: DroneState)
---@field getPosition fun(self: DroneState): Vec
---@field updatePosition fun(self: DroneState)
---@field getTask fun(self: DroneState): EDroneTask|nil
---@field setTask fun(self: DroneState, task: EDroneTask)
---@field updateDirection fun(self: DroneState, direction: number)
---@field getDirection fun(self: DroneState): number
---@field direction number
---@field waitingForUnloading boolean
---@field setWaitingForUnloading fun(self: DroneState, waitingForUnloading: boolean)
---@field waitingForRefueling boolean
---@field setWaitingForRefueling fun(self: DroneState, waitingForRefueling: boolean)
---
---@field targetPosition Vec
---@field setTargetPosition fun(self: DroneState, position: Vec)
---
---@field refuelingPosition Vec
---@field setRefuelingPosition fun(self: DroneState, position: Vec)
---@
---@field baseY       integer
---@field highYDig    integer
---@field lowYDig     integer
---@field delta       integer
---@field startNumber integer
---@field targetNumber integer
---@field initialPos Vec

local DroneState = {}
local GpsUtil = require("lib.gps_util")
local EDroneTask = require("lib.drone_tasks_enum")

DroneState.__index = DroneState

---@return DroneState
function DroneState.new()
    local self = setmetatable({id = os.getComputerID(),
                               hubId = -1,
                               registered = false,
                               position = GpsUtil.position(),
                               currentTask = EDroneTask.IDLE,
                               lock = false,
                               direction = 0,
                               waitingForUnloading = false,
                               targetPosition = nil,
                               refuelingPosition = nil,
                               baseY = 0,
                               highYDig = 0,
                               lowYDig = 0,
                               delta = 0,
                               initialPos = GpsUtil.position(),
                               startNumber = 0,
                               targetNumber = 0
                              }, DroneState)
    self.currentTask = EDroneTask.IDLE
    return self
end

-- @param self DroneState
-- @param waitingForUnloading boolean
function DroneState:setWaitingForUnloading(waitingForUnloading)
    self.waitingForUnloading = waitingForUnloading
end

-- @param self DroneState
-- @param waitingForRefueling boolean
function DroneState:setWaitingForRefueling(waitingForRefueling)
    self.waitingForRefueling = waitingForRefueling
end

--- 
--- @param self DroneState
--- @param position Vec
function DroneState:setTargetPosition(position)
    self.targetPosition = position
end

--- @param self DroneState
--- @param position Vec
function DroneState:setRefuelingPosition(position)
    self.refuelingPosition = position
end

---@param self DroneState
---@return integer
function DroneState:getId()
    return self.id
end

---@param self DroneState
---@return integer
function DroneState:getHubId()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local hubId = self.hubId
    self.lock = false
    return hubId
end

---@param self DroneState
---@return boolean
function DroneState:isRegistered()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local registered = self.registered
    self.lock = false
    return registered
end

---@param self DroneState
---@param hubId integer
function DroneState:register(hubId)
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    self.registered = true
    self.hubId = hubId
    self.lock = false
end

---@param self DroneState
function DroneState:unregister()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    self.registered = false
    self.hubId = -1
    self.lock = false
end

---@param self DroneState
---@return Vec
function DroneState:getPosition()
    return self.position
end

---@param self DroneState
function DroneState:updatePosition()
    self.position = GpsUtil.position()
end

---@param self DroneState
function DroneState:getTask()
    return self.currentTask
end

---@param self DroneState
function DroneState:setTask(task)
    self.currentTask = task
end

---@param self DroneState
---@param direction number
function DroneState:updateDirection(direction)
    self.direction = direction
end

function DroneState:getDirection()
    return self.direction
end

return DroneState