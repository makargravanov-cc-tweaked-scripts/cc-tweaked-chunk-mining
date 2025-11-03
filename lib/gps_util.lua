
local Vec = require("lib.vec")

---@class GpsUtil
local GpsUtil = {}

---@return Vec
function GpsUtil.position()
    local x, y, z = gps.locate(3, false)
    local pos = Vec.new(x, y, z)
    return pos
end

return GpsUtil
