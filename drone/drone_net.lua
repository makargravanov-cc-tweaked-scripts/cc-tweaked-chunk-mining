
--- @class DroneNet
--- @field droneState DroneState
--- @field dispatch fun(self: DroneNet, senderID: integer|number|nil, msg: Message|nil)

local router = require("lib.net.router").new()

local DroneNet = {}

DroneNet.__index = DroneNet

--- @param droneState DroneState
--- @return DroneNet
--- @constructor
function DroneNet.new(droneState)
    local self = setmetatable({}, DroneNet)
    self.droneState = droneState
    return self
end

--- @param self DroneNet
--- @param senderID integer|number|nil
--- @param msg Message|nil
function DroneNet:dispatch(senderID, msg)
    if senderID ~= self.droneState:getHubId() then
        return
    end
    if msg == nil then
        return
    end
    router:dispatch(msg.path, msg)
end

return DroneNet