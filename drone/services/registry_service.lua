
--- @class RegistryService
--- @field droneState DroneState
--- @field new fun(droneState: DroneState): RegistryService
--- @field discovery fun(self: RegistryService, msg: Message): Message
--- @field register fun(self: RegistryService, msg: Message)

local Message = require("lib.net.msg")
local Vec = require("lib.vec")

local RegistryService = {}
RegistryService.__index = RegistryService

--- @param droneState DroneState
--- @return RegistryService
--- @constructor
function RegistryService.new(droneState)
    local self = setmetatable({}, RegistryService)
    self.droneState = droneState
    
    return self
end

--- @param self RegistryService
--- @param msg Message
--- @return Message
function RegistryService:discovery(msg)

    --- @type Vec
    local hubPos = msg.payload.position
    --- @type integer
    local distance = msg.payload.distance
    self.droneState:updatePosition()
    local responseMsg = Message.new(msg.callbackPath,"", msg.callbackId, {
            droneId = self.droneState:getId(),
            registered = self.droneState:isRegistered(),
            distanceCheck = Vec.dist(hubPos, self.droneState:getPosition()) <= distance
        })
    return responseMsg
end

--- @param self RegistryService
--- @param msg Message
function RegistryService:register(msg)
    ---@type integer
    local hubId = msg.payload.hubId
    self.droneState:register(hubId)
    print("Registered drone with hub ID: "..hubId)
end

return RegistryService