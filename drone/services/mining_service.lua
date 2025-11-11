
--- @class MiningService
--- @field droneState DroneState
--- @field moveService MoveService
--- @field new fun(droneState: DroneState, moveService: MoveService): MiningService
--- @field startMining fun(self: MiningService, startNumber: integer, targetNumber: integer, fromY: integer, toY: integer)
--- @field mineColumn fun(self: MiningService, upperY: integer, lowerY: integer)

local GpsUtil = require("lib.gps_util")
local InventoryService = require("drone.services.inventory_service")
local Vec              = require("lib.vec")
local FuelService      = require("drone.services.fuel_ervice")

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
--- @param startNumber integer
--- @param targetNumber integer
--- @param fromY integer
--- @param toY integer
function MiningService:startMining(startNumber, targetNumber, fromY, toY)
    -- normalize indices
    local a = math.floor(startNumber)
    local b = math.floor(targetNumber)
    if a < 1 or b < 1 or a > 256 or b > 256 then
        error("Index out of range. Valid range: 1..256")
    end
    local fromIndex = math.min(a, b)
    local toIndex = math.max(a, b)

    -- normalize Y: upper >= lower
    local upperY = math.max(fromY, toY)
    local lowerY = math.min(fromY, toY)

    -- remember the original chunk (we work only inside it)
    self.droneState:updatePosition()
    local currentPos = self.droneState:getPosition()
    local chunk = GpsUtil.chunkOf(currentPos)

    for idx = fromIndex, toIndex do
        local colGlobal = GpsUtil.nthBlockGlobal(chunk, idx, true)
        if not colGlobal then
            error("Failed to compute global coords for index " .. tostring(idx))
        end
        if currentPos.y ~= upperY and not self.moveService:moveVertical(upperY) then
            error("Failed to move to upper Y (" .. tostring(upperY) .. ") before column " .. tostring(idx))
        end
        if not self.moveService:moveHorizontal(colGlobal.x, colGlobal.z) then
            error("Failed to move to column X=" .. tostring(colGlobal.x) .. " Z=" .. tostring(colGlobal.z) .. " (index " .. tostring(idx) .. ")")
        end
        self:mineColumn(upperY, lowerY)
        self.droneState:updatePosition()

        InventoryService.dropSelectedItemsDown()
        local freeSlots = InventoryService.getFreeSlots()
        print("free slots: " .. freeSlots)

        local lastPosition = Vec.copy(self.droneState:getPosition())

        if freeSlots <= 4 then
            print("Need to unload inventory")
            InventoryService.requestUnloading(self.droneState)
            while self.droneState.waitingForUnloading do
                os.sleep(1)
            end
            local unloadingPosition = self.droneState.targetPosition
            if not unloadingPosition then
                error("Unloading position not set")
            end
            self.moveService:moveTo(unloadingPosition)
            InventoryService.dropAllItemsDown()
            self.moveService:moveToWithFunction(lastPosition, function ()
                InventoryService.processInventoryUnloadRelease(self.droneState)
            end)
        end

        if FuelService.getFuelLevel() <= 2500 then
            print("Need to refuel")
            InventoryService.requestRefueling(self.droneState)
            while self.droneState.waitingForRefueling do
                os.sleep(1)
            end
            local refuellingPosition = self.droneState.targetPosition
            if not refuellingPosition then
                error("RefuellingPosition position not set")
            end
            self.moveService:moveTo(refuellingPosition)
            FuelService.refuelFromBiomassBlockChest()
            self.moveService:moveToWithFunction(lastPosition, function ()
                InventoryService.processRefuelRelease(self.droneState)
            end)
        end
    end
end

--- @param self MiningService
--- @param upperY integer 
--- @param lowerY integer 
function MiningService:mineColumn(upperY, lowerY)
    self.droneState:updatePosition()
    local pos = self.droneState:getPosition()

    for y = pos.y - 1, lowerY, -1 do
        local hasBlock, data = turtle.inspectDown()

        if hasBlock then
            if turtle.digDown() then
                if not turtle.down() then break end
            else
                print("Unbreakable block on Y=" .. y)
                break
            end
        else
            if not turtle.down() then
                print("Failed to descend to Y=" .. y)
                break
            end
        end
    end

    self.droneState:updatePosition()

    local currentPos = self.droneState:getPosition()
    if currentPos.y < upperY then
        local diff = upperY - currentPos.y
        for _ = 1, diff do
            if not turtle.up() then
                print("Error ascending to Y=" .. upperY)
                break
            end
        end
    end

    self.droneState:updatePosition()
end


return MiningService