
--- @class Hub
--- @field hubState HubState
--- @field droneService DroneService
--- @field hubNet HubNetwork
--- @field initialize fun(self: Hub)
--- @field listenCommands fun(self: Hub)
--- @field new fun(hubState: HubState, droneService: DroneService): Hub

local Hub = {}
Hub.__index = Hub

--- @param hubState HubState
--- @param droneService DroneService
--- @return Hub
--- @constructor
function Hub.new(hubState, droneService)
    local self = setmetatable({}, Hub)
    self.hubState = hubState
    self.droneService = droneService
    self.hubNet = require("hub/hub_net").new(droneService)
    self.hubNet:init()
    return self
end

--- @param self Hub
function Hub:listenCommands()
    while true do
        local senderID, msg = rednet.receive("mining_drone_protocol")
        ---@diagnostic disable-next-line: param-type-mismatch
        self.hubNet:dispatch(msg)
        os.sleep(0.1)
    end
end

--- @param self Hub
function Hub:initialize()
    self.droneService:searchForDrones()
end

return Hub