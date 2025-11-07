
--- @class Hub
--- @field hubState HubState
--- @field droneService DroneService
--- @field hubNet HubNetwork
--- @field msgQueue ConcurrentQueue
--- @field initialize fun(self: Hub)
--- @field listenCommands fun(self: Hub)
--- @field new fun(hubState: HubState, droneService: DroneService): Hub
--- @field processQueue fun(self: Hub)
--- @field consoleLoop fun(self: Hub)

local ConcurrentQueue = require("lib.concurrent.concurrent_queue")

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
    self.msgQueue = ConcurrentQueue.new()
    return self
end

--- @param self Hub
function Hub:listenCommands()
    while true do
        local event, senderID, msg, protocol = os.pullEvent("rednet_message")
        if protocol == "mining_drone_protocol" then
            self.msgQueue:push({ sender = senderID, msg = msg })
        end
    end
end

--- @param self Hub
function Hub:processQueue()
    while true do
        if not self.msgQueue:isEmpty() then
            local item = self.msgQueue:pull()
            if item then
                local ok, err = pcall(function()
                    self.hubNet:dispatch(item.msg)
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

--- @param self Hub
function Hub:initialize()
    self.droneService:searchForDrones()
    
end

--- @param self Hub
function Hub:consoleLoop()
    local Console = require("hub/console")
    local console = Console.new(self.hubState, self.droneService)
    console:run()
end


return Hub