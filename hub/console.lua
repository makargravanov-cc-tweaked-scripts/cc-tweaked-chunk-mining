
--- @class Console
--- @field hubState HubState
--- @field new fun(hubState: HubState): Console
--- @field run fun(self: Console)
--- @field handleHelp fun(self: Console)
--- @field handleStatus fun(self: Console)
--- @field handleListDrones fun(self: Console)
--- @field handleQuit fun(self: Console): boolean
--- @field handleUnknownCommand fun(self: Console, cmd: string)

local Console = {}
Console.__index = Console

--- @param hubState HubState
--- @return Console
--- @constructor
function Console.new(hubState)
    local self = setmetatable({}, Console)
    self.hubState = hubState
    return self
end

--- Handles the "help" command
--- @param self Console
function Console:handleHelp()
    print("Available commands:")
    print("  help          - Show this help message")
    print("  status        - Show hub status and statistics")
    print("  list-drones   - List all registered drone IDs")
    print("  quit/exit     - Exit the console")
end

--- Handles the "status" command
--- @param self Console
function Console:handleStatus()
    print("Hub ID:", tostring(self.hubState.id))
    local pos = self.hubState.position
    if pos and pos.x and pos.y and pos.z then
        print("Position:", pos.x .. "," .. pos.y .. "," .. pos.z)
    else
        print("Position: Not set")
    end
    print("Registered drones:", #self.hubState.drones)
    local chunkCount = 0
    for _ in pairs(self.hubState.chunkWorkMap) do chunkCount = chunkCount + 1 end
    print("Chunks tracked:", chunkCount)
end

--- Handles the "list-drones" command
--- @param self Console
function Console:handleListDrones()
    if #self.hubState.drones == 0 then
        print("No drones registered.")
    else
        local droneList = {}
        for _, id in ipairs(self.hubState.drones) do
            table.insert(droneList, tostring(id))
        end
        print("Registered drone IDs: " .. table.concat(droneList, ", "))
    end
end

--- Handles the "quit" or "exit" command
--- @param self Console
--- @return boolean Returns true if should exit
function Console:handleQuit()
    print("Console exiting.")
    return true
end

--- Handles unknown commands
--- @param self Console
--- @param cmd string The unknown command
function Console:handleUnknownCommand(cmd)
    print("Unknown command. Type 'help' for available commands.")
end

--- Main console loop
--- @param self Console
function Console:run()
    print("Hub console started. Type 'help' for available commands or 'quit' to exit.")
    while true do
        io.write("hub> ")
        local line = read()
        if not line then break end
        local cmd = line:lower()

        if cmd == "help" then
            self:handleHelp()
        elseif cmd == "status" then
            self:handleStatus()
        elseif cmd == "list-drones" then
            self:handleListDrones()
        elseif cmd == "quit" or cmd == "exit" then
            if self:handleQuit() then
                break
            end
        elseif cmd ~= "" then
            self:handleUnknownCommand(cmd)
        end
    end
end

return Console

