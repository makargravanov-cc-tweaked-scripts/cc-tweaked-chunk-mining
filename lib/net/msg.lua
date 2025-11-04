
--- @class Message
--- @field path string
--- @field callbackPath string
--- @field callbackId integer
--- @field payload table

local Message = {}
Message.__index = Message

--- @param path string
--- @param callbackPath string
--- @param callbackId integer
--- @param payload table
--- @return Message
--- @constructor
function Message.new(path, callbackPath, callbackId, payload)
    local self = setmetatable({}, Message)
    self.path = path
    self.callbackPath = callbackPath
    self.callbackId = callbackId
    self.payload = payload
    return self
end

return Message
