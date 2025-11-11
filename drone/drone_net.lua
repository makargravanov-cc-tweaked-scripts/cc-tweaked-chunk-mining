
--- @class DroneNet
--- @field droneState DroneState
--- @field registryService RegistryService
--- @field moveService MoveService
--- @field dispatch fun(self: DroneNet, senderID: integer|number|nil, msg: Message|nil)
--- @field send fun(self: DroneNet, targetId: integer, msg: Message)
--- @field sendToHub fun(self: DroneNet, msg: Message)
--- @field new fun(droneState: DroneState, registryService: RegistryService): DroneNet
--- @field init fun(self: DroneNet)

local router = require("lib.net.router").new()
local msg    = require("lib.net.msg")
local InventoryService = require("drone.services.inventory_service")

local DroneNet = {}

DroneNet.__index = DroneNet

--- @param droneState DroneState
--- @param registryService RegistryService
--- @return DroneNet
--- @constructor
function DroneNet.new(droneState, registryService, moveService)
    local self = setmetatable({}, DroneNet)
    self.droneState = droneState
    self.registryService = registryService
    self.moveService = moveService
    return self
end

--- @param self DroneNet
function DroneNet:init()
    router:registerRoute("/drone/discovery", function(message)
        local responseMsg = self.registryService:discovery(message)
        DroneNet.send(responseMsg.callbackId, responseMsg)
    end)
    router:registerRoute("/drone/register", function(message)
        self.registryService:register(message)
    end)
    router:registerRoute("/drone/unload-approved", function(message)
        InventoryService.unloadApproved(self.droneState, message)
    end)
    router:registerRoute("/drone/fuel-approved", function(message)
        -- NOT IMPLEMENTED
    end)
    router:registerRoute("/drone/pod-unsubscribe-approved", function(message)
        -- NOT IMPLEMENTED
    end)
--------------------------------------------------------------------------
    router:registerRoute("/drone/move/start/up/status", function(message)
        self.moveService:startUpStatus(message)
    end)
    router:registerRoute("/drone/move/finish/update", function(message)
        self.moveService:finishUpdate(message)
    end)

end

--- @param self DroneNet
--- @param senderID integer|number|nil
--- @param msg Message|nil
function DroneNet:dispatch(senderID, msg)
    if senderID ~= self.droneState:getHubId() and self.droneState:getHubId() ~= -1 then
        print("drone net dispatch: senderID ~= self.droneState:getHubId() and self.droneState:getHubId() ~= -1")
        return
    end
    if msg == nil then
        print("drone net dispatch: msg == nil")
        return
    end
    print("drone net dispatch: router:dispatch(msg.path, msg)")
    router:dispatch(msg.path, msg)
end

--- 
--- @param targetId integer
--- @param msg Message
function DroneNet.send(targetId, msg)
    router.send(targetId, msg)
end

--- @param self DroneNet
--- @param msg Message
function DroneNet:sendToHub(msg)
    router.send(self.droneState:getHubId(), msg)
end

return DroneNet