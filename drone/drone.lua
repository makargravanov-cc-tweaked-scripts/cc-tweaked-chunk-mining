local EDroneTask = require "lib.drone_tasks_enum"
--- @class Drone
--- @field droneState DroneState
--- @field moveService MoveService
--- @field registryService RegistryService
--- @field droneNet DroneNet
--- @field miningService MiningService
--- @field msgQueue ConcurrentQueue
--- @field new fun(): Drone
--- @field listenCommands fun(self: Drone)
--- @field processCurrentAction fun(self: Drone)

local Drone = {}
Drone.__index = Drone

function Drone.new()
    local ConcurrentQueue = require("lib.concurrent.concurrent_queue")
    
    local droneState = require("drone.drone_state").new()
    local moveService = require("drone.services.move_service").new(droneState)
    local registryService = require("drone.services.registry_service").new(droneState, moveService)
    local droneNet = require("drone.drone_net").new(droneState, registryService, moveService)
    
    -- Set up circular dependencies after all objects are created
    droneNet.moveService = moveService
    droneNet:init()
    moveService.droneNet = droneNet
    
    local miningService = require("drone.services.mining_service").new(droneState, moveService)
    
    local self = setmetatable({}, Drone)
    self.droneState = droneState
    self.moveService = moveService
    self.registryService = registryService
    self.droneNet = droneNet
    self.miningService = miningService
    self.msgQueue = ConcurrentQueue.new()
    return self
end


--- @param self Drone
function Drone:listenCommands()
    while true do
        local event, senderID, msg, protocol = os.pullEvent("rednet_message")
        if protocol == "mining_drone_protocol" then
            self.msgQueue:push({ sender = senderID, msg = msg })
        end
    end
end

--- @param self Drone
function Drone:processQueue()
    while true do
        if not self.msgQueue:isEmpty() then
            local item = self.msgQueue:pull()
            if item then
                local ok, err = pcall(function()
                    self.droneNet:dispatch(item.sender, item.msg)
                end)
                if not ok then
                    print("Error in dispatch:", tostring(err))
                end
            end
        else
            os.sleep(0.1)
        end
    end
end

--- @param self Drone
function Drone:processCurrentAction()
    while true do
        if self.droneState.currentTask == EDroneTask.IDLE then
        elseif self.droneState.currentTask == EDroneTask.TEST_MOVE then
            self.moveService:moveTest()
            self.droneState.currentTask = EDroneTask.IDLE
        elseif self.droneState.currentTask == EDroneTask.MINING then
        end
        os.sleep(1)
    end
end

return Drone