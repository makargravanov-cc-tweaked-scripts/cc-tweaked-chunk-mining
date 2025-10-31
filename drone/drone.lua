
local Drone = {}
local taskQueue = require("lib.concurrent_queue").new()
local droneState = require("drone_state")

function Drone.listenCommands()
    while true do
        local senderID, msg = rednet.receive("turtle_hub")
        taskQueue:push({senderID=senderID, msg=msg})
    end
end

function Drone.doTasks()
    while true do
        if not taskQueue:isEmpty() then
            local task = taskQueue:pull()
            executeTask(task)
        end
        os.sleep(0.1)
    end
end

return Drone