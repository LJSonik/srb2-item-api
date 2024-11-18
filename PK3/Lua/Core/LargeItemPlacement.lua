---@class itemapi
local mod = itemapi


local MAX_PLACEMENT_HEIGHT = 64*FU


---@param p player_t
---@param itemType itemapi.ItemType
---@return fixed_t
---@return fixed_t
---@return fixed_t
---@return angle_t
function mod.getDefaultLargeItemPlacementPosition(p, itemType)
	local def = mod.itemDefs[itemType]
	local mt = def.mobjType
	local pmo = p.mo

	local dir = mod.snapAngleToCardinalDirection(pmo.angle)
	local dist = pmo.radius

	local mobjRadius = (mt and mobjinfo[mt].radius or def.mobjRadius or 32*FU)
	local dim = def.dimensions
	if dim then
		dist = $ + dim[1] * FU / 2
	else
		dist = $ + mobjRadius
	end

	local x = pmo.x + FixedMul(dist, cos(dir))
	local y = pmo.y + FixedMul(dist, sin(dir))
	local z = pmo.z

	return x, y, z, dir
end

---@param itemType itemapi.ItemType
---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param angle angle_t
---@return fixed_t, fixed_t, fixed_t, fixed_t, fixed_t, fixed_t
function mod.getLargeItemBBox(itemType, x, y, z, angle)
	local def = mod.itemDefs[itemType]

	local dim = def.dimensions
	local widthX = dim[1] * FU
	local widthY = dim[2] * FU
	local height = dim[3] * FU

	local x1 = x - widthX / 2
	local y1 = y - widthY / 2
	local z1 = z

	local x2 = x1 + widthX
	local y2 = y1 + widthY
	local z2 = z1 + height

	x1, y1 = mod.rotatePointAroundPivot(x1, y1, x, y, angle)
	x2, y2 = mod.rotatePointAroundPivot(x2, y2, x, y, angle)

	if x1 > x2 then
		x1, x2 = x2, x1
	end
	if y1 > y2 then
		y1, y2 = y2, y1
	end

	return x1, y1, z1, x2, y2, z2
end

---@param player player_t
---@param itemType itemapi.ItemType
---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param angle angle_t
---@return boolean
function mod.canPlaceLargeItemAtPosition(player, itemType, x, y, z, angle)
	local x1, y1, z1, x2, y2, z2 = mod.getLargeItemBBox(itemType, x, y, z, angle)

	return
		mod.isGroundInAreaFlat(x1, y1, x2, y2, z, player)
		and not mod.doesAreaContainMobjs(x1, y1, z1, x2, y2, z2, player)
end

---@param player player_t
---@param itemType itemapi.ItemType
---@return boolean
function mod.canPlaceLargeItem(player, itemType)
	return mod.canPlaceLargeItemAtPosition(player, itemType, mod.findLargeItemPlacementPosition(player, itemType))
end

---@param p player_t
---@param itemType itemapi.ItemType
---@return fixed_t, fixed_t, fixed_t
---@return angle_t
function mod.findLargeItemPlacementPosition(p, itemType)
	local pmo = p.mo

	local playerX = pmo.x
	local playerY = pmo.y
	local playerZ = pmo.z + pmo.height * 2 / 3

	local minZ, maxZ = playerZ - MAX_PLACEMENT_HEIGHT, playerZ + MAX_PLACEMENT_HEIGHT

	local x, y, _, angle = mod.getDefaultLargeItemPlacementPosition(p, itemType)

	local subsector = R_PointInSubsectorOrNil(x, y)
	if not subsector then return x, y, pmo.z, angle end
	local sector = subsector.sector

	local bestZ

	local z = P_GetZAt(sector.f_slope, x, y, sector.floorheight)
	if minZ <= z and maxZ >= z then
		bestZ = z
	end

	for fof in sector.ffloors() do
		local z = P_GetZAt(fof.t_slope, x, y, fof.topheight)

		if minZ <= z and maxZ >= z
		and fof.flags & FF_BLOCKOTHERS
		and (bestZ == nil or mod.isItemPlacementPositionBetter(x, y, z, x, y, bestZ, playerX, playerY, playerZ)) then
			bestZ = z
		end
	end

	if bestZ == nil then
		bestZ = pmo.z
	end

	return x, y, bestZ, angle
end
