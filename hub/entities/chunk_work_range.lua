---@class ChunkWorkRange
---@field public from integer
---@field public to integer
---@field public nowProcessed integer
---@field public assignedDroneId integer|nil
---@field public new fun(from: integer, to: integer, assignedDroneId: integer|nil): ChunkWorkRange
---@field public getLength fun(self: ChunkWorkRange): integer
---@field public getProgress fun(self: ChunkWorkRange): number
---@field public increment fun(self: ChunkWorkRange)
---@field public isComplete fun(self: ChunkWorkRange): boolean
local ChunkWorkRange = {}
ChunkWorkRange.__index = ChunkWorkRange

--- @param from integer
--- @param to integer
--- @param assignedDroneId integer|nil
function ChunkWorkRange.new(from, to, assignedDroneId)
    local self = setmetatable({}, ChunkWorkRange)
    self.from = from
    self.to = to
    self.nowProcessed = 0
    self.assignedDroneId = assignedDroneId
    return self
end

--- Returns total number of columns in the range
---@return integer
function ChunkWorkRange:getLength()
    return self.to - self.from + 1
end

--- Returns current progress ratio (0..1)
---@return number
function ChunkWorkRange:getProgress()
    local length = self:getLength()
    if length <= 0 then return 1 end
    return math.min(self.nowProcessed / length, 1)
end

--- Advances processed counter by 1 column
function ChunkWorkRange:increment()
    if self.nowProcessed < self:getLength() then
        self.nowProcessed = self.nowProcessed + 1
    end
end

--- Returns true if range fully processed
---@return boolean
function ChunkWorkRange:isComplete()
    return self.nowProcessed >= self:getLength()
end


return ChunkWorkRange