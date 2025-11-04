
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
---@field fuelPods FuelPod[]
---@field cargoPods CargoPod[]
---@field id integer

local gpsUtil = require("lib.gps_util")

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
    self.id = os.getComputerID()
    return self
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

return HubState
