
--- @class DroneService
--- @field hubState HubState
--- @field new fun(hubState: HubState): DroneService
--- @field searchForDrones fun(self: DroneService)
--- @field registerDrone fun(self: DroneService, droneId: integer)
--- @field unregisterDrone fun(self: DroneService, droneId: integer)

local HubState = require("hub/hub_state")
local HubNetwork = require("hub/hub_net")
local Message = require("lib.net.msg")

local msg = require("lib.net.msg")
local DroneService = {}
DroneService.__index = DroneService

--- @param hubState HubState
--- @return DroneService
function DroneService.new(hubState)
    local self = setmetatable({}, DroneService)
    self.hubState = hubState
    return self
end

--- @param self DroneService
function DroneService:searchForDrones()
    local discoveryMsg = msg.new("/drone/discover",
    "/hub/responses/drone/discovery",
    self.hubState.id, {
        position = self.hubState.position,
        distance = 32
    })
    HubNetwork.sendNoTarget(discoveryMsg)
end

--- comment
--- @param self DroneService
--- @param msg Message
function DroneService:registerDrone(msg)
    ---@type integer
    local droneId = msg.payload.droneId
    ---@type boolean
    local registered = msg.payload.registered
    ---@type boolean
    local distanceCheck = msg.payload.distanceCheck

    if not registered and distanceCheck then
        self.hubState:registerDrone(droneId)
        local responseMsg = Message.new("/drone/register","", self.hubState.id, {
            hubId = self.hubState.id,
            droneId = droneId
        })
        HubNetwork.send(droneId, responseMsg)
        print("Registered drone with ID: "..droneId)
    end
end

function DroneService:unregisterDrone(droneId)
    -- Implementation for unregistering a drone
end

return DroneService