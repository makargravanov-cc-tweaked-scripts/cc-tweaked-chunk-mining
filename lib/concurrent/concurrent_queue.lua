
-- ConcurrentQueue: A thread-safe queue implementation for concurrent environments.

-- NOTE: CHANGE "ANY" TYPE TO TYPE THAT YOUR QUEUE WILL STORE IF NEEDED

---@class ConcurrentQueue
---@field items table<integer, any>
---@field lock boolean
---@field new fun(): ConcurrentQueue
---@field push fun(self: ConcurrentQueue, event: any)
---@field read fun(self: ConcurrentQueue): any
---@field pull fun(self: ConcurrentQueue): any
---@field clear fun(self: ConcurrentQueue)
---@field isEmpty fun(self: ConcurrentQueue): boolean
local ConcurrentQueue = {}

ConcurrentQueue.__index = ConcurrentQueue

---@return ConcurrentQueue
function ConcurrentQueue.new()
    return setmetatable({ items = {}, lock = false }, ConcurrentQueue)
end

---@param self ConcurrentQueue
---@param event any 
function ConcurrentQueue:push(event)
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    table.insert(self.items, event)
    self.lock = false
end

---@param self ConcurrentQueue
---@return any
function ConcurrentQueue:read()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local item = self.items[1]
    self.lock = false
    return item
end

---@param self ConcurrentQueue
---@return any
function ConcurrentQueue:pull()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local item = table.remove(self.items, 1)
    self.lock = false
    return item
end

---@param self ConcurrentQueue
function ConcurrentQueue:clear()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    self.items = {}
    self.lock = false
end

---@param self ConcurrentQueue
---@return boolean
function ConcurrentQueue:isEmpty()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local empty = #self.items == 0
    self.lock = false
    return empty
end

return ConcurrentQueue
