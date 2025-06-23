---@class itemapi
local mod = itemapi


---@class itemapi.ActionDef
---@field name string
---@field duration? tic_t
---@field variableDuration? boolean
---
---@field animations  itemapi.ActionAnimationDef[]
---@field animation?  itemapi.ActionAnimationDef
---@field animation1? itemapi.ActionAnimationDef
---@field animation2? itemapi.ActionAnimationDef
---@field animation3? itemapi.ActionAnimationDef

---@class itemapi.ItemActionDef : itemapi.ActionDef
---@field requiredGroundItem? string
---@field condition? fun(): boolean
---@field action fun(player: player_t)
---
---@field start fun(player: player_t)
---@field tick fun(player: player_t, actors: player_t[])
---@field stop fun(player: player_t)
---
---@field onActorStart fun(player: player_t)
---@field onActorStop fun(player: player_t)

---@class itemapi.GroundItemActionDef : itemapi.ActionDef
---@field requiredCarriedItem? string
---@field condition? fun(player: player_t, mobj: mobj_t): boolean
---@field selectSpot? boolean
---@field action fun(player: player_t, mobj: mobj_t, groundItemDef: itemapi.ItemDef, carriedItemDef: itemapi.ItemDef?, spotIndex: integer?)
---@field actionV2 fun(action: itemapi.Action, mobj: mobj_t, actors: player_t[])
---
---@field start fun(action: itemapi.Action, mobj: mobj_t)
---@field tick fun(action: itemapi.Action, mobj: mobj_t, actors: player_t[])
---@field stop fun(action: itemapi.Action, mobj: mobj_t)
---
---@field onActorStart fun(action: itemapi.Action, mobj: mobj_t, actor: player_t)
---@field onActorStop fun(action: itemapi.Action, mobj: mobj_t, actor: player_t)

---@class itemapi.MobjActionDef : itemapi.ActionDef
---@field mobjType mobjtype_t
---@field state? statenum_t
---@field action fun(player: player_t, mobj: mobj_t)

---@alias itemapi.ActionType "carried_item"|"ground_item"|"mobj"

---@class itemapi.Action
---@field arrayIndex integer
---@field despawning? boolean
---@field type itemapi.ActionType
---@field actors player_t[]
---@field target? any
---@field itemType? integer
---@field index integer
---@field spotIndex? integer
---@field progress tic_t
---@field completed? boolean

---@class player_t
---@field itemapi_action? itemapi.Action


local MAX_ACTION_DIST = 128*FU
local MAX_ACTION_HEIGHT = 96*FU


---@type { [mobjtype_t]: { [statenum_t]: itemapi.MobjActionDef } }
mod.mobjActionDefs = {}

---@class itemapi.Vars
---@field actions itemapi.Action[]
mod.vars.actions = {}

---@param action itemapi.Action
---@return itemapi.ActionDef?
function mod.getActionDef(action)
	local actionType = action.type

	if actionType == "carried_item" then
		local itemDef = mod.itemDefs[action.itemType]
		return itemDef and itemDef.actions[action.index]
	elseif actionType == "ground_item" then
		local itemDef = mod.itemDefs[action.itemType]
		return itemDef.groundActions[action.index]
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

	mod.parseSugarArray(def, "animations", "animation")

	for i, anim in ipairs(def.animations) do
		if type(anim) == "string" then
			def.animations[i] = { type = anim }
		end
	end

	-- Required to ensure the mobjs are synced in servers
	-- and can be detected when searching for nearby objects
	mobjinfo[mobjType].flags = $ & ~(MF_NOTHINK | MF_NOBLOCKMAP)
end

---@param actionType itemapi.ActionType
---@return itemapi.Action
function mod.spawnAction(actionType)
	local index = #mod.vars.actions + 1

	local action = {
		arrayIndex = index,
		type = actionType,
		actors = {},
		progress = 0
	}

	mod.vars.actions[index] = action

	return action
end

function mod.updateActions()
	local actions = mod.vars.actions

	for i = #actions, 1, -1 do
		local action = actions[i]
		local actionDef = mod.getActionDef(action)

		for i = #action.actors, 1, -1 do
			local actor = action.actors[i]

			if not mod.canPlayerContinueAction(actor) then
				mod.stopAction(actor)
				continue
			end

			action.progress = $ + 1
		end

		if action.despawning then return end

		if actionDef.tick then
			if action.type == "carried_item" then
				actionDef.tick(action.target, action.actors)
			elseif action.type == "ground_item" then
				actionDef.tick(action, action.target, action.actors)
			end
		end

		mod.updateActionAnimation(action)

		if not actionDef.variableDuration and action.progress >= (actionDef.duration or 0) then
			mod.completeAction(action)
		end
	end
end

---@param action itemapi.Action
function mod.despawnAction(action)
	if action.despawning then return end
	action.despawning = true

	for i = #action.actors, 1, -1 do
		mod.stopAction(action.actors[i])
	end

	local actionDef = mod.getActionDef(action)
	if actionDef.stop then
		if action.type == "carried_item" then
			actionDef.stop(action.target)
		elseif action.type == "ground_item" then
			actionDef.stop(action, action.target)
		end
	end

	mod.stopActionAnimation(action)
	mod.removeIndexFromUnorderedArrayAndUpdateField(mod.vars.actions, action.arrayIndex, "arrayIndex")
end

---@param action itemapi.Action
function mod.completeAction(action)
	local actionDef = mod.getActionDef(action)
	local actor = mod.randomElement(action.actors)

	action.completed = true

	if not actionDef.stop then
		if action.type == "carried_item" then
			actionDef.action(actor, action.groundItem)
		elseif action.type == "ground_item" then
			local groundItemDef = mod.getItemDefFromMobj(action.target)
			local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(actor)]

			if actionDef.actionV2 then
				actionDef.actionV2(action, action.target, action.actors)
			else
				actionDef.action(actor, action.target, groundItemDef, carriedItemDef, action.spotIndex)
			end
		elseif action.type == "mobj" then
			actionDef.action(actor, action.target)
		end
	end

	mod.despawnAction(action)
end

function mod.uninitialiseActions()
	for i = #mod.vars.actions, 1, -1 do
		mod.despawnAction(mod.vars.actions[i])
	end
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
				if actionDef.requiredCarriedItem and not mod.doesItemMatchSelector(carriedItemID, actionDef.requiredCarriedItem)
				or actionDef.condition and not actionDef.condition(player, mobj) then
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

	local pmo = player.mo
	if not pmo then return false end

	if action.type == "carried_item" then
		local carriedItemDef = mod.itemDefs[mod.getMainCarriedItemType(player)]
		if not carriedItemDef then return false end

		local actionDef = carriedItemDef.actions[action.index]

		if actionDef.requiredGroundItem then
			local groundItem = action.groundItem
			if not (groundItem and groundItem.valid) then return false end

			local dist = R_PointToDist2(pmo.x, pmo.y, groundItem.x, groundItem.y)
			if dist > MAX_ACTION_DIST then return false end

			local groundItemID = mod.getItemIDFromMobj(groundItem)
			if not mod.doesItemMatchSelector(groundItemID, actionDef.requiredGroundItem) then
				return false
			end
		end
	elseif action.type == "ground_item" then
		local mobj = action.target
		if not mobj.valid then return false end

		local dist = R_PointToDist2(pmo.x, pmo.y, mobj.x, mobj.y)
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

		local dist = R_PointToDist2(pmo.x, pmo.y, mobj.x, mobj.y)
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
		local action = mod.spawnAction("carried_item")
		action.target = player
		action.itemType = mod.getMainCarriedItemType(player)
		action.index = index
		action.groundItem = groundItem

		if actionDef.start then
			actionDef.start(action.target)
		end

		table.insert(action.actors, player)
		player.itemapi_action = action

		mod.startActionAnimation(action)

		if actionDef.onActorStart then
			actionDef.onActorStart(action.target)
		end
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

	if actionDef.condition and not actionDef.condition(player, groundItem) then return end

	-- Ground item already in use but with a different action?
	local action = mod.findElementInArrayByFieldValue(mod.vars.actions, "target", groundItem)
	if action and not (action.index == actionIndex and action.spotIndex == spotIndex) then return end

	if player.itemapi_action then
		mod.stopAction(player)
	end

	-- Intentionally done again in case the player's action was stopped
	local action = mod.findElementInArrayByFieldValue(mod.vars.actions, "target", groundItem)

	-- Spawn a new action if one didn't exist for this ground item yet
	if not action then
		action = mod.spawnAction("ground_item")
		action.target = groundItem
		action.itemType = groundItemDef.index
		action.index = actionIndex
		action.spotIndex = spotIndex

		if actionDef.start then
			actionDef.start(action, action.target)
		end
	end

	table.insert(action.actors, player)
	player.itemapi_action = action

	mod.startActionAnimation(action)

	if actionDef.onActorStart then
		actionDef.onActorStart(action, action.target, player)
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
		local action = mod.findElementInArrayByFieldValue(mod.vars.actions, "target", mobj)

		-- Spawn a new action if one didn't exist for this ground item yet
		if not action then
			action = mod.spawnAction("mobj")
			action.target = mobj
		end

		table.insert(action.actors, player)
		player.itemapi_action = action

		mod.startActionAnimation(action)
	else
		actionDef.action(player, mobj)
	end
end

---@param player player_t
function mod.stopAction(player)
	local action = player.itemapi_action
	local actionDef = mod.getActionDef(action)

	if actionDef.onActorStop then
		actionDef.onActorStop(action, action.target, player)
	end

	mod.removeValueFromArray(action.actors, player)
	player.itemapi_action = nil

	if #action.actors == 0 then
		mod.despawnAction(action)
	end
end

---@param player player_t
---@return mobj_t?
function mod.findAimedMobj(player)
	local playerMobj = player.mo
	if not playerMobj then return end

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
