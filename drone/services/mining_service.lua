
--- @class MiningService
--- @field droneState DroneState
--- @field moveService MoveService
--- @field new fun(droneState: DroneState, moveService: MoveService): MiningService
--- @field startMining fun(self: MiningService, startNumber: integer, targetNumber: integer, fromY: integer, toY: integer)
--- @field mineColumn fun(self: MiningService, upperY: integer, lowerY: integer) : boolean
--- @field mining fun(self: MiningService)

local GpsUtil = require("lib.gps_util")
local InventoryService = require("drone.services.inventory_service")
local Vec              = require("lib.vec")
local FuelService      = require("drone.services.fuel_service")
local EDroneTask       = require("lib.drone_tasks_enum")

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
        if self.droneState.currentTask ~= EDroneTask.MINING then
            print("droneState.currentTask ~= EDroneTask.MINING")
            return
        end
        InventoryService.dropSelectedItemsDown()

        local isCompleted = self:mineColumn(upperY, lowerY)
        if not isCompleted then
            print("droneState.currentTask ~= EDroneTask.MINING")
            return
        end
        self.droneState:updatePosition()

        InventoryService.dropSelectedItemsDown()
        local freeSlots = InventoryService.getFreeSlots()
        print("free slots: " .. freeSlots)

        local lastPosition = Vec.copy(self.droneState:getPosition())

        if freeSlots <= 15 then
            print("Need to unload inventory")
            InventoryService.requestUnloading(self.droneState, self.moveService.droneNet)
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
                InventoryService.processInventoryUnloadRelease(self.droneState, self.moveService.droneNet)
            end)
        end

        if FuelService.getFuelLevel() <= 2500 then
            print("Need to refuel")
            InventoryService.requestRefueling(self.droneState, self.moveService.droneNet)
            while self.droneState.waitingForRefueling do
                os.sleep(1)
            end
            local refuellingPosition = self.droneState.targetPosition
            if not refuellingPosition then
                error("RefuellingPosition position not set")
            end
            self.moveService:moveTo(refuellingPosition)
            for i = 1, 10, 1 do
                FuelService.refuelFromBiomassBlockChest()
            end
            self.moveService:moveToWithFunction(lastPosition, function ()
                InventoryService.processRefuelRelease(self.droneState, self.moveService.droneNet)
            end)
        end
    end
end

--- @param self MiningService
--- @param upperY integer 
--- @param lowerY integer 
--- @return boolean
function MiningService:mineColumn(upperY, lowerY)
    self.droneState:updatePosition()
    local pos = self.droneState:getPosition()

    for y = pos.y - 1, lowerY, -1 do
        if self.droneState.currentTask ~= EDroneTask.MINING then
            print("droneState.currentTask ~= EDroneTask.MINING")
            return false
        end
        local hasBlock, data = turtle.inspectDown()
        if hasBlock then
            if data.name == "minecraft:water" or data.name == "minecraft:lava" then
                if not turtle.down() then
                    print("Cannot descend into" .. data.name .. " on Y=" .. y)
                    break
                end
            elseif turtle.digDown() then
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
                turtle.digUp()
                if not turtle.up() then
                    if not turtle.back() then
                        print("Error ascending to Y=" .. upperY)
                    end
                end
                break
            end
        end
    end

    self.droneState:updatePosition()

    return true
end

--- @param self MiningService
function MiningService:mining()
    self.moveService:moveTo(self.droneState.targetPosition)
    self:startMining(self.droneState.startNumber, self.droneState.targetNumber, self.droneState.highYDig, self.droneState.lowYDig)
    print("return")
    self.moveService:moveTo(self.droneState.initialPos)
end

return MiningService