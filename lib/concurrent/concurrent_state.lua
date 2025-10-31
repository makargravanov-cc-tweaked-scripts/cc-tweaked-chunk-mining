
--- @class ConcurrentState
--- @field state any
--- @field lock boolean
--- @field new fun(initialState: any): ConcurrentState
--- @field getState fun(self: ConcurrentState): any
--- @field setState fun(self: ConcurrentState, newState: any)

local ConcurrentState = {}

ConcurrentState.__index = ConcurrentState

--- @return ConcurrentState
--- @param initialState any
function ConcurrentState.new(initialState)
    local self = setmetatable({ state = initialState, lock = false }, ConcurrentState)
    return self
end

--- @param self ConcurrentState
--- @return any
function ConcurrentState:getState()
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    local state = self.state
    self.lock = false
    return state
end

--- @param self ConcurrentState
--- @param newState any  
function ConcurrentState:setState(newState)
    while self.lock do
        os.sleep(0.1)
    end
    self.lock = true
    self.state = newState
    self.lock = false
end