
---@class HubState
---@field chunkWorkMap table<string, ChunkWorkRange[]>  -- chunkId → list of ranges
---@field droneAssignment table<integer, {chunkId:string, rangeIndex:integer}>  -- droneId → assigned range
---@field drones DroneEntity[]
---@field new fun(): HubState
---@field registerChunk fun(self: HubState, chunkId: string, ranges: ChunkWorkRange[])
---@field assignDrone fun(self: HubState, droneId: integer, chunkId: string, rangeIndex: integer)
---@field unassignDrone fun(self: HubState, droneId: integer)
---@field getAssignedRange fun(self: HubState, droneId: integer): ChunkWorkRange|nil
---@field getChunkProgress fun(self: HubState, chunkId: string): number
---@field registerDrone fun(self: HubState, droneId: integer): integer
---@field unregisterDrone fun(self: HubState, droneId: integer)
---@field containsDrone fun(self: HubState, droneId: integer): boolean
---@field rootChunk ChunkEntity|nil
---@field position Vec|nil
---
---//////////////
---@field fuelPods FuelPod[]
---@field fuelQueue ConcurrentQueue
---@field addFuelPod fun(self: HubState, pod: FuelPod)
---@field removeFuelPod fun(self: HubState, pod: FuelPod)
---@field subscribeDroneToFuelPod fun(self: HubState, droneId: integer) : Vec|nil
---@field unsubscribeDroneFromFuelPod fun(self: HubState, droneId: integer)
---
---@field cargoPods CargoPod[]
---@field cargoQueue ConcurrentQueue
---@field addCargoPod fun(self: HubState, pod: CargoPod)
---@field removeCargoPod fun(self: HubState, pod: CargoPod)
---@field subscribeDroneToCargoPod fun(self: HubState, droneId: integer) : Vec|nil
---@field unsubscribeDroneFromCargoPod fun(self: HubState, droneId: integer)
---//////////////
---
---@field id integer
---@field registerChunksGrid fun(self: HubState, gridSize: integer?)
---@field getChunkId fun(self: HubState, chunkVec: Vec): string
---@field hasAssignedDrone fun(self: HubState, chunkId: string): boolean
---@field getCenterChunk fun(self: HubState): Vec|nil
---//////////////
--- drone move synchronization
---@field movingUp         table<integer, EMoveState>  -- droneId → isOnFinish
---@field movingDown       table<integer, EMoveState>  -- droneId → isOnFinish
---@field movingHorizontal table<integer, EMoveState>  -- droneId → isOnFinish
---@field currentDirection ECurrentDirection
---
---@field checkMoveVertical      fun(self: HubState): table<integer, EMoveState>|nil
---@field checkMoveHorizontal    fun(self: HubState): table<integer, EMoveState>|nil
---@field finishMoveUp           fun(self: HubState, droneId: integer): table<integer, EMoveState>|nil
---@field finishMoveDown         fun(self: HubState, droneId: integer): table<integer, EMoveState>|nil
---@field finishMoveHorizontal   fun(self: HubState, droneId: integer): table<integer, EMoveState>|nil
---@field tryStartMoveUp         fun(self: HubState, droneId: integer): boolean
---@field tryStartMoveDown       fun(self: HubState, droneId: integer): boolean
---@field tryStartMoveHorizontal fun(self: HubState, droneId: integer): boolean
---////////////
---constants
---@field latency  integer -- latency in seconds for starting drones
---@field baseY    integer
---@field highYDig integer
---@field lowYDig  integer
---@field parallelStartedDronesNumber integer

local gpsUtil = require("lib.gps_util")
local ChunkWorkRange = require("hub.entities.chunk_work_range")
local ChunkEntity = require("hub.entities.chunk_entity")
local ConcurrentQueue = require("lib.concurrent.concurrent_queue")
local FuelPod = require("hub.entities.inventory.fuel_pod")
local CargoPod = require("hub.entities.inventory.cargo_pod")
local EMoveState = require("lib.move_status_enum").EMoveState
local ECurrentDirection = require("lib.move_status_enum").ECurrentDirection

local HubState = {}
HubState.__index = HubState

--- @constructor
--- @return HubState
function HubState.new()
    local self = setmetatable({}, HubState)
    self.chunkWorkMap = {}
    self.droneAssignment = {}
    self.drones = {}
    self.position = gpsUtil.position()
    self.rootChunk = nil
    self.fuelPods = {}
    self.cargoPods = {}
    self.fuelQueue = ConcurrentQueue.new()
    self.cargoQueue = ConcurrentQueue.new()
    self.id = os.getComputerID()
    self.movingHorizontal = {}
    self.movingUp = {}
    self.movingDown = {}
    self.currentDirection = ECurrentDirection.VERTICAL
    self.latency = 0
    self.baseY    = self.position.y
    self.highYDig = self.baseY
    self.lowYDig  = self.baseY - 10
    self.parallelStartedDronesNumber = 1
    return self
end


--- @param self HubState
--- @return table<integer, EMoveState>|nil
function HubState:checkMoveVertical()
--- @type table<integer, EMoveState>
    local updatedIds = {}
    local flag = false
    -- check if all up moves are finished
    for id, elem in pairs(self.movingUp) do
        if elem == EMoveState.MOVE then
            log(id .. " checkMoveVertical(up): state = MOVE, return nil")
            return nil
        elseif elem == EMoveState.WAIT then
            flag = true
            updatedIds[id] = EMoveState.MOVE
            self.movingUp[id] = EMoveState.MOVE
        end
    end
    -- check if all down moves are finished
    for id, elem in pairs(self.movingDown) do
        if elem == EMoveState.MOVE then
            log(id .. " checkMoveVertical(down): state = MOVE, return nil")
            return nil
        elseif elem == EMoveState.WAIT then
            flag = true
            updatedIds[id] = EMoveState.MOVE
            self.movingDown[id] = EMoveState.MOVE
        end
    end

    if (flag) then
        log("checkMoveVertical: flag is true")
        return updatedIds
    end

    -- if all drones already finished their moves
    -- then switch to horizontal
    -- and return updated ids...
    self.currentDirection = ECurrentDirection.HORIZONTAL
    for i, elem in pairs(self.movingUp) do
        self.movingHorizontal[i] = EMoveState.MOVE
        updatedIds[i] = EMoveState.MOVE
    end
    for i, elem in pairs(self.movingHorizontal) do
        if self.movingHorizontal[i] == EMoveState.WAIT then
            self.movingHorizontal[i] = EMoveState.MOVE
            updatedIds[i] = EMoveState.MOVE
        end
    end
    self.movingUp = {}
    self.movingDown = {}
    local updatedCount = 0
    for _ in pairs(updatedIds) do
        updatedCount = updatedCount + 1
    end
    log("checkMoveVertical SUCCESS: updated " .. updatedCount .. " drones")
    -- in the code that calls HubState:finishMove*() 
    -- we will understand what type of messages must be sent 
    -- by we known the direction
    return updatedIds
end

--- @param self HubState
--- @param droneId integer
--- @return table<integer, EMoveState>|nil
function HubState:finishMoveUp(droneId)
    log(droneId .. " finishMoveUp currentDir: " .. self.currentDirection)
    if self.currentDirection == ECurrentDirection.VERTICAL then
        if self.movingUp[droneId] then
            self.movingUp[droneId] = EMoveState.FINISH
            return self:checkMoveVertical()
        else
            log(droneId .. " WARN: finishMoveUp: " .. droneId .. " not found!")
            return nil
        end
    else
        log(droneId .. " WARN: finishMoveUp: currentDirection not vertical!")
        return nil
    end
end

--- @param self HubState
--- @param droneId integer
--- @return table<integer, EMoveState>|nil
function HubState:finishMoveDown(droneId)
    log(droneId .. " finishMoveDown currentDir: " .. self.currentDirection)
    if self.currentDirection == ECurrentDirection.VERTICAL then
        if self.movingDown[droneId] then
            self.movingDown[droneId] = EMoveState.FINISH
            return self:checkMoveVertical()
        else
            log(droneId .. " WARN: finishMoveDown: " .. droneId .. " not found!")
            return nil
        end
    else
        log(droneId .. " WARN: finishMoveUp: currentDirection not vertical!")
        return nil
    end
end

--- @param self HubState
--- @return table<integer, EMoveState>|nil
function HubState:checkMoveHorizontal()
    --- @type table<integer, EMoveState>
    local updatedIds = {}
    local flag = false
    -- check if all up moves are finished, 
    -- like in checkMoveVertical but for horizontal
    for id, elem in pairs(self.movingHorizontal) do
        if elem == EMoveState.MOVE then
            log(id .. " checkMoveHorizontal: state = MOVE, return nil")
            return nil
        elseif elem == EMoveState.WAIT then
            flag = true
            updatedIds[id] = EMoveState.MOVE
            self.movingHorizontal[id] = EMoveState.MOVE
        end
    end

    if (flag) then
        log("checkMoveHorizontal: flag is true")
        return updatedIds
    end

    -- if all drones already finished their moves
    -- then switch to vertical
    -- and return updated ids...
    self.currentDirection = ECurrentDirection.VERTICAL

    local counter1 = 0
    local counter2 = 0
    local counter3 = 0

    for i, elem in pairs(self.movingHorizontal) do
        self.movingDown[i] = EMoveState.MOVE
        updatedIds[i] = EMoveState.MOVE
        counter1 = counter1 + 1
    end
    for i, elem in pairs(self.movingDown) do
        if self.movingDown[i] == EMoveState.WAIT then
            self.movingDown[i] = EMoveState.MOVE
            updatedIds[i] = EMoveState.MOVE
            counter2 = counter2 + 1
        end
    end
    for i, elem in pairs(self.movingUp) do
        if self.movingUp[i] == EMoveState.WAIT then
            self.movingUp[i] = EMoveState.MOVE
            updatedIds[i] = EMoveState.MOVE
            counter3 = counter3 + 1
        end
    end
    self.movingHorizontal = {}
    log("checkMoveHorizontal SUCCESS: " .. counter1 .. " " .. counter2 .. " " .. counter3)        
    -- in the code that calls HubState:finishMove*() 
    -- we will understand what type of messages must be sent 
    -- by we known the direction
    return updatedIds
end

--- @param self HubState
--- @param droneId integer
--- @return table<integer, EMoveState>|nil
function HubState:finishMoveHorizontal(droneId)
    log(droneId .. " finishMoveHorizontal currentDir: " .. self.currentDirection)
    if self.currentDirection == ECurrentDirection.HORIZONTAL then
        if self.movingHorizontal[droneId] then
            self.movingHorizontal[droneId] = EMoveState.FINISH
            return self:checkMoveHorizontal()
        else
            log(droneId .. "WARN: finishMoveHorizontal: " .. droneId .. " not found!")
            return nil
        end
    else
        log(droneId .. "WARN: finishMoveHorizontal: currentDirection not horizontal!")
        return nil
    end
end

--- @param self HubState
--- @param droneId integer
--- @return boolean
function HubState:tryStartMoveUp(droneId)
    log(droneId .. " tryStartMoveUp currentDir: " .. self.currentDirection)
    if self.currentDirection == ECurrentDirection.VERTICAL then
        self.movingUp[droneId] = EMoveState.MOVE
        return true
    elseif self.currentDirection == ECurrentDirection.HORIZONTAL then
        if next(self.movingHorizontal) == nil then
            self.currentDirection = ECurrentDirection.VERTICAL
            self.movingUp[droneId] = EMoveState.MOVE
            return true
        end
        self.movingUp[droneId] = EMoveState.WAIT
        return false
    end
    return false
end

--- @param self HubState
--- @param droneId integer
--- @return boolean
function HubState:tryStartMoveDown(droneId)
    log(droneId .. " tryStartMoveDown currentDir: " .. self.currentDirection)
    if self.currentDirection == ECurrentDirection.VERTICAL then
        self.movingDown[droneId] = EMoveState.MOVE
        return true
    elseif self.currentDirection == ECurrentDirection.HORIZONTAL then
        self.movingDown[droneId] = EMoveState.WAIT
        return false
    end
    return false
end

--- @param self HubState
--- @param droneId integer
--- @return boolean
function HubState:tryStartMoveHorizontal(droneId)
    log(droneId .. " tryStartMoveHorizontal currentDir: " .. self.currentDirection)
    if self.currentDirection == ECurrentDirection.HORIZONTAL then
        self.movingHorizontal[droneId] = EMoveState.MOVE
        return true
    elseif self.currentDirection == ECurrentDirection.VERTICAL then
        self.movingHorizontal[droneId] = EMoveState.WAIT
        return false
    end
    return false
end


--- @param self HubState
--- @param droneId integer
--- @return Vec|nil
function HubState:subscribeDroneToFuelPod(droneId)
    for _, pod in pairs(self.fuelPods) do
        if pod.isOccupied == false then
            if(pod:subscribeDrone(droneId)) then
                return pod.position
            end
        end
    end
    return nil
end

--- @param self HubState
--- @param droneId integer
function HubState:unsubscribeDroneFromFuelPod(droneId)
    for _, pod in pairs(self.fuelPods) do
        pod:unsubscribeDrone(droneId)
    end
end

--- 
--- @param self HubState
--- @param pod FuelPod
function HubState:addFuelPod(pod)
    table.insert(self.fuelPods, pod)
end

--- @param self HubState
--- @param pod FuelPod
function HubState:removeFuelPod(pod)
    for i, p in pairs(self.fuelPods) do
        if p:equals(pod) then
            table.remove(self.fuelPods, i)
            break
        end
    end
end

--- @param self HubState
--- @param pod FuelPod
function HubState:addCargoPod(pod)
    log(pod.position.x .. "; " .. pod.position.y .. "; " .. pod.position.z .. " addCargoPod")
    table.insert(self.cargoPods, pod)
end

--- @param self HubState
--- @param pod CargoPod
function HubState:removeCargoPod(pod)
    log(pod.position.x .. "; " .. pod.position.y .. "; " .. pod.position.z ..  " removeCargoPod")
    for i, p in pairs(self.cargoPods) do
        if p:equals(pod) then
            table.remove(self.cargoPods, i)
            break
        end
    end
end

--- @param self HubState
--- @param droneId integer
--- @return Vec|nil
function HubState:subscribeDroneToCargoPod(droneId)
    log(droneId .. " subscribeDroneFromCargo")
    for _, pod in pairs(self.cargoPods) do
        if pod.isOccupied == false then
            if(pod:subscribeDrone(droneId)) then
                return pod.position
            end
        end
    end
    return nil
end

--- @param self HubState
--- @param droneId integer
function HubState:unsubscribeDroneFromCargoPod(droneId)
    log(droneId .. " unsubscribeDroneFromCargo")
    for _, pod in pairs(self.cargoPods) do
        pod:unsubscribeDrone(droneId)
    end
end


--- Registers a chunk and its work ranges
---@param chunkId string
---@param ranges ChunkWorkRange[]
function HubState:registerChunk(chunkId, ranges)
    self.chunkWorkMap[chunkId] = ranges
end

--- Registers a drone in the hub state
---@param droneId integer
---@return integer
function HubState:registerDrone(droneId)
    table.insert(self.drones, droneId)
    local delta = #self.drones
    return delta
end

--- Unregisters a drone from the hub state
---@param droneId integer
function HubState:unregisterDrone(droneId)
    for i, id in ipairs(self.drones) do
        if id == droneId then
            table.remove(self.drones, i)
            break
        end
    end
end

--- Checks if a drone is registered in the hub state
---@param droneId integer
function HubState:containsDrone(droneId)
    for _, id in ipairs(self.drones) do
        if id == droneId then
            return true
        end
    end
    return false
end

--- Assigns a drone to a specific range of a chunk
---@param droneId integer
---@param chunkId string
---@param rangeIndex integer
function HubState:assignDrone(droneId, chunkId, rangeIndex)
    if not self:containsDrone(droneId) then return end
    self.droneAssignment[droneId] = { chunkId = chunkId, rangeIndex = rangeIndex }
    local range = self.chunkWorkMap[chunkId][rangeIndex]
    if range then range.assignedDroneId = droneId end
end

--- Unassigns a drone and clears its link from the range
---@param droneId integer
function HubState:unassignDrone(droneId)
    if not self:containsDrone(droneId) then return end
    local assignment = self.droneAssignment[droneId]
    if not assignment then return end
    local chunkRanges = self.chunkWorkMap[assignment.chunkId]
    if chunkRanges and chunkRanges[assignment.rangeIndex] then
        chunkRanges[assignment.rangeIndex].assignedDroneId = nil
    end
    self.droneAssignment[droneId] = nil
end

--- Returns assigned range for given drone
---@param droneId integer
---@return ChunkWorkRange|nil
function HubState:getAssignedRange(droneId)
    local assignment = self.droneAssignment[droneId]
    if not assignment then return nil end
    local ranges = self.chunkWorkMap[assignment.chunkId]
    return ranges and ranges[assignment.rangeIndex] or nil
end

--- Returns overall completion ratio for a chunk
---@param chunkId string
---@return number
function HubState:getChunkProgress(chunkId)
    local ranges = self.chunkWorkMap[chunkId]
    if not ranges or #ranges == 0 then return 1 end
    local total, done = 0, 0
    for _, r in ipairs(ranges) do
        total = total + r:getLength()
        done = done + r.nowProcessed
    end
    return done / total
end

--- Converts chunk coordinates to chunk ID string
---@param chunkVec Vec
---@return string
function HubState:getChunkId(chunkVec)
    return tostring(chunkVec.x) .. "," .. tostring(chunkVec.z)
end

--- Gets the center chunk (hub's current chunk)
---@return Vec|nil
function HubState:getCenterChunk()
    if not self.position then return nil end
    return gpsUtil.chunkOf(self.position)
end

--- Checks if a chunk has any assigned drone
---@param chunkId string
---@return boolean
function HubState:hasAssignedDrone(chunkId)
    local ranges = self.chunkWorkMap[chunkId]
    if not ranges then return false end
    for _, range in ipairs(ranges) do
        if range.assignedDroneId then
            return true
        end
    end
    return false
end

--- Registers a grid of chunks around the hub's center chunk
---@param gridSize integer? Default: 5
function HubState:registerChunksGrid(gridSize)
    gridSize = gridSize or 5
    local centerChunk = self:getCenterChunk()
    if not centerChunk then
        log("Error: Hub position not set. Cannot register chunks.")
        return
    end

    -- Set root chunk if not set
    if not self.rootChunk then
        local relativeChunk = gpsUtil.chunkOfRelativeTo(self.position, self.position)
        self.rootChunk = ChunkEntity.new(centerChunk, relativeChunk)
    end

    local offset = math.floor(gridSize / 2)
    local registeredCount = 0

    for dz = -offset, offset do
        for dx = -offset, offset do
            -- Calculate chunk coordinates relative to center
            local chunkVec = {x = centerChunk.x + dx, y = 0, z = centerChunk.z + dz}
            local chunkId = self:getChunkId(chunkVec)

            -- Only register if not already registered
            if not self.chunkWorkMap[chunkId] then
                -- Create a single work range covering the entire chunk (1-256 blocks)
                local ranges = {ChunkWorkRange.new(1, 256, nil)}
                self:registerChunk(chunkId, ranges)
                registeredCount = registeredCount + 1
            end
        end
    end

    log("Registered " .. registeredCount .. " new chunks in " .. gridSize .. "x" .. gridSize .. " grid.")
    log("Center chunk: " .. self:getChunkId(centerChunk))
end

return HubState
