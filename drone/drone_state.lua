
local DroneState = {}
local GpsUtil = require("lib.gps_util")

DroneState.__index = DroneState

function DroneState.new()
    local self = setmetatable({id = turtle.getID(),
                               hubId = -1,
                               isRegistered = false,
                               position = GpsUtil.position(),
                               currentTask = nil,
                              }, DroneState)
    self.currentTask = nil
    self.taskHistory = {}
    return self
end

function DroneState:getId()
    return self.id
end

function DroneState:getHubId()
    return self.hubId
end

function DroneState:isRegistered()
    return self.isRegistered
end

function DroneState:register(hubId)
    self.isRegistered = true
    self.hubId = hubId
end

function DroneState:unregister()
    self.isRegistered = false
    self.hubId = -1
end

function DroneState:getPosition()
    return self.position
end

function DroneState:updatePosition()
    self.position = GpsUtil.position()
end

function DroneState:getTask()
    return self.currentTask
end

function DroneState:setTask(task)
    self.currentTask = task
end

return DroneState