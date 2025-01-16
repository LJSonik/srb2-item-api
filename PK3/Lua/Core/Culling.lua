---@class itemapi
local mod = itemapi


---@class itemapi.CullableEntityDef
---@field id    string
---@field index integer
---@field spawn fun(entity: any)
---@field despawn fun(entity: any)


local MAP_SIZE = 65536
local MAP_SIZE_HALF = MAP_SIZE / 2
local BLOCK_SIZE = 512
local NUM_BLOCKS_PER_SIDE = (MAP_SIZE + (BLOCK_SIZE - 1)) / BLOCK_SIZE
local CULL_DIST = 2048


local initialised = false
local blocks_entity = {}
local blocks_entityType = {}
local viewX, viewY
local distLUT -- Note: takes a lot of RAM... not ideal

---@type { [string|integer]: itemapi.CullableEntityDef }
mod.cullableEntityDefs = {}


---@param id string
---@param def itemapi.CullableEntityDef
function mod.addCullableEntity(id, def)
	if type(id) ~= "string" then
		error("missing or invalid cullable entity ID", 2)
	end

	def.index = #mod.cullableEntityDefs + 1
	def.id = id
	mod.cullableEntityDefs[def.index] = def
	mod.cullableEntityDefs[id] = def
end

local function realPosToBlockPos(x, y)
	return
		(x / FU + MAP_SIZE_HALF) / BLOCK_SIZE,
		(y / FU + MAP_SIZE_HALF) / BLOCK_SIZE
end

local function getBlockDistFromRealPos(x1, y1, x2, y2)
	local bx1, by1 = realPosToBlockPos(x1, y1)
	local bx2, by2 = realPosToBlockPos(x2, y2)
	return distLUT[bx2 - bx1][by2 - by1]
end

local function cacheDistanceLUT()
	local limit = MAP_SIZE / BLOCK_SIZE

	distLUT = {}

	for dx = -limit, limit do
		distLUT[dx] = {}

		for dy = -limit, limit do
			distLUT[dx][dy] = R_PointToDist2(0, 0, dx * 256, dy * 256) / 256
		end
	end
end

---@param entityType string|integer
---@param entity any
---@param blockIndex integer
local function addEntityToBlock(entityType, entity, blockIndex)
	-- mod.logDebugLine("addEntityToBlock " .. entity.debugID)

	if not blocks_entity[blockIndex] then
		blocks_entity[blockIndex] = {}
		blocks_entityType[blockIndex] = {}
	end

	local block_entity = blocks_entity[blockIndex]
	local block_entityType = blocks_entityType[blockIndex]

	local i = #block_entity + 1
	block_entity[i] = entity
	block_entityType[i] = entityType
end

---@param entityType string|integer
---@param entity any
---@param x fixed_t
---@param y fixed_t
function mod.addEntityToCullingSystem(entityType, entity, x, y)
	if not initialised then return end

	-- mod.logDebugLine("addEntityToCullingSystem " .. entity.debugID)

	if not distLUT then
		cacheDistanceLUT()
	end

	local bx, by = realPosToBlockPos(x, y)
	addEntityToBlock(entityType, entity, by * NUM_BLOCKS_PER_SIDE + bx)

	if viewX == nil then
		if displayplayer.realmo then
			viewX, viewY = displayplayer.realmo.x, displayplayer.realmo.y
		else
			viewX, viewY = 0, 0
		end
	end

	local dist = getBlockDistFromRealPos(viewX, viewY, x, y)
	if dist <= CULL_DIST / BLOCK_SIZE then
		local def = mod.cullableEntityDefs[entityType]
		def.spawn(entity)
	end
end

---@param entity any
---@param blockIndex integer
local function removeEntityFromBlock(entity, blockIndex)
	-- mod.logDebugLine("removeEntityFromBlock " .. entity.debugID)

	local block_entity = blocks_entity[blockIndex]
	local block_entityType = blocks_entityType[blockIndex]
	local highestIndexInBlock = #block_entity

	-- Remove element from block
	local indexInBlock = mod.findInArray(block_entity, entity)
	block_entity[indexInBlock] = block_entity[highestIndexInBlock]
	block_entity[highestIndexInBlock] = nil
	block_entityType[indexInBlock] = block_entityType[highestIndexInBlock]
	block_entityType[highestIndexInBlock] = nil

	-- Remove block if empty
	if highestIndexInBlock == 1 then -- Was 1 before removing the last element, thus now 0
		blocks_entity[blockIndex] = nil
		blocks_entityType[blockIndex] = nil
	end
end

---@param entityType string|integer
---@param entity any
---@param x fixed_t
---@param y fixed_t
function mod.removeEntityFromCullingSystem(entityType, entity, x, y)
	if not initialised then return end

	-- mod.logDebugLine("removeEntityFromCullingSystem " .. entity.debugID)

	local bx, by = realPosToBlockPos(x, y)
	removeEntityFromBlock(entity, by * NUM_BLOCKS_PER_SIDE + bx)

	local def = mod.cullableEntityDefs[entityType]
	def.despawn(entity)
end

---@param entityType string|integer
---@param entity any
---@param oldX fixed_t
---@param oldY fixed_t
---@param newX fixed_t
---@param newY fixed_t
function mod.moveEntityInCullingSystem(entityType, entity, oldX, oldY, newX, newY)
	if not initialised or viewX == nil then return end

	local oldBX, oldBY = realPosToBlockPos(oldX, oldY)
	local newBX, newBY = realPosToBlockPos(newX, newY)

	local oldBlockIndex = oldBY * NUM_BLOCKS_PER_SIDE + oldBX
	local newBlockIndex = newBY * NUM_BLOCKS_PER_SIDE + newBX

	if oldBlockIndex == newBlockIndex then return end

	-- mod.logDebugLine("moveEntityInCullingSystem " .. entity.debugID)

	removeEntityFromBlock(entity, oldBlockIndex)
	addEntityToBlock(entityType, entity, newBlockIndex)

	local cullDist = CULL_DIST / BLOCK_SIZE
	local oldInView = (getBlockDistFromRealPos(viewX, viewY, oldX, oldY) <= cullDist)
	local newInView = (getBlockDistFromRealPos(viewX, viewY, newX, newY) <= cullDist)
	if not oldInView and newInView then
		local def = mod.cullableEntityDefs[entityType]
		def.spawn(entity)
	elseif oldInView and not newInView then
		local def = mod.cullableEntityDefs[entityType]
		def.despawn(entity)
	end
end

local function hideOldBlocks(oldBX, oldBY, newBX, newBY)
	local cullDist = CULL_DIST / BLOCK_SIZE

	for y = max(oldBY - cullDist, 0), min(oldBY + cullDist, NUM_BLOCKS_PER_SIDE - 1) do
		for x = max(oldBX - cullDist, 0), min(oldBX + cullDist, NUM_BLOCKS_PER_SIDE - 1) do
			local oldDist = distLUT[oldBX - x][oldBY - y]
			if oldDist > cullDist then continue end

			local newDist = distLUT[newBX - x][newBY - y]
			if newDist <= cullDist then continue end

			local blockIndex = y * NUM_BLOCKS_PER_SIDE + x
			local block_entity = blocks_entity[blockIndex]
			if not block_entity then continue end
			local block_entityType = blocks_entityType[blockIndex]

			for i = 1, #block_entity do
				local def = mod.cullableEntityDefs[block_entityType[i]]
				def.despawn(block_entity[i])
			end
		end
	end
end

local function showNewBlocks(oldBX, oldBY, newBX, newBY)
	local cullDist = CULL_DIST / BLOCK_SIZE

	for y = max(newBY - cullDist, 0), min(newBY + cullDist, NUM_BLOCKS_PER_SIDE - 1) do
		for x = max(newBX - cullDist, 0), min(newBX + cullDist, NUM_BLOCKS_PER_SIDE - 1) do
			local newDist = distLUT[newBX - x][newBY - y]
			if newDist > cullDist then continue end

			local oldDist = distLUT[oldBX - x][oldBY - y]
			if oldDist <= cullDist then continue end

			local blockIndex = y * NUM_BLOCKS_PER_SIDE + x
			local block_entity = blocks_entity[blockIndex]
			if not block_entity then continue end
			local block_entityType = blocks_entityType[blockIndex]

			for i = 1, #block_entity do
				local def = mod.cullableEntityDefs[block_entityType[i]]
				def.spawn(block_entity[i])
			end
		end
	end
end

function mod.updateCulling()
	if not initialised then return end

	if not distLUT then
		cacheDistanceLUT()
	end

	local newX, newY
	if displayplayer.realmo then
		newX, newY = displayplayer.realmo.x, displayplayer.realmo.y
	else
		newX, newY = 0, 0
	end

	if viewX ~= nil then
		local oldBX, oldBY = realPosToBlockPos(viewX, viewY)
		local newBX, newBY = realPosToBlockPos(newX, newY)

		if oldBX ~= newBX or oldBY ~= newBY then
			hideOldBlocks(oldBX, oldBY, newBX, newBY)
			showNewBlocks(oldBX, oldBY, newBX, newBY)
		end
	end

	viewX, viewY = newX, newY
end

function mod.initialiseVisualCulling()
	if initialised then return end
	mod.uninitialiseVisualCulling()
	initialised = true
end

function mod.uninitialiseVisualCulling()
	blocks_entity = {}
	blocks_entityType = {}
	viewX, viewY = nil, nil

	initialised = false
end
