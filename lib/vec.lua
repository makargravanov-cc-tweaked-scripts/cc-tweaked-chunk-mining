
-- vec.lua

---@class Vec
---@field x number
---@field y number
---@field z number
local Vec = {}

---@param x? number
---@param y? number
---@param z? number
---@return Vec
function Vec.new(x,y,z)
    return {x=x or 0, y=y or 0, z=z or 0}
end

---@param a Vec
---@param b Vec
---@return Vec
function Vec.add(a,b)
    return Vec.new(a.x+b.x, a.y+b.y, a.z+b.z)
end

---@param a Vec
---@param b Vec
---@return Vec
function Vec.sub(a,b)
    return Vec.new(a.x-b.x, a.y-b.y, a.z-b.z)
end

---@param a Vec
---@param b Vec
---@return boolean
function Vec.equals(a,b)
    return a.x==b.x and a.y==b.y and a.z==b.z
end

---@param a Vec
---@param b Vec
---@return number
function Vec.dist(a, b)
    return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2 + (a.z-b.z)^2)
end

return Vec
