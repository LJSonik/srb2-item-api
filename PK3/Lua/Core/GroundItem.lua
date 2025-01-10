---@class itemapi
local mod = itemapi


mod.nextGroundItemStateID = 1


freeslot("MT_ITEMAPI_GROUNDITEM", "S_ITEMAPI_GROUNDITEM")

mobjinfo[MT_ITEMAPI_GROUNDITEM] = {
	spawnstate = S_ITEMAPI_GROUNDITEM,
	spawnhealth = 1,
	radius = 4*FU,
	height = 8*FU,
	flags = MF_NOCLIPTHING|MF_SCENERY
}

states[S_ITEMAPI_GROUNDITEM] = {}


---For a given mobj, returns the corresponding item type if there is one, nil otherwise
---@param mobj mobj_t
---@return integer?
function mod.getItemTypeFromMobj(mobj)
	local stateToItemType = mod.mobjToItemType[mobj.type]

	if stateToItemType then
		return stateToItemType[mobj.state] or stateToItemType[S_NULL]
	else
		return nil
	end
end

---For a given mobj, returns the corresponding item ID if there is one, nil otherwise
---@param mobj mobj_t
---@return string?
function mod.getItemIDFromMobj(mobj)
	local type = mod.getItemTypeFromMobj(mobj)
	return type and mod.itemDefs[type].id
end

---For a given mobj, returns the corresponding item definition if there is one, nil otherwise
---@param mobj mobj_t
---@return itemapi.ItemDef?
function mod.getItemDefFromMobj(mobj)
	local type = mod.getItemTypeFromMobj(mobj)
	return mod.itemDefs[type]
end

---@param mobj mobj_t
---@param spotIndex integer
---@return fixed_t, fixed_t, fixed_t
function mod.getGroundItemSpotPosition(mobj, spotIndex)
	local itemDef = mod.getItemDefFromMobj(mobj)
	local spot = itemDef.spots[spotIndex]
	local scale = mobj.scale

	local relX, relY, relZ = spot[1] * scale, spot[2] * scale, spot[3] * scale
	local angle = R_PointToAngle2(0, 0, relX, relY) + mobj.angle
	local dist = R_PointToDist2(0, 0, relX, relY)

	return
		mobj.x + FixedMul(cos(angle), dist),
		mobj.y + FixedMul(sin(angle), dist),
		mobj.z + relZ
end

---@param mobj mobj_t
---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@return integer?
function mod.findClosestGroundItemSpotIndex(mobj, x, y, z)
	local itemDef = mod.getItemDefFromMobj(mobj)
	local spotDefs = itemDef.spots

	local bestSpotIndex, bestDist = nil, INT32_MAX

	for i = 1, #spotDefs do
		local spotX, spotY, spotZ = mod.getGroundItemSpotPosition(mobj, i)
		local dist = mod.pointToDist3D(x, y, z, spotX, spotY, spotZ)
		if dist < bestDist then
			bestSpotIndex, bestDist = i, dist
		end
	end

	return bestSpotIndex
end

---@param def itemapi.ItemDef
function mod.addGroundItem(def)
	local mt = def.mobjType

	if not mt then
		local stateName = "S_ITEMAPI_GROUNDITEM" .. mod.nextGroundItemStateID
		mod.nextGroundItemStateID = $ + 1

		freeslot(stateName)
		mt = MT_ITEMAPI_GROUNDITEM
		def.mobjType = mt
		def.mobjState = _G[stateName]
		if def.model then
			states[def.mobjState] = { SPR_NULL }
		else
			states[def.mobjState] = { def.mobjSprite, def.mobjFrame }
		end
	end

	if mod.mobjToItemType[mt] and mod.mobjToItemType[mt][def.mobjState or S_NULL] then
		error("mobj type and state already used by another item type", 3)
	end

	if not mod.mobjToItemType[mt] then
		addHook("MobjRemoved", mod.groundItemRemovedHook, mt)
		mod.mobjToItemType[mt] = {}
	end

	mod.mobjToItemType[mt][def.mobjState or S_NULL] = def.index

	-- Required to ensure the mobjs are synced in servers
	-- and can be detected when searching for nearby objects
	mobjinfo[mt].flags = $ & ~(MF_NOTHINK | MF_NOBLOCKMAP)
end

---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param id itemapi.ItemType
function mod.spawnGroundItem(x, y, z, id)
	local def = mod.itemDefs[id]
	local mo = P_SpawnMobj(x, y, z, def.mobjType or MT_ITEMAPI_GROUNDITEM)

	if def.mobjState then
		mo.state = def.mobjState
	end

	if def.mobjScale then
		mo.scale = def.mobjScale
	end

	if def.model then
		mo.itemapi_model = mod.spawnModelOnMobj(mo, def.model)
		mod.setModelTransform(mo.itemapi_model, mo.x, mo.y, mo.z, 0, def.modelScale or FU)
	end

	if def.onSpawn then
		def.onSpawn(mo)
	end

	for _, tickerDef in ipairs(def.groundTickers) do
		mod.startMobjTicker(mo, tickerDef.ticker, tickerDef.frequency)
	end

	return mo
end

---@param mobj mobj_t
---@param itemType itemapi.ItemType
function mod.applyGroundItemAppearanceToMobj(mobj, itemType)
	local def = itemapi.itemDefs[itemType]

	if def.model then
		mobj.itemapi_model = itemapi.spawnModelOnMobj(mobj, def.model)
		local scale = FixedMul(def.modelScale or FU, mobj.scale)
		itemapi.setModelTransform(mobj.itemapi_model, mobj.x, mobj.y, mobj.z, mobj.angle, scale)

		mobj.sprite = SPR_NULL
	else
		mobj.sprite = def.mobjSprite
		mobj.frame = def.mobjFrame
	end
end

function mod.groundItemRemovedHook(mo)
	if not (mo and mo.valid) then return end

	local itemType = mod.getItemTypeFromMobj(mo)
	if not itemType then return end

	local def = mod.itemDefs[itemType]
	if def.onDespawn then
		def.onDespawn(mo)
	end

	if def.model and mo.itemapi_model then
		itemapi.despawnModel(mo.itemapi_model)
	end
end
