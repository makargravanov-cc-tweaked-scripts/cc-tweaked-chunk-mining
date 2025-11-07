
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

local function splitWords(s)
    local t={}
    for w in s:gmatch("%S+") do table.insert(t,w) end
    return t
end

function Hub:consoleLoop()
    print("Hub console started. Type 'help' for available commands or 'quit' to exit.")
    while true do
        io.write("hub> ")
        local line = read()
        if not line then break end
        local cmd = line:lower()

        if cmd == "help" then
            print("Available commands:")
            print("  help          - Show this help message")
            print("  status        - Show hub status and statistics")
            print("  list-drones   - List all registered drone IDs")
            print("  quit/exit     - Exit the console")

        elseif cmd == "status" then
            print("Hub ID:", tostring(self.hubState.id))
            local pos = self.hubState.position
            print("Position:", pos.x .. "," .. pos.y .. "," .. pos.z)
            print("Registered drones:", #self.hubState.drones)
            local chunkCount = 0
            for _ in pairs(self.hubState.chunkWorkMap) do chunkCount = chunkCount + 1 end
            print("Chunks tracked:", chunkCount)

        elseif cmd == "list-drones" then
            if #self.hubState.drones == 0 then
                print("No drones registered.")
            else
                local droneList = {}
                for _, id in ipairs(self.hubState.drones) do
                    table.insert(droneList, tostring(id))
                end
                print("Registered drone IDs: " .. table.concat(droneList, ", "))
            end

        elseif cmd == "quit" or cmd == "exit" then
            print("Console exiting.")
            break

        elseif cmd ~= "" then
            print("Unknown command. Type 'help' for available commands.")
        end
    end
end


return Hub