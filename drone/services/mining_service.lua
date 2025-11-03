
--- @class MiningService
--- @field droneState DroneState
--- @field moveService MoveService
--- @field new fun(droneState: DroneState, moveService: MoveService): MiningService

local MiningService = {}
MiningService.__index = MiningService

--- @param droneState DroneState
--- @param moveService MoveService
--- @return MiningService
--- @constructor
function MiningService.new(droneState, moveService)
    local self = setmetatable({}, MiningService)
    self.droneState = droneState
    self.moveService = moveService
    return self
end

--- @param self MiningService
--- @param length integer
--- @param fromY integer
--- @param toY integer
function MiningService:startMining(length, fromY, toY)

end

return MiningService