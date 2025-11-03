-- test_gpsutil.lua
-- Simple tests for Vec and GpsUtil. Uses assert() and a mocked gps API.

local Vec = require("lib.vec")
local GpsUtil = require("lib.gps_util")

-- Mock gps.locate for testing
gps = {
    locate = function(timeout, debug) return 30, 64, -10 end
}

-- 1) Test position() and currentChunk()
do
    local pos = GpsUtil.position()
    assert(pos.x == 30 and pos.y == 64 and pos.z == -10, "position() mismatch")
    local chunk = GpsUtil.currentChunk()
    -- 30/16 = 1.875 -> floor = 1; -10/16 = -0.625 -> floor = -1
    assert(chunk.x == 1 and chunk.z == -1, "currentChunk() mismatch")
end

-- 2) Test getChunk with positive and negative coordinates
do
    local p1 = Vec.new(0,0,0)
    local c1 = Vec.getChunk(p1)
    assert(c1.x == 0 and c1.z == 0)

    local p2 = Vec.new(15,0,15)
    local c2 = Vec.getChunk(p2)
    assert(c2.x == 0 and c2.z == 0)

    local p3 = Vec.new(16, 0, 16)
    local c3 = Vec.getChunk(p3)
    assert(c3.x == 1 and c3.z == 1)

    local p4 = Vec.new(-1,0,-1)
    local c4 = Vec.getChunk(p4)
    assert(c4.x == -1 and c4.z == -1)

    local p5 = Vec.new(-16,0,-16)
    local c5 = Vec.getChunk(p5)
    assert(c5.x == -1 and c5.z == -1)
end

-- 3) Test globalToLocalBlock and localBlockToGlobal
do
    local p = Vec.new(30, 70, -10)
    local localp = Vec.globalToLocalBlock(p)
    -- 30 % 16 = 14; -10 % 16 = 6 (Lua’s % is always non-negative)
    assert(localp.x == 14 and localp.z == 6 and localp.y == 70, "globalToLocalBlock failed")

    local chunk = Vec.getChunk(p) -- expected 1, -1
    local global_again = Vec.localBlockToGlobal(chunk, localp)
    assert(global_again.x == 30 and global_again.z == -10 and global_again.y == 70, "localBlockToGlobal failed")
end

-- 4) Test relative chunk
do
    local a = Vec.new(100,0,100)
    local b = Vec.new(50,0,48)
    local rel = Vec.getChunkRelativeTo(a, b)
    -- chunk(a) = floor(100/16)=6, floor(100/16)=6 -> (6,6)
    -- chunk(b) = floor(50/16)=3, floor(48/16)=3 -> (3,3)
    assert(rel.x == 3 and rel.z == 3, "getChunkRelativeTo failed")
end

-- 5) Test N-th block in chunk
do
    local chunk = Vec.new(0,0,0)
    local g0 = Vec.nthBlockInChunkGlobal(chunk, 0)
    assert(g0.x == 0 and g0.z == 0)
    local g15 = Vec.nthBlockInChunkGlobal(chunk, 15)
    assert(g15.x == 15 and g15.z == 0)
    local g16 = Vec.nthBlockInChunkGlobal(chunk, 16)
    assert(g16.x == 0 and g16.z == 1)
    local g255 = Vec.nthBlockInChunkGlobal(chunk, 255)
    assert(g255.x == 15 and g255.z == 15)
end

print("All tests passed.")
