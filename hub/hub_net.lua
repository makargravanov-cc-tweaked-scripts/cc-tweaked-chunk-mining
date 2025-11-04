
--- @class HubNetwork
--- @field public droneService DroneService
--- @field public dispatch fun(self: HubNetwork, msg: Message)
--- @field public send fun(self: HubNetwork, droneId: integer, msg: Message)
--- @field public new fun(droneService: DroneService): HubNetwork
--- @field public sendNoTarget fun(msg: Message)
--- @field public init fun(self: HubNetwork)

local router = require("lib.net.router").new()

local HubNetwork = {}
HubNetwork.__index = HubNetwork

--- @param droneService DroneService
--- @return HubNetwork
--- @constructor
function HubNetwork.new(droneService)
    local self = setmetatable({}, HubNetwork)
    self.droneService = droneService
    return self
end

--- @param self HubNetwork
function HubNetwork:init()
    router:registerRoute("/hub/responses/drone/discovery", function(message)
        self.droneService:registerDrone(message)
    end)
end

--- @param msg Message
function HubNetwork:dispatch(msg)
    router:dispatch(msg.path, msg)
end

--- @param droneId integer
--- @param msg Message
function HubNetwork.send(droneId, msg)
    router.send(droneId, msg)
end

--- @param msg Message
function HubNetwork.sendNoTarget(msg)
    router.sendNoTarget(msg)
end

return HubNetwork