
local ConcurrentQueue = {}

ConcurrentQueue.__index = ConcurrentQueue

function ConcurrentQueue.new()
    return setmetatable({ items = {}, lock = false }, ConcurrentQueue)
end

function ConcurrentQueue:push(event)
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    table.insert(self.items, event)
    self.lock = false
end

function ConcurrentQueue:read()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local item = self.items[1]
    self.lock = false
    return item
end

function ConcurrentQueue:pull()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local item = table.remove(self.items, 1)
    self.lock = false
    return item
end

function ConcurrentQueue:clear()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    self.items = {}
    self.lock = false
end

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
