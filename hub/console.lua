--- @class Console
--- @field hubState HubState
--- @field droneService DroneService
--- @field width integer
--- @field heigh integer
--- @field monitor ccTweaked.peripheral.wrappedPeripheral|nil
--- @field new fun(hubState: HubState, droneService: DroneService): Console
--- @field run fun(self: Console)
--- @field handleHelp fun(self: Console)
--- @field handleStatus fun(self: Console)
--- @field handleListDrones fun(self: Console)
--- @field handleSearchDrones fun(self: Console)
--- @field handleRegisterChunks fun(self: Console)
--- @field handleShowChunks fun(self: Console)
--- @field handleChunkClick fun(self: Console, mouseX: number, mouseY: number)
--- @field handleQuit fun(self: Console): boolean
--- @field handleUnknownCommand fun(self: Console, cmd: string)
--- @field assignDroneToChunk fun(self: Console, chunkId: string): boolean
--- @field unassignDroneFromChunk fun(self: Console, chunkId: string): boolean
--- @field displayChunkGrid fun(self: Console): boolean

local Console = {}
Console.__index = Console

--- @param hubState HubState
--- @param droneService DroneService
--- @return Console
--- @constructor
function Console.new(hubState, droneService)
    local self = setmetatable({}, Console)
    self.hubState = hubState
    self.droneService = droneService
    self.monitor = nil
    self.width, self.heigh = term.getSize()
    return self
end

--- Handles the "help" command
--- @param self Console
function Console:handleHelp()
    print("Available commands:")
    print("  help           - Show this help message")
    print("  status         - Show hub status and statistics")
    print("  list-drones    - List all registered drone IDs")
    print("  search-drones  - Search for and register new drones")
    print("  register-chunks - Register 5x5 grid of chunks around hub")
    print("  show-chunks    - Display 5x5 chunk grid visualization")
    print("  quit/exit      - Exit the console")
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

--- Handles the "search-drones" command
--- @param self Console
function Console:handleSearchDrones()
    print("Searching for drones...")
    self.droneService:searchForDrones()
    print("Discovery message sent. Waiting for responses...")
end

--- Handles the "register-chunks" command
--- @param self Console
function Console:handleRegisterChunks()
    self.hubState:registerChunksGrid(5)
end

--- Handles mouse click on a chunk in the grid visualization
--- @param self Console
--- @param mouseX number
--- @param mouseY number
function Console:handleChunkClick(mouseX, mouseY)
    local centerChunk = self.hubState:getCenterChunk()
    if not centerChunk then
        print("Error: Hub position not set. Cannot handle chunk click.")
        return
    end

    local gridSize = 5




end

--- Attempts to assign an available drone to a chunk
--- @param self Console
--- @param chunkId string
--- @return boolean success
function Console:assignDroneToChunk(chunkId)
    -- Find an unassigned drone from the registered drones
    for _, droneId in ipairs(self.hubState.drones) do
        local isAssigned = false
        -- Check if this drone is already assigned to any chunk
        for assignedDroneId, _ in pairs(self.hubState.droneAssignment) do
            if assignedDroneId == droneId then
                isAssigned = true
                break
            end
        end
        
        if not isAssigned then
            -- Assign this drone to the chunk
            -- For now, assign the first range in the chunk (range index 1)
            local ranges = self.hubState.chunkWorkMap[chunkId]
            if ranges and ranges[1] then
                self.hubState:assignDrone(droneId.id, chunkId, 1)
                return true
            end
        end
    end
    return false  -- No available drones
end

--- Unassigns any drone assigned to a chunk
--- @param self Console
--- @param chunkId string
function Console:unassignDroneFromChunk(chunkId)
    -- Find which drone is assigned to this chunk and unassign it
    for droneId, assignment in pairs(self.hubState.droneAssignment) do
        if assignment.chunkId == chunkId then
            self.hubState:unassignDrone(droneId)
            break
        end
    end
end

--- Displays the chunk grid visualization
--- @param self Console
function Console:displayChunkGrid()
    local centerChunk = self.hubState:getCenterChunk()
    if not centerChunk then
        print("Error: Hub position not set. Cannot display chunks.")
        return
    end

    local gridSize = 5
    
    print(self.heigh .. " - " .. self.width)

    -- Print legend
    print("")
    term.setTextColor(colors.black)
    term.setBackgroundColor(colors.black)
    io.write("██")
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    print(" - Not registered")

    term.setTextColor(colors.blue)
    term.setBackgroundColor(colors.blue)
    io.write("██")
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    print(" - Center chunk")

    term.setTextColor(colors.red)
    term.setBackgroundColor(colors.red)
    io.write("██")
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    print(" - Registered, no drone")

    term.setTextColor(colors.green)
    term.setBackgroundColor(colors.green)
    io.write("██")
    term.setTextColor(colors.white)
    term.setBackgroundColor(colors.black)
    print(" - Has assigned drone")
    print("Click on a chunk square to assign/unassign a drone. Press 'q' to exit.")
end

--- Handles the "show-chunks" command
--- @param self Console
function Console:handleShowChunks()
    self.monitor = peripheral.wrap("top");
    if self.monitor ~= nil then
        term.redirect(self.monitor)
         -- Display the chunk grid initially
        self:displayChunkGrid()
    -- Enter an interactive loop to handle mouse clicks and keyboard input
        while true do
            local event, p1, p2, p3 = os.pullEvent()

            if event == "mouse_click" then
                local button, mouseX, mouseY = p1, p2, p3
                if button == 1 then  -- Left mouse button
                    self:handleChunkClick(mouseX, mouseY)
                    -- Redraw the grid to show updated status
                    self:displayChunkGrid()
                end
            elseif event == "char" then
                if p1 == "q" then
                    break
                end
            end
        end
        term.redirect(term.native())
    else
        print("No monitor on top")
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
        elseif cmd == "search-drones" then
            self:handleSearchDrones()
        elseif cmd == "register-chunks" then
            self:handleRegisterChunks()
        elseif cmd == "show-chunks" then
            self:handleShowChunks()
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
