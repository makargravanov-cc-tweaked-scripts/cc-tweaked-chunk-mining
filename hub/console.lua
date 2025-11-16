--- @class Console
--- @field hubState HubState
--- @field droneService DroneService
--- @field width integer
--- @field heigh integer
--- @field scale number
--- @field monitor ccTweaked.peripheral.wrappedPeripheral|nil
--- @field pendingChunkIds table
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
--- @field handleAssignDrones fun(self: Console, n: integer)
--- @field handleResetAssignments fun(self: Console)
--- @field parseXYZ fun(input: string): integer|nil, integer|nil, integer|nil, string|nil
--- @
--- @field handleFuel fun(self: Console)
--- @field handleCargo fun(self: Console)
--- @
--- @field handleLatency  fun(self: Console)
--- @field handleHeights  fun(self: Console)
--- @field handleTestMove fun(self: Console)
--- @
--- @field handleStartMining fun(self: Console)
--- @field handleStopMining fun(self: Console)
--- @
--- @field handleSendReboot fun(self: Console)

local FuelPod = require("hub.entities.inventory.fuel_pod")
local CargoPod = require("hub.entities.inventory.cargo_pod")
local ChunkWorkRange = require("hub.entities.chunk_work_range")
local Vec            = require("lib.vec")
local HubNet         = require("hub.hub_net")
local Message = require("lib.net.msg")
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
    self.scale = 1
    self.pendingChunkIds = {}
    self.width, self.heigh = term.getSize()
    return self
end

--- Handles the "help" command
--- @param self Console
function Console:handleHelp()
    print("Available commands:")
    print("h   help              - Show this help")
    print("s   status            - Hub status and statistics")
    print("dl  drones-list       - List registered drones")
    print("ds  drones-search     - Discover new drones nearby")
    print("cr  chunks-register   - Register 5x5 chunk grid")
    print("cs  chunks-show       - Visualize chunk grid")
    print("da  drones-assign N   - Assign N drones per selected chunk")
    print("dra drones-reset-assignments - Reset all assignments and chunk ranges")
    print("pf  fuel              - Manage fuel pods")
    print("pc  cargo             - Manage cargo pods")
    print("ln  latency-numbers   - mining latency, num of parallel started")
    print("ph  heights           - Set excavation heights (`x y z` syntax)")
    print("mt  test-move         - Test movement commands")
    print("mm  mining            - Start mining")
    print("ms  stop              - Stop mining")
    print("drb send-reboot       - Send global reboot")
    print("q   quit/exit         - Exit console")
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

        if cmd == "help" or cmd == "h" then
            self:handleHelp()
        elseif cmd == "status" or cmd == "s" then
            self:handleStatus()
        elseif cmd == "drones-list" or cmd == "dl" then
            self:handleListDrones()
        elseif cmd == "drones-search" or cmd == "ds" then
            self:handleSearchDrones()
        elseif cmd == "chunks-register" or cmd == "cr" then
            self:handleRegisterChunks()
        elseif cmd == "chunks-show" or cmd == "cs" then
            self:handleShowChunks()
        elseif cmd == "fuel" or cmd == "pf" then
            self:handleFuel()
        elseif cmd == "cargo" or cmd == "pc" then
            self:handleCargo()
        elseif cmd == "latency-numbers" or cmd == "ln" then
            self:handleLatency()
        elseif cmd == "heights" or cmd == "ph" then
            self:handleHeights()
        elseif cmd == "test-move" or cmd == "mt" then
            self:handleTestMove()
        elseif cmd == "mining" or cmd == "mm" then
            self:handleStartMining()
        elseif cmd == "stop" or cmd == "ms" then
            self:handleStopMining()
        elseif cmd:find("^drones%-assign%s") or cmd:find("^da%s") then
            local n = tonumber(cmd:match("^assign%-drones%s+(%d+)$"))
            if not n then
                n = tonumber(cmd:match("^da%s+(%d+)$"))
            end
            if not n or n < 1 then
                print("Wrong format! Example: assign-drones 2 or da 2")
            else
                self:handleAssignDrones(n)
            end
        elseif cmd == "drones-reset-assignments" or cmd == "dra" then
            self:handleResetAssignments()
        elseif cmd == "drones-reboot" or cmd == "drb" then
            self:handleSendReboot()
        elseif cmd == "quit" or cmd == "exit" or cmd == "q" then
            if self:handleQuit() then
                break
            end
        elseif cmd ~= "" then
            self:handleUnknownCommand(cmd)
        end
    end
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
    local gridSize = 5
    local offset = math.floor(gridSize / 2)
    local gridStartX = 2
    local gridStartY = 2
    local relX = mouseX - gridStartX
    local relY = mouseY - gridStartY
    if relX < 0 or relY < 0 or relX >= gridSize or relY >= gridSize then
        print("No hit in chunk!")
        return
    end

    local centerChunk = self.hubState:getCenterChunk()
    if centerChunk~=nil then
        print("relX=".. relX .. " relY=" .. relY)
        local chunkVec = { x = centerChunk.x + (relX - offset), y = 0, z = centerChunk.z + (relY - offset) }
        local chunkId = self.hubState:getChunkId(chunkVec)
        self.pendingChunkIds = self.pendingChunkIds or {}
        if not self.pendingChunkIds[chunkId] then
            self.pendingChunkIds[chunkId] = true
            print("assigned: " .. chunkId)
        else
            self.pendingChunkIds[chunkId] = nil
            print("unassigned: " .. chunkId)
        end
    else
        print("center chunk is nullptr")
    end
end

--- Attempts to assign an available drone to a chunk
--- @param self Console
--- @param chunkId string
--- @return boolean success
function Console:assignDroneToChunk(chunkId)
    -- Find an unassigned drone from the registered drones
    for _, droneEntity in ipairs(self.hubState.drones) do
        local isAssigned = false
        -- Check if this drone is already assigned to any chunk
        for assignedDroneId, _ in pairs(self.hubState.droneAssignment) do
            if assignedDroneId == droneEntity.id then
                isAssigned = true
                break
            end
        end
        
        if not isAssigned then
            -- Assign this drone to the chunk
            -- For now, assign the first range in the chunk (range index 1)
            local ranges = self.hubState.chunkWorkMap[chunkId]
            if ranges and ranges[1] then
                self.hubState:assignDrone(droneEntity.id, chunkId, 1)
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

    -- Collect all "selected for assignment" chunkIds, including already assigned
    self.pendingChunkIds = self.pendingChunkIds or {}
    for chunkId, ranges in pairs(self.hubState.chunkWorkMap) do
        local assigned = false
        for _, range in ipairs(ranges) do
            if range.assignedDroneId ~= nil then
                assigned = true
                break
            end
        end
        if assigned then
            self.pendingChunkIds[chunkId] = true
        end
    end

    self.monitor.setBackgroundColor(colors.black)
    self.monitor.clear()
    self.width, self.heigh = self.monitor.getSize()

    local gridSize = 5
    local offset = math.floor(gridSize / 2)
    for dz = -offset, offset do
        for dx = -offset, offset do
            local chunkVec = {
                x = centerChunk.x + dx,
                y = 0,
                z = centerChunk.z + dz
            }
            local chunkId = self.hubState:getChunkId(chunkVec)
            local px = dx + offset + 2
            local py = dz + offset + 2

            -- Select color for chunk
            local color
            if self.hubState:hasAssignedDrone(chunkId) then
                color = colors.green    -- Has assigned drone
            elseif self.pendingChunkIds[chunkId]  then
                color = colors.yellow   -- Selected for assignment
            elseif not self.hubState.chunkWorkMap[chunkId] then
                color = colors.black    -- Not registered
            elseif dx == 0 and dz == 0 then
                color = colors.blue     -- Center chunk
            else
                color = colors.red      -- Registered, no drone
            end

            paintutils.drawPixel(px, py, color)
        end
    end

    -- Direction labels
    self.monitor.setCursorPos(1, offset + 2)
    self.monitor.write("x")
    self.monitor.setCursorPos(gridSize + 3, offset + 2)
    self.monitor.write("X")
    self.monitor.setCursorPos(offset + 2, 1)
    self.monitor.write("z")
    self.monitor.setCursorPos(offset + 2, gridSize + 3)
    self.monitor.write("Z")

    print("Click on a chunk square to select/unselect chunk for drone assignment. Press 'q' to exit.")
    print("Legend: yellow = selected for assignment, black = not registered, blue = center, green = has drone, red = registered, no drone.")
end

--- Handles the "show-chunks" command
--- @param self Console
function Console:handleShowChunks()
    self.monitor = peripheral.wrap("top");
    if self.monitor ~= nil then
        term.redirect(self.monitor)
         -- Display the chunk grid initially
        self.monitor.setTextScale(self.scale)
        self:displayChunkGrid()
        -- Enter an interactive loop to handle mouse clicks and keyboard input
        while true do
            local event, p1, p2, p3 = os.pullEvent()
            if event == "monitor_touch" then
                local side, mouseX, mouseY = p1, p2, p3
                if side == "top" then
                    self:handleChunkClick(mouseX, mouseY)
                    self:displayChunkGrid()
                end
                print("X: " .. mouseX .. " Y: " .. mouseY)
            elseif event == "mouse_scroll" then
                self.scale = math.max(0.5, math.min(5, self.scale + 0.5 * p1))
                self.monitor.setTextScale(self.scale)
                self:displayChunkGrid()
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

function Console:handleAssignDrones(n)
    if not self.pendingChunkIds then
        print("No selected chunks!")
        return
    end

    local chunksToAssign = {}
    for chunkId, _ in pairs(self.pendingChunkIds) do
        table.insert(chunksToAssign, chunkId)
    end

    if #chunksToAssign == 0 then
        print("No selected chunks! (1)")
        return
    end

    local freeDrones = {}
    for _, droneId in ipairs(self.hubState.drones) do
        if not self.hubState.droneAssignment[droneId] then
            table.insert(freeDrones, droneId)
        end
    end

    local required = #chunksToAssign * n
    if #freeDrones < required then
        print("Too small number of drones! Required: " .. required .. ", free: " .. #freeDrones)
        return
    end

    local droneIdx = 1
    for _, chunkId in ipairs(chunksToAssign) do
        local ranges = self.hubState.chunkWorkMap[chunkId]

        if ranges and (#ranges ~= n or ranges[1].assignedDroneId ~= nil or (#ranges == 1 and ranges[1].assignedDroneId == nil)) then
            local r = ranges[1]
            local totalLen = r:getLength()
            local lenPerDrone = math.floor(totalLen / n)
            local newRanges = {}
            local fromIdx = r.from
            for i = 1, n do
                local toIdx = (i == n) and r.to or (fromIdx + lenPerDrone - 1)
                table.insert(newRanges, ChunkWorkRange.new(fromIdx, toIdx, nil))
                fromIdx = toIdx + 1
            end
            self.hubState:registerChunk(chunkId, newRanges)
            ranges = newRanges
        end

        for i = 1, n do
            local droneId = freeDrones[droneIdx]
            droneIdx = droneIdx + 1
            self.hubState:assignDrone(droneId, chunkId, i)
        end
    end

    print("Drones are assigned (" .. n .. " drones per chunk).")
    self.pendingChunkIds = {}
end


--- Resets all drone assignments and chunk ranges to default (single range per chunk, none assigned)
--- @param self Console
function Console:handleResetAssignments()
    print("Resetting all assignments and chunk ranges...")
    -- Unassign all drones first
    for _, droneEntity in ipairs(self.hubState.drones) do
        self.hubState:unassignDrone(droneEntity.id)
    end

    -- For all chunks that have been registered: reset ranges
    for chunkId, ranges in pairs(self.hubState.chunkWorkMap) do
        -- Always replace with just ONE default range
        self.hubState:registerChunk(chunkId, {ChunkWorkRange.new(1, 256, nil)})
    end

    -- Clear selection
    self.pendingChunkIds = {}

    print("All assignments and chunk work ranges reset to defaults.")
end

--- 
--- @param self Console
function Console:handleFuel()
    for _, pod in ipairs(self.hubState.fuelPods) do
        print("x: " .. pod.position.x .. ", y: " .. pod.position.y .. ", z: " .. pod.position.z)
    end
    while true do
        local line = read()
        if not line then break end
        ---@type string
        local cmd = line:lower()
        if cmd == "exit" then break end
        Console.parseXYZ(cmd)
        local x, y, z = Console.parseXYZ(cmd)
        self.hubState:addFuelPod(FuelPod.new(Vec.new(x, y, z)))
    end
end

--- @param self Console
function Console:handleCargo()
    for _, pod in ipairs(self.hubState.cargoPods) do
        print("x: " .. pod.position.x .. ", y: " .. pod.position.y .. ", z: " .. pod.position.z)
    end
    while true do
        local line = read()
        if not line then break end
        ---@type string
        local cmd = line:lower()
        if cmd == "exit" then break end
        Console.parseXYZ(cmd)
        local x, y, z = Console.parseXYZ(cmd)
        self.hubState:addCargoPod(CargoPod.new(Vec.new(x, y, z)))
    end
end

--- @param self Console
function Console:handleLatency()
    print("Latency: " .. self.hubState.latency .. "s", "Parallel started drones number: " .. self.hubState.parallelStartedDronesNumber)
    print("write 3 nubers but 3rd will ignore")
    local line = read()
    if not line then return end
    local cmd = line:lower()
    if cmd == "exit" then return end
    Console.parseXYZ(cmd)
    local x, y, z = Console.parseXYZ(cmd)
    if x == nil then return end
    if y == nil then return end
    if x < 0 then x = 0 end
    if y < 1 then y = 1 end
    self.hubState.latency = x
    self.hubState.parallelStartedDronesNumber = y
    print("Latency: " .. self.hubState.latency .. "s")
end

--- @param self Console
function Console:handleHeights()
    print("heights: baseY= " .. self.hubState.baseY .. " highYDig=" .. self.hubState.highYDig .. " lowYDig=" .. self.hubState.lowYDig)
    local line = read()
    if not line then return end
    local cmd = line:lower()
    if cmd == "exit" then return end
    Console.parseXYZ(cmd)
    local x, y, z = Console.parseXYZ(cmd)
    if x == nil or y == nil or z == nil then return end
    self.hubState.baseY = x
    self.hubState.highYDig = y
    self.hubState.lowYDig = z
    print("heights: baseY= " .. self.hubState.baseY .. " highYDig=" .. self.hubState.highYDig .. " lowYDig=" .. self.hubState.lowYDig)
end

--- @param self Console
function Console:handleTestMove()
    print("Start coordinates for assigned drone ranges:")

    for droneId, assignment in pairs(self.hubState.droneAssignment) do
        local chunkId = assignment.chunkId
        local rangeIndex = assignment.rangeIndex
        local ranges = self.hubState.chunkWorkMap[chunkId]
        local range = ranges and ranges[rangeIndex]
        if not range then
            print(string.format("Drone %s: NO RANGE", tostring(droneId)))
            goto continue
        end
        local chunkX, chunkZ = chunkId:match("^([%-]?%d+),([%-]?%d+)$")
        chunkX = tonumber(chunkX)
        chunkZ = tonumber(chunkZ)

        if not chunkX or not chunkZ then
            print(string.format("Drone %s: BAD CHUNKID %s", tostring(droneId), chunkId))
            goto continue
        end
        local chunkVec = Vec.new(chunkX, 0, chunkZ)
        local startPos = require("lib.gps_util").nthBlockGlobal(chunkVec, range.from, true)
        if startPos then
            print(
                string.format(
                    "Drone %s: Chunk %s | Range %d | Start XYZ: %d %d %d (from=%d to=%d)",
                    tostring(droneId),
                    chunkId,
                    rangeIndex,
                    startPos.x, startPos.y, startPos.z,
                    range.from, range.to
                )
            )
            HubNet.send(droneId, Message.new(
                "/drone/move-test",
                "",
                self.hubState.id,
                {
                    position = Vec.new(startPos.x, self.hubState.highYDig, startPos.z),
                    baseY    = self.hubState.baseY,
                    highYDig = self.hubState.highYDig,
                    lowYDig  = self.hubState.lowYDig
                }
            ))

        else
            print(string.format("Drone %s: FAILED TO CALC GLOBAL COORDS", tostring(droneId)))
        end
        ::continue::
    end
end

--- @param self Console
function Console:handleStartMining()
    local N = self.hubState.parallelStartedDronesNumber
    local epsilon = self.hubState.latency or 0

    if not N or N < 1 then
        N = 0
    end

    local startedCount = 0
    print("Start coordinates for assigned drone ranges:")

    local droneIds = {}
    for droneId in pairs(self.hubState.droneAssignment) do
        table.insert(droneIds, droneId)
    end
    table.sort(droneIds)

    local totalDrones = #droneIds

    for i, droneId in ipairs(droneIds) do
        local assignment = self.hubState.droneAssignment[droneId]
        local chunkId = assignment.chunkId
        local rangeIndex = assignment.rangeIndex
        local ranges = self.hubState.chunkWorkMap[chunkId]
        local range = ranges and ranges[rangeIndex]

        if not range then
            print(string.format("Drone %s: NO RANGE", tostring(droneId)))
            goto continue
        end

        local chunkX, chunkZ = chunkId:match("^([%-]?%d+),([%-]?%d+)$")
        chunkX = tonumber(chunkX)
        chunkZ = tonumber(chunkZ)

        if not chunkX or not chunkZ then
            print(string.format("Drone %s: BAD CHUNKID %s", tostring(droneId), chunkId))
            goto continue
        end

        local chunkVec = Vec.new(chunkX, 0, chunkZ)
        local startPos = require("lib.gps_util").nthBlockGlobal(chunkVec, range.from, true)

        if startPos then
            print(
                string.format(
                    "Drone %s: Chunk %s | Range %d | Start XYZ: %d %d %d (from=%d to=%d)",
                    tostring(droneId),
                    chunkId,
                    rangeIndex,
                    startPos.x, startPos.y, startPos.z,
                    range.from, range.to
                )
            )

            HubNet.send(droneId, Message.new(
                "/drone/start/mining",
                "",
                self.hubState.id,
                {
                    position = Vec.new(startPos.x, self.hubState.highYDig, startPos.z),
                    rangeFrom = range.from,
                    rangeTo = range.to,
                    baseY    = self.hubState.baseY,
                    highYDig = self.hubState.highYDig,
                    lowYDig  = self.hubState.lowYDig
                }
            ))

            startedCount = startedCount + 1

            if N > 0 and startedCount % N == 0 and i < totalDrones then
                os.sleep(epsilon)
            end
        else
            print(string.format("Drone %s: FAILED TO CALC GLOBAL COORDS", tostring(droneId)))
        end

        ::continue::
    end
end

--- @param self Console
function Console:handleStopMining()
    for droneId in pairs(self.hubState.droneAssignment) do
        HubNet.send(droneId, Message.new(
            "/drone/stop/mining",
            "",
            self.hubState.id,
            {}
        ))
    end
end

--- @param self Console
function Console:handleSendReboot()
    self.droneService:globalReboot()
end

--- @param input string
--- @return integer|nil x
--- @return integer|nil y
--- @return integer|nil z
--- @return string|nil
function Console.parseXYZ(input)
    if type(input) ~= "string" then
        return nil, nil, nil, "input must be a string"
    end

    --- @param s string
    --- @return integer|nil
    local function toint(s)
        if s and s:match("^[-+]?%d+$") then
            return tonumber(s)
        end
        return nil
    end

    --- @type table<string, integer|nil>
    local out = { x = nil, y = nil, z = nil }

    for k, v in input:gmatch("([xXyYzZ])%s*[:=]%s*([-+]?%d+)") do
        local key = k:lower()
        out[key] = toint(v)
    end

    if not (out.x and out.y and out.z) then
        local residual = input:gsub("[xXyYzZ]%s*[:=]%s*[-+]?%d+", " ")
        residual = residual:gsub("[,;]", " ")
        --- @type string[]
        local nums = {}
        for n in residual:gmatch("[-+]?%d+") do
            table.insert(nums, n)
        end
        if #nums >= 3 then
            out.x = out.x or toint(nums[1])
            out.y = out.y or toint(nums[2])
            out.z = out.z or toint(nums[3])
        end
    end

    if out.x and out.y and out.z then
        return out.x, out.y, out.z, nil
    end

    --- @type string[]
    local missing = {}
    if not out.x then table.insert(missing, "x") end
    if not out.y then table.insert(missing, "y") end
    if not out.z then table.insert(missing, "z") end
    return nil, nil, nil, "Missing values: " .. table.concat(missing, ", ")
end

return Console
