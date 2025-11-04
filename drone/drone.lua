
local Drone = {}
local taskQueue = require("lib.concurrent.concurrent_queue").new()
local droneState = require("drone.drone_state").new()
local moveService = require("drone.services.move_service").new(droneState)
local registryService = require("drone.services.registry_service").new(droneState, moveService)
local droneNet = require("drone.drone_net").new(droneState, registryService)
droneNet:init()


local miningService = require("drone.services.mining_service").new(droneState, moveService)



function Drone.listenCommands()
    while true do
        local senderID, msg = rednet.receive("mining_drone_protocol")
        print("senderId = " .. senderID)
---@diagnostic disable-next-line: param-type-mismatch
        droneNet:dispatch(senderID, msg)
        os.sleep(0.1)
    end
end

-- function Drone.doTasks()
--     while true do
--         if not taskQueue:isEmpty() then
--             local task = taskQueue:pull()
--             droneState:setTask(task.msg)
--         end
--         os.sleep(0.1)
--     end
-- end

return Drone