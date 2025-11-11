
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
    router:registerRoute("/hub/requests/drone/unload", function(message)
        self.droneService:processInventoryUnload(message)
    end)
    router:registerRoute("/hub/requests/drone/refuel", function(message)
        self.droneService:processRefuel(message)
    end)
    router:registerRoute("/hub/requests/drone/unload/release", function(message)
        self.droneService:processInventoryUnloadRelease(message)
    end)
    router:registerRoute("/hub/requests/drone/refuel/release", function(message)
        self.droneService:processRefuelRelease(message)
    end)
    router:registerRoute("/hub/requests/drone/move/start/up", function(message)
        self.droneService:processStartUp(message)
    end)
    router:registerRoute("/hub/requests/drone/move/finish/up", function(message)
        self.droneService:processFinishUp(message)
    end)
    router:registerRoute("/hub/requests/drone/move/finish/horizontal", function(message)
        self.droneService:processFinishHorizontal(message)
    end)
    router:registerRoute("/hub/requests/drone/move/finish/down", function(message)
        self.droneService:processFinishDown(message)
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