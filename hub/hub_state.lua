
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
---@field registerDrone fun(self: HubState, droneId: integer)
---@field unregisterDrone fun(self: HubState, droneId: integer)
---@field containsDrone fun(self: HubState, droneId: integer): boolean
---@field rootChunk ChunkEntity|nil
---@field position Vec|nil
---
---//////////////
---@field fuelPods FuelPod[]
---@field fuelQeueue ConcurrentQueue
---@field addFuelPod fun(self: HubState, pod: FuelPod)
---@field removeFuelPod fun(self: HubState, pod: FuelPod)
---@field subscribeDroneToFuelPod fun(self: HubState, pod: FuelPod, droneId: integer) : boolean
---@field unsubscribeDroneFromFuelPod fun(self: HubState, pod: FuelPod, droneId: integer)
---
---@field cargoPods CargoPod[]
---@field cargoQeueue ConcurrentQueue
---@field addCargoPod fun(self: HubState, pod: CargoPod)
---@field removeCargoPod fun(self: HubState, pod: CargoPod)
---@field subscribeDroneToCargoPod fun(self: HubState, pod: CargoPod, droneId: integer) : boolean
---@field unsubscribeDroneFromCargoPod fun(self: HubState, pod: CargoPod, droneId: integer)
---//////////////
---
---@field id integer
---@field registerChunksGrid fun(self: HubState, gridSize: integer?)
---@field getChunkId fun(self: HubState, chunkVec: Vec): string
---@field hasAssignedDrone fun(self: HubState, chunkId: string): boolean
---@field getCenterChunk fun(self: HubState): Vec|nil

local gpsUtil = require("lib.gps_util")
local ChunkWorkRange = require("hub.entities.chunk_work_range")
local ChunkEntity = require("hub.entities.chunk_entity")
local ConcurrentQueue = require("lib.concurrent.concurrent_queue")
local FuelPod = require("hub.entities.inventory.fuel_pod")
local CargoPod = require("hub.entities.inventory.cargo_pod")

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
    self.fuelQeueue = ConcurrentQueue.new()
    self.cargoQeueue = ConcurrentQueue.new()
    self.id = os.getComputerID()
    return self
end

--- @param self HubState
--- @param droneId integer
--- @return boolean
function HubState:subscribeDroneToFuelPod(droneId)
    for _, pod in pairs(self.fuelPods) do
        if pod.isOccupied == false then
            return pod:subscribeDrone(droneId)
        end
    end
    self.fuelQeueue:push(droneId)
    return false
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
    table.insert(self.cargoPods, pod)
end

--- @param self HubState
--- @param pod CargoPod
function HubState:removeCargoPod(pod)
    for i, p in pairs(self.cargoPods) do
        if p:equals(pod) then
            table.remove(self.cargoPods, i)
            break
        end
    end
end

--- @param self HubState
--- @param droneId integer
--- @return boolean
function HubState:subscribeDroneToCargoPod(droneId)
    for _, pod in pairs(self.cargoPods) do
        if pod.isOccupied == false then
            return pod:subscribeDrone(droneId)
        end
    end
    self.cargoQeueue:push(droneId)
    return false
end

--- @param self HubState
--- @param droneId integer
function HubState:unsubscribeDroneFromCargoPod(droneId)
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
function HubState:registerDrone(droneId)
    table.insert(self.drones, droneId)
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
        print("Error: Hub position not set. Cannot register chunks.")
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

    print("Registered " .. registeredCount .. " new chunks in " .. gridSize .. "x" .. gridSize .. " grid.")
    print("Center chunk: " .. self:getChunkId(centerChunk))
end

return HubState
