
--- @class Message
--- @field path string
--- @field payload table

local Message = {}
Message.__index = Message

--- @param path string
--- @param payload table
--- @return Message
--- @constructor
function Message.new(path, payload)
    local self = setmetatable({}, Message)
    self.path = path
    self.payload = payload
    return self
end

return Message
