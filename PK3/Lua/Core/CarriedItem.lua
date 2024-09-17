---@class itemapi
local mod = itemapi


freeslot("MT_ITEMAPI_CARRIEDITEM", "S_ITEMAPI_CARRIEDITEM")


mobjinfo[MT_ITEMAPI_CARRIEDITEM] = {
	spawnstate = S_ITEMAPI_CARRIEDITEM,
	spawnhealth = 1,
	radius = 8*FU,
	height = 16*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOGRAVITY
}

states[S_ITEMAPI_CARRIEDITEM] = { SPR_UNKN, 0 }


-- ...I assume Sonic & co are right handed lol?
---@param player player_t
function mod.getCarriedItemPosition(player)
	local mo = player.mo
	local dist = mo.radius * 2
	local angle = player.drawangle - ANGLE_45

	local x = mo.x + FixedMul(dist, cos(angle))
	local y = mo.y + FixedMul(dist, sin(angle))
	local z = mo.z + mo.height / 2

	return x, y, z
end

---@param player player_t
---@return integer?
function mod.getMainCarriedItemType(player)
	local slot = player.itemapi_carrySlots["right_hand"]
	return slot and slot.itemType
end

---@param player player_t
---@param slotID? string|integer
function mod.spawnCarriedItemMobj(player, slotID)
	slotID = $ or "right_hand"

	local slot = player.itemapi_carrySlots[slotID]
	local itemDef = mod.itemDefs[slot.itemType]

	local x, y, z = mod.getCarriedItemPosition(player)
	local mo = P_SpawnMobj(x, y, z, MT_ITEMAPI_CARRIEDITEM)
	slot.mobj = mo

	if itemDef.model then
		mo.itemapi_model = mod.spawnModelOnMobj(mo, itemDef.model)
		mod.setModelTransform(mo.itemapi_model, mo.x, mo.y, mo.z, 0, itemDef.modelScale or FU)

		mo.sprite = SPR_NULL
	else
		mo.sprite = itemDef.mobjSprite
		mo.frame = itemDef.mobjFrame
	end

	if itemDef.onCarry then
		itemDef.onCarry(mo)
	end
end

---Puts an item in a player's hand.
---The player only takes the item if their hands are free.
---@param player player_t
---@param itemType itemapi.ItemType
---@param slotID? string|integer
---@return boolean carried True if the item was put in the player's hand.
function mod.carryItem(player, itemType, slotID)
	slotID = $ or "right_hand"

	if player.itemapi_carrySlots[slotID] then return false end

	local slotDef = mod.carrySlotDefs[slotID]
	local itemDef = mod.itemDefs[itemType]

	local slot = { itemType = itemDef.index }

	player.itemapi_carrySlots[slotDef.index] = slot
	player.itemapi_carrySlots[slotDef.id] = slot

	mod.spawnCarriedItemMobj(player)

	return true
end

-- ---Puts an item in a player's hand.
-- ---The player only takes the item if their hands are free.
-- ---@param player player_t
-- ---@param itemType itemapi.ItemType
-- ---@param slotID? string|integer
-- ---@return boolean carried True if the item was put in the player's hand.
-- function mod.carryItem(player, itemType, slotID)
-- 	slotID = $ or "right_hand"

-- 	if player.itemapi_carrySlots[slotID] then return false end

-- 	local slotDef = mod.carrySlotDefs[slotID]
-- 	local itemDef = mod.itemDefs[itemType]

-- 	local x, y, z = mod.getCarriedItemPosition(player)
-- 	local mo = P_SpawnMobj(x, y, z, MT_ITEMAPI_CARRIEDITEM)

-- 	local slot = {
-- 		itemType = itemDef.index,
-- 		mobj = mo
-- 	}

-- 	player.itemapi_carrySlots[slotDef.index] = slot
-- 	player.itemapi_carrySlots[slotDef.id] = slot

-- 	if itemDef.model then
-- 		mo.itemapi_model = mod.spawnModelOnMobj(mo, itemDef.model)
-- 		mod.setModelTransform(mo.itemapi_model, mo.x, mo.y, mo.z, 0, itemDef.modelScale or FU)

-- 		mo.sprite = SPR_NULL
-- 	else
-- 		mo.sprite = itemDef.mobjSprite
-- 		mo.frame = itemDef.mobjFrame
-- 	end

-- 	if itemDef.onCarry then
-- 		itemDef.onCarry(mo)
-- 	end

-- 	return true
-- end

---@param player player_t
function mod.updateCarriedItems(player)
	local slots = player.itemapi_carrySlots

	for i = 1, #mod.carrySlotDefs do
		local slot = slots[i]
		if not slot then continue end

		local mo = slot.mobj
		if not mo then continue end

		local x, y, z = mod.getCarriedItemPosition(player)
		P_MoveOrigin(mo, x, y, z)

		mo.angle = player.mo.angle
	end
end

---@param player player_t
---@param slotID? string|integer
function mod.uncarryItem(player, slotID)
	slotID = $ or "right_hand"

	local slot = player.itemapi_carrySlots[slotID]
	if not slot then return end

	local slotDef = mod.carrySlotDefs[slotID]
	local itemDef = mod.itemDefs[slot.itemType]
	local mo = slot.mobj

	if itemDef.model and mo.itemapi_model then
		itemapi.despawnModel(mo.itemapi_model)
	end

	if itemDef.onUncarry then
		itemDef.onUncarry(mo)
	end

	P_RemoveMobj(mo)

	player.itemapi_carrySlots[slotDef.index] = nil
	player.itemapi_carrySlots[slotDef.id] = nil
end

---@param player player_t
---@param slotID? string|integer
function mod.smartUncarryItem(player, slotID)
	slotID = $ or "right_hand"

	local slot = player.itemapi_carrySlots[slotID]
	if not slot then return end

	local itemType = slot.itemType
	local multiple = slot.multiple

	mod.uncarryItem(player, slotID)

	if multiple and player.itemapi_inventory:remove(itemType) then
		mod.carryItem(player, itemType)
		player.itemapi_carrySlots[slotID].multiple = true
	end
end
