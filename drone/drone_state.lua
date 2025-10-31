
---@class DroneState
---@field id number
---@field hubId number
---@field registered boolean
---@field position Vec
---@field currentTask EDroneTask|nil
---@field new fun(): DroneState
---@field getId fun(self: DroneState): number
---@field getHubId fun(self: DroneState): number
---@field isRegistered fun(self: DroneState): boolean
---@field register fun(self: DroneState, hubId: number)
---@field unregister fun(self: DroneState)
---@field getPosition fun(self: DroneState): Vec
---@field updatePosition fun(self: DroneState)
---@field getTask fun(self: DroneState): EDroneTask|nil
---@field setTask fun(self: DroneState, task: EDroneTask)

local DroneState = {}
local GpsUtil = require("lib.gps_util")
local EDroneTask = require("lib.drone_tasks_enum")

DroneState.__index = DroneState

---@return DroneState
function DroneState.new()
    local self = setmetatable({id = turtle.getID(),
                               hubId = -1,
                               registered = false,
                               position = GpsUtil.position(),
                               currentTask = EDroneTask.IDLE,
                              }, DroneState)
    self.currentTask = EDroneTask.IDLE
    return self
end

---@param self DroneState
---@return number
function DroneState:getId()
    return self.id
end

---@param self DroneState
---@return number
function DroneState:getHubId()
    return self.hubId
end

---@param self DroneState
---@return boolean
function DroneState:isRegistered()
    return self.registered
end

---@param self DroneState
---@param hubId number
function DroneState:register(hubId)
    self.registered = true
    self.hubId = hubId
end

---@param self DroneState
function DroneState:unregister()
    self.registered = false
    self.hubId = -1
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

return DroneState