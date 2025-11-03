-- lib/vec.lua

---@class Vec
---@field x number
---@field y number
---@field z number
local Vec = {}

local CHUNK_SIZE = 16

---@param x? number
---@param y? number
---@param z? number
---@return Vec
function Vec.new(x,y,z)
    return {x = x or 0, y = y or 0, z = z or 0}
end

---@param a Vec
---@param b Vec
---@return Vec
function Vec.add(a,b)
    return Vec.new(a.x + b.x, a.y + b.y, a.z + b.z)
end

---@param a Vec
---@param b Vec
---@return Vec
function Vec.sub(a,b)
    return Vec.new(a.x - b.x, a.y - b.y, a.z - b.z)
end

---@param a Vec
---@param b Vec
---@return boolean
function Vec.equals(a,b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

---@param a Vec
---@param b Vec
---@return number
function Vec.dist(a, b)
    return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2)
end

-- ---------- Chunk and coordinate utilities ----------

-- Returns integer chunk coordinates for global block coordinates in Vec.
-- Minecraft rule: chunkX = floor(globalX / 16)
---@param v Vec
---@return Vec -- Vec(chunkX, 0, chunkZ)
function Vec.getChunk(v)
    local gx = math.floor(v.x)
    local gz = math.floor(v.z)
    local cx = math.floor(gx / CHUNK_SIZE)
    local cz = math.floor(gz / CHUNK_SIZE)
    return Vec.new(cx, 0, cz)
end

-- Returns which chunk A is in, relative to the chunk that contains B.
-- Result: Vec(relativeChunkX, 0, relativeChunkZ)
---@param a Vec -- global coordinate A
---@param b Vec -- global coordinate B (chunk of B is treated as origin 0,0)
---@return Vec
function Vec.getChunkRelativeTo(a, b)
    local ca = Vec.getChunk(a)
    local cb = Vec.getChunk(b)
    return Vec.new(ca.x - cb.x, 0, ca.z - cb.z)
end

-- Converts a global block position into its local position inside the chunk.
-- local x,z are in 0..15 range. y is preserved.
---@param v Vec -- global block coordinate
---@return Vec -- Vec(localX, y, localZ)
function Vec.globalToLocalBlock(v)
    local gx = math.floor(v.x)
    local gz = math.floor(v.z)
    local lx = gx % CHUNK_SIZE
    local lz = gz % CHUNK_SIZE
    return Vec.new(lx, v.y or 0, lz)
end

-- Converts local block coordinates inside a chunk to global coordinates.
-- chunkVec: chunk coordinates. localVec: local (0..15).
---@param chunkVec Vec -- Vec(chunkX, _, chunkZ)
---@param localVec Vec -- Vec(localX, y, localZ)
---@return Vec -- global Vec
function Vec.localBlockToGlobal(chunkVec, localVec)
    local gx = chunkVec.x * CHUNK_SIZE + math.floor(localVec.x)
    local gz = chunkVec.z * CHUNK_SIZE + math.floor(localVec.z)
    local gy = localVec.y or 0
    return Vec.new(gx, gy, gz)
end

-- Returns the N-th block (0-based) in a chunk in global coordinates.
-- Iteration order: X grows first, then Z.
-- N must be in [0..255]. If one_based == true, then N is [1..256].
---@param chunkVec Vec -- Vec(chunkX, 0, chunkZ)
---@param n number
---@param one_based boolean?
---@return Vec
function Vec.nthBlockInChunkGlobal(chunkVec, n, one_based)
    if one_based then n = n - 1 end
    n = math.floor(n)
    if n < 0 then n = 0 end
    if n > (CHUNK_SIZE*CHUNK_SIZE - 1) then n = CHUNK_SIZE*CHUNK_SIZE - 1 end
    local localX = n % CHUNK_SIZE
    local localZ = math.floor(n / CHUNK_SIZE)
    return Vec.new(chunkVec.x * CHUNK_SIZE + localX, 0, chunkVec.z * CHUNK_SIZE + localZ)
end

-- Converts global chunk coordinates to local coordinates relative to an origin.
---@param globalChunk Vec -- Vec(chunkX,0,chunkZ)
---@param originChunk Vec -- Vec(originChunkX,0,originChunkZ)
---@return Vec -- Vec(localChunkX, 0, localChunkZ)
function Vec.globalChunkToLocal(globalChunk, originChunk)
    return Vec.new(globalChunk.x - originChunk.x, 0, globalChunk.z - originChunk.z)
end

-- Converts local chunk coordinates (relative to origin) to global.
---@param localChunk Vec -- Vec(localChunkX,0,localChunkZ)
---@param originChunk Vec -- Vec(originChunkX,0,originChunkZ)
---@return Vec -- Vec(globalChunkX, 0, globalChunkZ)
function Vec.localChunkToGlobal(localChunk, originChunk)
    return Vec.new(localChunk.x + originChunk.x, 0, localChunk.z + originChunk.z)
end

return Vec
