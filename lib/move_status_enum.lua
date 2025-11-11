---@enum EMoveState
local EMoveState = {
    MOVE = 0,
    FINISH = 1,
    WAIT = 2,
    FINISH_OUT = 3
}

---@enum ECurrentDirection
local ECurrentDirection = {
    VERTICAL = 0,
    HORIZONTAL = 1
}

return {
    EMoveState = EMoveState,
    ECurrentDirection = ECurrentDirection
}