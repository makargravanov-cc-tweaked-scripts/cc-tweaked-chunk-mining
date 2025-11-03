
--- @class ChunkEntity
--- @field public coordAbsolute Vec
--- @field public coordRelative Vec

local ChunkEntity = {}
ChunkEntity.__index = ChunkEntity

--- @param coordAbsolute Vec
--- @param coordRelative Vec
function ChunkEntity.new(coordAbsolute, coordRelative)
    local self = setmetatable({}, ChunkEntity)
    self.coordAbsolute = coordAbsolute
    self.coordRelative = coordRelative
    return self
end

function ChunkEntity:toString()
    return tostring(self.coordAbsolute)
end

return ChunkEntity