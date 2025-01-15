---@class itemapi
local mod = itemapi


local MAX_PLACEMENT_HEIGHT = 64*FU
local PLACEMENT_CHECK_STEP = 8*FU


---@param x fixed_t
---@param y fixed_t
---@param radius fixed_t
---@param fof? ffloor_t
---@return fixed_t
local function findItemFloorZOnSurface(x, y, radius, fof)
	local l, b = x - radius, y - radius
	local r, t = x + radius, y + radius

	local sector = R_PointInSubsectorOrNil(x, y).sector
	local slope

	if fof then
		slope = fof.t_slope

		if not slope then
			return fof.topheight
		end
	else
		slope = sector.f_slope

		if not slope then
			return sector.floorheight
		end
	end

	local highestZ = INT32_MIN

	for x = l, r, radius do
		for y = b, t, radius do
			local ss = R_PointInSubsectorOrNil(x, y)
			if not (ss and ss.sector == sector) then continue end

			local z = P_GetZAt(slope, x, y)
			if highestZ < z then
				highestZ = z
			end
		end
	end

	return highestZ
end

---After a valid surface has been found, this is used to potentially adjust the position
---of the item if other solid objects are blocking this specific position.
---If no suitable position is found close enough to the desired position, returns nil
---@param p player_t
---@param cx fixed_t
---@param cy fixed_t
---@param fof? ffloor_t
---@param radius fixed_t
---@param height fixed_t
---@return fixed_t?
---@return fixed_t?
---@return fixed_t?
local function adjustItemPlacementPosition(p, cx, cy, fof, radius, height)
	local distStep = radius * 2 * 9/8
	local maxDist = min(4 * distStep, 64*FU)
	local sector = R_PointInSubsectorOrNil(cx, cy).sector

	for dist = 0, maxDist, distStep do
		-- Limited amount of tries
		for _ = 1, 10 do
			local dir = mod.randomAngle()
			local x = cx + FixedMul(cos(dir), dist)
			local y = cy + FixedMul(sin(dir), dist)

			local ss = R_PointInSubsectorOrNil(x, y)
			if not (ss and ss.sector == sector) then continue end

			local z = findItemFloorZOnSurface(x, y, radius, fof)

			local x1, y1, z1 = x - radius, y - radius, z
			local x2, y2, z2 = x + radius, y + radius, z + height

			if not (
				mod.doesAreaContainSolidGeometry(x1, y1, z1, x2, y2, z2)
				or mod.doesAreaContainMobjs(x1, y1, z1, x2, y2, z2, p)
			) then
				return x, y, z
			end
		end
	end

	return nil, nil, nil
end

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
---@param adjusted? boolean Only use serverside or it will desync
---@param canPlaceOnSurface? fun(surfaceType: "sector_floor"|"fof_top", surface: any): boolean
---@return fixed_t?
---@return fixed_t?
---@return fixed_t?
function mod.findItemPlacementPosition(p, itemType, adjusted, canPlaceOnSurface)
	local bestX, bestY, bestZ
	local bestFOF

	local pmo = p.mo
	local def = mod.itemDefs[itemType]

	local playerX = pmo.x
	local playerY = pmo.y
	local playerZ = pmo.z + pmo.height * 2 / 3

	local mt = def.mobjType
	local mobjScale = def.mobjScale or FU
	local mobjRadius = FixedMul(mt and mobjinfo[mt].radius or def.mobjRadius or 32*FU, mobjScale)
	local mobjHeight = FixedMul(mt and mobjinfo[mt].height or def.mobjHeight or 64*FU, mobjScale)

	local minDist = pmo.radius + mobjRadius
	local maxDist = pmo.radius * 4 + mobjRadius
	local minZ, maxZ = playerZ - MAX_PLACEMENT_HEIGHT, playerZ + MAX_PLACEMENT_HEIGHT

	for i = minDist, maxDist, PLACEMENT_CHECK_STEP do
		local x = playerX + FixedMul(i, cos(pmo.angle))
		local y = playerY + FixedMul(i, sin(pmo.angle))

		local subsector = R_PointInSubsectorOrNil(x, y)
		if not subsector then return nil, nil, nil end
		local sector = subsector.sector

		local x1, y1 = x - mobjRadius, y - mobjRadius
		local x2, y2 = x + mobjRadius, y + mobjRadius

		local z = P_GetZAt(sector.f_slope, x, y, sector.floorheight)

		if minZ <= z and maxZ >= z
		and (not canPlaceOnSurface or canPlaceOnSurface("sector_floor", sector)) then
			-- Calculate more accurately this time
			z = findItemFloorZOnSurface(x, y, mobjRadius)

			if minZ <= z and maxZ >= z
			and (bestX == nil or mod.isItemPlacementPositionBetter(x, y, z, bestX, bestY, bestZ, playerX, playerY, playerZ))
			and not mod.doesAreaContainSolidGeometry(x1, y1, z, x2, y2, z + mobjHeight)
			then
				bestX, bestY, bestZ = x, y, z
				bestFOF = nil
			end
		end

		for fof in sector.ffloors() do
			local z = P_GetZAt(fof.t_slope, x, y, fof.topheight)

			if minZ <= z and maxZ >= z
			and fof.flags & FF_BLOCKOTHERS
			and (not canPlaceOnSurface or canPlaceOnSurface("fof_top", fof)) then
				-- Calculate more accurately this time
				z = findItemFloorZOnSurface(x, y, mobjRadius, fof)

				if minZ <= z and maxZ >= z
				and (bestX == nil or mod.isItemPlacementPositionBetter(x, y, z, bestX, bestY, bestZ, playerX, playerY, playerZ))
				and not mod.doesAreaContainSolidGeometry(x1, y1, z, x2, y2, z + mobjHeight)
				then
					bestX, bestY, bestZ = x, y, z
					bestFOF = fof
				end
			end
		end
	end

	if adjusted and bestX ~= nil then
		bestX, bestY, bestZ = adjustItemPlacementPosition(p, bestX, bestY, bestFOF, mobjRadius, mobjHeight)
	end

	return bestX, bestY, bestZ
end

---@param player player_t
---@param itemType integer
---@param itemData? any
---@param canPlaceOnSurface? fun(surfaceType: "sector_floor"|"fof_top", surface: any): boolean
---@return mobj_t?
function mod.placeItem(player, itemType, itemData, canPlaceOnSurface)
	local def = mod.itemDefs[itemType]

	local bestX, bestY, bestZ
	if mod.itemDefs[itemType].carriable then
		bestX, bestY, bestZ = mod.findItemPlacementPosition(player, itemType, true, canPlaceOnSurface)
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

		mo.itemapi_data = itemData

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

	local slot = player.itemapi_carrySlots["right_hand"]
	local mo = mod.placeItem(player, itemType, slot.itemData)

	if mo then
		mod.uncarryItem(player)
	end

	return mo
end
