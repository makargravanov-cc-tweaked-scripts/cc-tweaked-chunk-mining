-- GpsUtil.lua

local Vec = require("lib.vec")

---@class GpsUtil
local GpsUtil = {}

---@return Vec
function GpsUtil.position()
    local x, y, z = gps.locate(3, false)
    local pos = Vec.new(x, y, z)
    return pos
end

-- Returns the current chunk as Vec(chunkX, 0, chunkZ)
---@return Vec
function GpsUtil.currentChunk()
    local pos = GpsUtil.position()
    return Vec.getChunk(pos)
end

-- Returns the chunk for any given position Vec
---@param pos Vec
---@return Vec
function GpsUtil.chunkOf(pos)
    return Vec.getChunk(pos)
end

-- Returns which chunk A is in, relative to the chunk containing B.
---@param a Vec
---@param b Vec
---@return Vec -- Vec(relativeChunkX, 0, relativeChunkZ)
function GpsUtil.chunkOfRelativeTo(a, b)
    return Vec.getChunkRelativeTo(a, b)
end

-- Returns the N-th block of a chunk in global coordinates. Default: N is 0-based.
---@param chunkVec Vec -- Vec(chunkX, 0, chunkZ)
---@param n number
---@param one_based boolean?
---@return Vec -- Vec(globalX, 0, globalZ)
function GpsUtil.nthBlockGlobal(chunkVec, n, one_based)
    return Vec.nthBlockInChunkGlobal(chunkVec, n, one_based)
end

-- Converts global block position to local coordinates inside a chunk.
---@param pos Vec -- global block position
---@return Vec -- local position (0..15)
function GpsUtil.globalToLocalBlock(pos)
    return Vec.globalToLocalBlock(pos)
end

-- Converts local block coordinates in a chunk to global coordinates.
---@param chunkVec Vec -- chunk coordinates
---@param localVec Vec -- local position in chunk
---@return Vec -- global position
function GpsUtil.localBlockToGlobal(chunkVec, localVec)
    return Vec.localBlockToGlobal(chunkVec, localVec)
end

-- Converts global chunk coordinates to local (relative to an origin)
---@param globalChunk Vec
---@param originChunk Vec
---@return Vec -- local chunk
function GpsUtil.globalChunkToLocal(globalChunk, originChunk)
    return Vec.globalChunkToLocal(globalChunk, originChunk)
end

-- Converts local chunk coordinates to global (relative to an origin)
---@param localChunk Vec
---@param originChunk Vec
---@return Vec -- global chunk
function GpsUtil.localChunkToGlobal(localChunk, originChunk)
    return Vec.localChunkToGlobal(localChunk, originChunk)
end

return GpsUtil
