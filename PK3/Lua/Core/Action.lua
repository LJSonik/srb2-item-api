---@class itemapi
local mod = itemapi


---@class itemapi.ItemActionDef
---@field name string
---@field requiredGroundItem? string
---@field condition? fun(): boolean
---@field action fun(player: player_t)
---@field duration? tic_t

---@class itemapi.GroundItemActionDef
---@field name string
---@field requiredCarriedItem? string
---@field condition? fun(): boolean
---@field selectSpot? boolean
---@field action fun(player: player_t, mobj: mobj_t, groundItemDef: itemapi.ItemDef, carriedItemDef: itemapi.ItemDef?, spotIndex: integer?)
---@field duration? tic_t

---@class itemapi.MobjActionDef
---@field mobjType mobjtype_t
---@field state? statenum_t
---@field name string
---@field action fun(player: player_t, mobj: mobj_t)
---@field duration? tic_t
---@field animation? itemapi.ActionAnimationDef

---@class itemapi.Action
---@field type "carried_item"|"ground_item"|"mobj"
---@field target? mobj_t
---@field index integer
---@field spotIndex? integer
---@field progress tic_t

---@class player_t
---@field itemapi_action? itemapi.Action


local MAX_ACTION_DIST = 128*FU
local MAX_ACTION_HEIGHT = 96*FU


---@type { [mobjtype_t]: { [statenum_t]: itemapi.MobjActionDef } }
mod.mobjActionDefs = {}


---@param player player_t
---@return nil|itemapi.ItemActionDef|itemapi.GroundItemActionDef|itemapi.MobjActionDef
function mod.getActionDefFromPlayer(player)
	local action = player.itemapi_action
	local actionType = action.type

	if actionType == "carried_item" then
		local itemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
		return itemDef and itemDef.actions[action.index]
	elseif actionType == "ground_item" then
		local mobj = action.target
		if not (mobj and mobj.valid) then return nil end

		local groundItemDef = mod.getItemDefFromMobj(mobj)
		return groundItemDef.groundActions[action.index]
	elseif actionType == "mobj" then
		local mobj = action.target
		if not (mobj and mobj.valid) then return nil end

		local actionDefs = mod.mobjActionDefs[mobj.type]
		return actionDefs and (actionDefs[mobj.state] or actionDefs[S_NULL])
	end
end

---Registers a new item action
---@param itemID itemapi.ItemType
---@param def itemapi.ItemActionDef
function mod.addItemAction(itemID, def)
	local itemDef = mod.itemDefs[itemID]
	table.insert(itemDef.actions, def)
end

---Registers a new ground item action
---@param itemID itemapi.ItemType
---@param def itemapi.GroundItemActionDef
function mod.addGroundItemAction(itemID, def)
	local itemDef = mod.itemDefs[itemID]
	table.insert(itemDef.groundActions, def)
end

---Registers a new mobj action
---@param mobjType mobjtype_t
---@param def itemapi.MobjActionDef
function mod.addMobjAction(mobjType, def)
	def.mobjType = mobjType
	mod.mobjActionDefs[mobjType] = $ or {}
	mod.mobjActionDefs[mobjType][def.state or S_NULL] = def

	-- Required to ensure the mobjs are synced in servers
	-- and can be detected when searching for nearby objects
	mobjinfo[mobjType].flags = $ & ~(MF_NOTHINK | MF_NOBLOCKMAP)
end

---@param player player_t
---@param mobj? mobj_t
---@return table[]
function mod.findAvailableActions(player, mobj)
	local availableActions = {}

	local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
	local groundItemID = mobj and mod.getItemIDFromMobj(mobj)

	if carriedItemDef then
		for i, actionDef in ipairs(carriedItemDef.actions) do
			if actionDef.requiredGroundItem and not mod.doesItemMatchSelector(groundItemDefID, actionDef.requiredGroundItem) then
				continue
			end

			table.insert(availableActions, {
				type = "carried_item",
				index = i,
				def = actionDef
			})
		end
	end

	if mobj then
		local actionDefs = mod.mobjActionDefs[mobj.type]
		local actionDef = actionDefs and (actionDefs[mobj.state] or actionDefs[S_NULL])
		if actionDef and not carriedItemDef then
			table.insert(availableActions, {
				type = "mobj",
				index = 1,
				def = actionDef
			})
		end

		if groundItemID then
			local groundItemDef = mod.itemDefs[groundItemID]

			for i, actionDef in ipairs(groundItemDef.groundActions) do
				local carriedItemID = carriedItemDef and carriedItemDef.id
				if actionDef.requiredCarriedItem and not mod.doesItemMatchSelector(carriedItemID, actionDef.requiredCarriedItem) then
					continue
				end

				table.insert(availableActions, {
					type = "ground_item",
					index = i,
					def = actionDef
				})
			end
		end
	end

	return availableActions
end

---@param player player_t
---@param mobj mobj_t
---@return boolean
function mod.canPlayerPerformActionsOnMobj(player, mobj)
	local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
	local groundItemID = mobj and mod.getItemIDFromMobj(mobj)

	if carriedItemDef then
		for _, actionDef in ipairs(carriedItemDef.actions) do
			if not actionDef.requiredGroundItem or mod.doesItemMatchSelector(groundItemID, actionDef.requiredGroundItem) then
				return true
			end
		end
	end

	local actionDefs = mod.mobjActionDefs[mobj.type]
	local actionDef = actionDefs and (actionDefs[mobj.state] or actionDefs[S_NULL])
	if actionDef and not carriedItemDef then
		return true
	end

	if groundItemID then
		local groundItemDef = mod.itemDefs[groundItemID]

		if not carriedItemDef then
			return true
		end

		for _, actionDef in ipairs(groundItemDef.groundActions) do
			local carriedItemID = carriedItemDef and carriedItemDef.id
			if not actionDef.requiredCarriedItem or mod.doesItemMatchSelector(carriedItemID, actionDef.requiredCarriedItem) then
				return true
			end
		end
	end

	return false
end

---@param player player_t
---@return boolean
function mod.canPlayerContinueAction(player)
	local action = player.itemapi_action

	if action.type == "carried_item" then
		local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
		if not carriedItemDef then return false end

		local actionDef = carriedItemDef.actions

		if actionDef.requiredGroundItem then
			local groundItem = action.groundItem
			if not (groundItem and groundItem.valid) then return false end

			local dist = R_PointToDist2(player.mo.x, player.mo.y, groundItem.x, groundItem.y)
			if dist > MAX_ACTION_DIST then return false end

			local groundItemID = mod.getItemIDFromMobj(groundItem)
			if not mod.doesItemMatchSelector(groundItemID, actionDef.requiredGroundItem) then
				return false
			end
		end
	elseif action.type == "ground_item" then
		local mobj = action.target
		if not mobj.valid then return false end

		local dist = R_PointToDist2(player.mo.x, player.mo.y, mobj.x, mobj.y)
		if dist > MAX_ACTION_DIST then return false end

		local groundItemDef = mod.getItemDefFromMobj(mobj)
		local actionDef = groundItemDef.groundActions[action.index]

		if actionDef.requiredCarriedItem then
			local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
			local carriedItemID = carriedItemDef and carriedItemDef.id

			if not mod.doesItemMatchSelector(carriedItemID, actionDef.requiredCarriedItem) then
				return false
			end
		end
	elseif action.type == "mobj" then
		local mobj = action.target
		if not mobj.valid then return false end

		local dist = R_PointToDist2(player.mo.x, player.mo.y, mobj.x, mobj.y)
		if dist > MAX_ACTION_DIST then return false end
	end

	return true
end

---@param player player_t
---@param index integer
---@param groundItem? mobj_t
function mod.performCarriedItemAction(player, index, groundItem)
	local itemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
	if not itemDef then return end

	local actionDef = itemDef.actions[index]
	if not actionDef then return end

	local groundItemID = mobj and mod.getItemIDFromMobj(mobj)
	local requiredID = actionDef.requiredGroundItem
	if requiredID and not mod.doesItemMatchSelector(groundItemID, requiredID) then return end

	if player.itemapi_action then
		mod.stopAction(player)
	end

	if actionDef.duration ~= nil then
		player.itemapi_action = {
			type = "carried_item",
			index = index,
			groundItem = groundItem,
			progress = 0
		}
	else
		actionDef.action(player, groundItem)
	end
end

---@param player player_t
---@param actionIndex integer
---@param groundItem mobj_t
---@param spotIndex? integer
function mod.performGroundItemAction(player, actionIndex, groundItem, spotIndex)
	if not groundItem then return end

	local groundItemDef = mod.getItemDefFromMobj(groundItem)
	if not groundItemDef then return end

	local actionDef = groundItemDef.groundActions[actionIndex]
	if not actionDef then return end

	local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
	local carriedItemID = carriedItemDef and carriedItemDef.id

	local requiredID = actionDef.requiredCarriedItem
	if requiredID and not mod.doesItemMatchSelector(carriedItemID, requiredID) then return end

	if player.itemapi_action then
		mod.stopAction(player)
	end

	if actionDef.duration ~= nil then
		player.itemapi_action = {
			type = "ground_item",
			target = groundItem,
			index = actionIndex,
			spotIndex = spotIndex,
			progress = 0
		}

		mod.startPlayerActionAnimation(player)
	else
		actionDef.action(player, groundItem, groundItemDef, carriedItemDef, spotIndex)
	end
end

---@param player player_t
---@param index integer
---@param mobj mobj_t
function mod.performMobjAction(player, index, mobj)
	if not mobj then return end

	local actionDefs = mod.mobjActionDefs[mobj.type]
	local actionDef = actionDefs and (actionDefs[mobj.state] or actionDefs[S_NULL])
	if not actionDef then return end

	if player.itemapi_action then
		mod.stopAction(player)
	end

	if actionDef.duration ~= nil then
		player.itemapi_action = {
			type = "mobj",
			target = mobj,
			progress = 0
		}

		mod.startPlayerActionAnimation(player)
	else
		actionDef.action(player, mobj)
	end
end

---@param player player_t
function mod.updateAction(player)
	local action = player.itemapi_action

	if not mod.canPlayerContinueAction(player) then
		mod.stopAction(player)
		return
	end

	action.progress = $ + 1

	if action.type == "carried_item" then
		local itemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
		local actionDef = itemDef.actions[action.index]

		if action.progress >= actionDef.duration then
			actionDef.action(player, action.groundItem)
			mod.stopAction(player)
		end
	elseif action.type == "ground_item" then
		local groundItemDef = mod.getItemDefFromMobj(action.target)
		local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
		local actionDef = groundItemDef.groundActions[action.index]

		mod.updatePlayerActionAnimation(player)

		if action.progress >= actionDef.duration then
			actionDef.action(player, action.target, groundItemDef, carriedItemDef)
			mod.stopAction(player)
		end
	elseif action.type == "mobj" then
		local mobj = action.target
		local actionDefs = mod.mobjActionDefs[mobj.type]
		local actionDef = actionDefs and (actionDefs[mobj.state] or actionDefs[S_NULL])

		mod.updatePlayerActionAnimation(player)

		if action.progress >= actionDef.duration then
			actionDef.action(player, action.target)
			mod.stopAction(player)
		end
	end
end

---@param player player_t
function mod.stopAction(player)
	if not player.itemapi_action then return end

	mod.stopPlayerActionAnimation(player)
	player.itemapi_action = nil
end

---@param player player_t
---@return mobj_t?
function mod.findAimedMobj(player)
	local playerMobj = player.mo
	local playerAngle = playerMobj.angle

	local maxDist = MAX_ACTION_DIST
	local maxHeight = MAX_ACTION_HEIGHT
	local maxAngle = ANGLE_45

	local x, y, z = playerMobj.x, playerMobj.y, playerMobj.z
	local x1, y1, z1 = x - maxDist, y - maxDist, z - maxHeight
	local x2, y2, z2 = x + maxDist, y + maxDist, z + maxHeight

	local bestScore, bestMobj = INT32_MAX, nil

	searchBlockmap("objects", function(_, mo)
		local mx, my, mz = mo.x, mo.y, mo.z

		if not (mz > z1 and mz < z2) then return end

		local dist = R_PointToDist2(x, y, mx, my)
		if not (dist < maxDist and mo ~= playerMobj) then return end

		local angle = abs(playerAngle - R_PointToAngle2(x, y, mx, my))
		if angle >= maxAngle then return end

		local mt = mo.type
		local state = mo.state
		local stateToItemType = mod.mobjToItemType[mt]
		if not (stateToItemType and (stateToItemType[state] or stateToItemType[S_NULL])) then
			local stateToActionDef = mod.mobjActionDefs[mt]
			if not (stateToActionDef and (stateToActionDef[state] or stateToActionDef[S_NULL])) then
				return
			end
		end

		if not mod.canPlayerPerformActionsOnMobj(player, mo) then return end

		-- Use some basic heuristic to determine if that mobj
		-- if more likely to be the one the player is interested in
		local score = FixedDiv(angle, maxAngle) / 2
					+ FixedDiv(dist, maxDist)
					+ FixedDiv(abs(z - mz), maxHeight)

		if score < bestScore then
			bestScore, bestMobj = score, mo
		end
	end, player.mo, x1, x2, y1, y2)

	return bestMobj
end
