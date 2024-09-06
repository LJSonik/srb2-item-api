---@class itemapi
local mod = itemapi


local MAX_PLACEMENT_HEIGHT = 64*FU
local PLACEMENT_CHECK_STEP = 8*FU


---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param bestX fixed_t
---@param bestY fixed_t
---@param bestZ fixed_t
---@param playerX fixed_t
---@param playerY fixed_t
---@param playerZ fixed_t
---@return boolean
function mod.isItemPlacementPositionBetter(x, y, z, bestX, bestY, bestZ, playerX, playerY, playerZ)
	local oldDelta = abs(bestZ - playerZ)
	local newDelta = abs(z - playerZ)

	if newDelta < oldDelta then
		return true
	elseif newDelta == oldDelta then
		local oldDist = R_PointToDist2(playerX, playerY, bestX, bestY)
		local newDist = R_PointToDist2(playerX, playerY, x, y)
		return (newDist > oldDist)
	else
		return false
	end
end

---@param p player_t
---@param itemType itemapi.ItemType
---@return fixed_t?
---@return fixed_t?
---@return fixed_t?
function mod.findItemPlacementPosition(p, itemType)
	local bestX, bestY, bestZ

	local pmo = p.mo
	local def = mod.itemDefs[itemType]

	local playerX = pmo.x
	local playerY = pmo.y
	local playerZ = pmo.z + pmo.height * 2 / 3

	local mt = def.mobjType
	local mobjRadius = (mt and mobjinfo[mt].radius or def.mobjRadius or 32*FU)

	local minDist = pmo.radius + mobjRadius
	local maxDist = pmo.radius * 4 + mobjRadius
	local minZ, maxZ = playerZ - MAX_PLACEMENT_HEIGHT, playerZ + MAX_PLACEMENT_HEIGHT

	for i = minDist, maxDist, PLACEMENT_CHECK_STEP do
		local x = playerX + FixedMul(i, cos(pmo.angle))
		local y = playerY + FixedMul(i, sin(pmo.angle))

		local subsector = R_PointInSubsectorOrNil(x, y)
		if not subsector then return nil, nil, nil end
		local sector = subsector.sector

		local z = P_GetZAt(sector.f_slope, x, y, sector.floorheight)

		if minZ <= z and maxZ >= z
		and (bestX == nil or mod.isItemPlacementPositionBetter(x, y, z, bestX, bestY, bestZ, playerX, playerY, playerZ)) then
			bestX, bestY, bestZ = x, y, z
		end

		for fof in sector.ffloors() do
			local z = P_GetZAt(fof.t_slope, x, y, fof.topheight)

			-- if minZ <= z and maxZ >= z
			-- and fof.flags & FF_SOLID == FF_SOLID
			-- and (bestX == nil or mod.isItemPlacementPositionBetter(x, y, z, bestX, bestY, bestZ, playerX, playerY, playerZ)) then
			-- 	bestX, bestY, bestZ = x, y, z
			-- end

			if minZ <= z and maxZ >= z
			and fof.flags & FF_SOLID == FF_SOLID then
				if (bestX == nil or mod.isItemPlacementPositionBetter(x, y, z, bestX, bestY, bestZ, playerX, playerY, playerZ)) then
					bestX, bestY, bestZ = x, y, z
				end
			end
		end
	end

	return bestX, bestY, bestZ
end

---@param player player_t
---@param itemType integer
---@return mobj_t?
function mod.placeItem(player, itemType)
	local def = mod.itemDefs[itemType]

	local bestX, bestY, bestZ
	if mod.itemDefs[itemType].carriable then
		bestX, bestY, bestZ = mod.findItemPlacementPosition(player, itemType)
	else
		bestX, bestY, bestZ = mod.findLargeItemPlacementPosition(player, itemType)
	end

	local mo
	if bestX ~= nil then
		mo = mod.spawnGroundItem(bestX, bestY, bestZ, itemType)

		if mo and not P_CheckPosition(mo, bestX, bestY) then
			P_RemoveMobj(mo)
			mo = nil
		end
	end

	if mo then
		mo.angle = player.mo.angle
		if not def.carriable then
			mo.angle = mod.snapAngleToCardinalDirection($)
		end

		if def.onPlace then
			def.onPlace(mo)
		end
	end

	return mo
end

---@param player player_t
---@return mobj_t?
function mod.placeCarriedItem(player)
	local itemType = mod.getMainCarriedItemType(player)
	if not itemType then return nil end

	local mo = mod.placeItem(player, itemType)

	if mo then
		mod.uncarryItem(player)
	end

	return mo
end
