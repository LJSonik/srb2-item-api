---@class itemapi
local mod = itemapi


local MAP_SIZE = 65536
local MAP_SIZE_HALF = MAP_SIZE / 2
local BLOCK_SIZE = 512
local NUM_BLOCKS_PER_SIDE = (MAP_SIZE + (BLOCK_SIZE - 1)) / BLOCK_SIZE
local CULL_DIST = 2048


local initialised = false
local blocks = {}
local viewX, viewY
local distLUT -- Note: takes a lot of RAM... not ideal


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

---@param model itemapi.Model
---@param blockIndex integer
local function addModelToBlock(model, blockIndex)
	local block = blocks[blockIndex]
	if not block then
		block = {}
		blocks[blockIndex] = block
	end

	block[#block + 1] = model
end

---@param model itemapi.Model
function mod.addModelToCullingSystem(model)
	if not initialised then return end

	if not distLUT then
		cacheDistanceLUT()
	end

	local x, y = realPosToBlockPos(model.x, model.y)
	addModelToBlock(model, y * NUM_BLOCKS_PER_SIDE + x)

	if viewX == nil then
		viewX, viewY = displayplayer.mo.x, displayplayer.mo.y
	end

	local dist = getBlockDistFromRealPos(viewX, viewY, model.x, model.y)
	if dist <= CULL_DIST / BLOCK_SIZE then
		mod.spawnClientModel(model.index)
	end
end

---@param model itemapi.Model
---@param blockIndex integer
local function removeModelFromBlock(model, blockIndex)
	local block = blocks[blockIndex]
	local highestIndexInBlock = #block

	-- Remove element from block
	local indexInBlock = mod.findInArray(block, model)
	block[indexInBlock] = block[highestIndexInBlock]
	block[highestIndexInBlock] = nil

	-- Remove block if empty
	if highestIndexInBlock == 1 then -- Was 1 before removing the last element, thus now 0
		blocks[blockIndex] = nil
	end
end

---@param model itemapi.Model
function mod.removeModelFromCullingSystem(model)
	if not initialised then return end

	local x, y = realPosToBlockPos(model.x, model.y)
	removeModelFromBlock(model, y * NUM_BLOCKS_PER_SIDE + x)
	mod.despawnClientModel(model.index)
end

---@param model itemapi.Model
---@param oldX fixed_t
---@param oldY fixed_t
function mod.moveModelInCullingSystem(model, oldX, oldY, newX, newY)
	if not initialised or viewX == nil then return end

	local oldBX, oldBY = realPosToBlockPos(oldX, oldY)
	local newBX, newBY = realPosToBlockPos(newX, newY)

	local oldBlockIndex = oldBY * NUM_BLOCKS_PER_SIDE + oldBX
	local newBlockIndex = newBY * NUM_BLOCKS_PER_SIDE + newBX

	if oldBlockIndex == newBlockIndex then return end

	removeModelFromBlock(model, oldBlockIndex)
	addModelToBlock(model, newBlockIndex)

	local cullDist = CULL_DIST / BLOCK_SIZE
	local oldInView = (getBlockDistFromRealPos(viewX, viewY, oldX, oldY) <= cullDist)
	local newInView = (getBlockDistFromRealPos(viewX, viewY, newX, newY) <= cullDist)
	if not oldInView and newInView then
		mod.spawnClientModel(model.index)
	elseif oldInView and not newInView then
		mod.despawnClientModel(model.index)
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
			local block = blocks[blockIndex]
			if not block then continue end

			for i = 1, #block do
				mod.despawnClientModel(block[i].index)
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
			local block = blocks[blockIndex]
			if not block then continue end

			for i = 1, #block do
				mod.spawnClientModel(block[i].index)
			end
		end
	end
end

function mod.updateCulling()
	if not initialised then return end

	if not distLUT then
		cacheDistanceLUT()
	end

	local newX, newY = displayplayer.mo.x, displayplayer.mo.y

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
	blocks = {}
	viewX, viewY = nil, nil

	initialised = false
end
