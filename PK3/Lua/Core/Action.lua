---@class itemapi
local mod = itemapi


local ljclass = ljrequire "ljclass"


---@class itemapi.ItemActionDef : itemapi.ActionDef
---@field item string
---@field requiredGroundItem? string
---@field condition? fun(): boolean
---
---@field action fun(player: player_t)
---@field actionV2 fun(action: itemapi.Action, actor: player_t)
---
---@field start fun(action: itemapi.Action, actor: player_t)
---@field tick fun(action: itemapi.Action, actor: player_t)
---@field stop fun(action: itemapi.Action, actor: player_t)
---
---@field onActorStart fun(player: player_t)
---@field onActorStop fun(player: player_t)


---@class itemapi.GroundItemActionDef : itemapi.ActionDef
---@field item string
---@field requiredCarriedItem? string
---@field condition? fun(player: player_t, mobj: mobj_t): boolean
---@field selectSpot? boolean
---
---@field action fun(player: player_t, mobj: mobj_t, groundItemDef: itemapi.ItemDef, carriedItemDef: itemapi.ItemDef?, spotIndex: integer?)
---@field actionV2 fun(action: itemapi.Action, mobj: mobj_t, actors: player_t[])
---
---@field start fun(action: itemapi.Action, mobj: mobj_t)
---@field tick fun(action: itemapi.Action, mobj: mobj_t, actors: player_t[])
---@field stop fun(action: itemapi.Action, mobj: mobj_t)
---
---@field onActorStart fun(action: itemapi.Action, mobj: mobj_t, actor: player_t)
---@field onActorStop fun(action: itemapi.Action, mobj: mobj_t, actor: player_t)


---@class itemapi.FOFActionDef : itemapi.ActionDef
---@field item string
---@field requiredCarriedItem? string
---@field condition? fun(player: player_t, aimedFOF: itemapi.AimedFOF): boolean
---@field action fun(action: itemapi.Action, aimedFOF: itemapi.AimedFOF, actors: player_t[])
---
---@field start fun(action: itemapi.Action, aimedFOF: itemapi.AimedFOF)
---@field tick fun(action: itemapi.Action, aimedFOF: itemapi.AimedFOF, actors: player_t[])
---@field stop fun(action: itemapi.Action, aimedFOF: itemapi.AimedFOF)
---
---@field onActorStart fun(action: itemapi.Action, aimedFOF: itemapi.AimedFOF, actor: player_t)
---@field onActorStop fun(action: itemapi.Action, aimedFOF: itemapi.AimedFOF, actor: player_t)


---@alias itemapi.ActionType "carried_item"|"ground_item"|"fof"


---@class itemapi.AimedFOF
---@field fof ffloor_t
---@field x fixed_t
---@field y fixed_t
---@field z fixed_t


---@class player_t
---@field itemapi_action? itemapi.Action


local MAX_ACTION_DIST = 128*FU
local MAX_ACTION_HEIGHT = 96*FU


---@type { [string|integer]: itemapi.ActionDef }
mod.actionDefs = {}

---@type { [string]: integer[] }
mod.fofActionDefs = {}

---@class itemapi.Vars
---@field actions itemapi.Action[]
mod.vars.actions = {}


---@class itemapi.ActionDef : ljclass.Class
---@field index integer
---@field name string
---@field type "carried_item"|"ground_item"|"fof"
---
---@field duration? tic_t
---@field variableDuration? boolean
---
---@field animations  itemapi.ActionAnimationDef[]
---@field animation?  itemapi.ActionAnimationDef
---@field animation1? itemapi.ActionAnimationDef
---@field animation2? itemapi.ActionAnimationDef
---@field animation3? itemapi.ActionAnimationDef
local ActionDef = ljclass.localclass()
mod.ActionDef = ActionDef


---@class itemapi.Action : ljclass.Class
---@field type integer
---@field arrayIndex integer
---@field despawning? boolean
---@field def itemapi.ActionDef
---@field carriedItemDef? itemapi.ItemDef
---@field groundItemDef? itemapi.ItemDef
---@field actors player_t[]
---@field target? any
---@field itemType? integer
---@field materialID? string
---@field index integer
---@field slotIndex? integer
---@field carriedItemSlotIndex? integer
---@field spotIndex? integer
---@field progress tic_t
---@field completed? boolean
local Action = ljclass.class()
mod.Action = Action


---@param self itemapi.Action
ljclass.getter(Action, "def", function(self)
	return mod.actionDefs[self.type]
end)

---@param self itemapi.Action
ljclass.getter(Action, "carriedItemDef", function(self)
	local p = self.actors[1]
	local slot = p.itemapi_carrySlots[self.carriedItemSlotIndex]
	return mod.itemDefs[slot.itemType]
end)

---@param self itemapi.Action
ljclass.getter(Action, "groundItemDef", function(self)
	return mod.getItemDefFromMobj(self.target)
end)


---@param p player_t
---@param requiredItem
---@return integer?
local function findRequiredCarriedItemSlotIndex(p, requiredItem)
	if not requiredItem then return nil end

	for _, id in ipairs(itemapi.dualWieldableCarrySlots) do
		local slot = p.itemapi_carrySlots[id]

		if slot and mod.doesItemMatchSelector(slot.itemType, requiredItem) then
			return mod.carrySlotDefs[id].index
		end
	end

	return nil
end

---Registers a new action
---@param def itemapi.ActionDef
function mod.addAction(def)
	def = mod.copy(def, ActionDef())

	def.index = #mod.actionDefs + 1
	mod.actionDefs[def.index] = def

	mod.parseSugarArray(def, "animations", "animation")
	def.animations = $ or {}

	for i, anim in ipairs(def.animations) do
		if type(anim) == "string" then
			def.animations[i] = { type = anim }
		end
	end
end

---Registers a new item action
---@param itemID itemapi.ItemType
---@param def itemapi.ItemActionDef
function mod.addItemAction(itemID, def)
	local itemDef = mod.itemDefs[itemID]
	def.type = "carried_item"
	def.item = itemID
	mod.addAction(def)
	table.insert(itemDef.actions, #mod.actionDefs)
end

---Registers a new ground item action
---@param itemID itemapi.ItemType
---@param def itemapi.GroundItemActionDef
function mod.addGroundItemAction(itemID, def)
	local itemDef = mod.itemDefs[itemID]
	def.type = "ground_item"
	def.item = itemID
	mod.addAction(def)
	table.insert(itemDef.groundActions, #mod.actionDefs)
end

---Registers a new FOF action
---@param materialID string
---@param def itemapi.FOFActionDef
function mod.addFOFAction(materialID, def)
	def.type = "fof"
	def.material = materialID
	mod.addAction(def)

	mod.fofActionDefs[materialID] = $ or {}
	table.insert(mod.fofActionDefs[materialID], #mod.actionDefs)
end

---@param id integer
---@return itemapi.Action
function mod.spawnAction(id)
	local index = #mod.vars.actions + 1

	local action = Action()
	action.type = id
	action.arrayIndex = index
	action.actors = {}
	action.progress = 0

	mod.vars.actions[index] = action

	return action
end

function mod.updateActions()
	local actions = mod.vars.actions

	for i = #actions, 1, -1 do
		local action = actions[i]
		local actionDef = action.def

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
			if actionDef.type == "carried_item" then
				actionDef.tick(action, action.target)
			elseif actionDef.type == "ground_item" then
				actionDef.tick(action, action.target, action.actors)
			elseif actionDef.type == "fof" then
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

	local actionDef = action.def
	if actionDef.stop then
		if actionDef.type == "carried_item" then
			actionDef.stop(action, action.target)
		elseif actionDef.type == "ground_item" then
			actionDef.stop(action, action.target)
		elseif actionDef.type == "fof" then
			actionDef.stop(action, action.target)
		end
	end

	mod.stopActionAnimation(action)
	mod.removeIndexFromUnorderedArrayAndUpdateField(mod.vars.actions, action.arrayIndex, "arrayIndex")
end

---@param action itemapi.Action
function mod.completeAction(action)
	local actionDef = action.def
	local actor = mod.randomElement(action.actors)

	action.completed = true

	if not actionDef.stop then
		if actionDef.type == "carried_item" then
			if actionDef.actionV2 then
				actionDef.actionV2(action, action.target)
			elseif actionDef.action then
				actionDef.action(actor, action.groundItem)
			end
		elseif actionDef.type == "ground_item" then
			local groundItemDef = mod.getItemDefFromMobj(action.target)

			if actionDef.actionV2 then
				actionDef.actionV2(action, action.target, action.actors)
			elseif actionDef.action then
				local carriedItemSlotIndex = findRequiredCarriedItemSlotIndex(actor, actionDef.requiredCarriedItem)
				local slot = carriedItemSlotIndex and actor.itemapi_carrySlots[carriedItemSlotIndex]
				local carriedItemDef = slot and mod.itemDefs[slot.itemType]

				actionDef.action(actor, action.target, groundItemDef, carriedItemDef, action.spotIndex)
			end
		elseif actionDef.type == "fof" then
			actionDef.action(action, action.target, action.actors)
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

	local groundItemID = mobj and mod.getItemIDFromMobj(mobj)

	for _, slotID in ipairs(itemapi.dualWieldableCarrySlots) do
		local slot = player.itemapi_carrySlots[slotID]
		if not slot then continue end

		local itemDef = mod.itemDefs[slot.itemType]

		for i, actionType in ipairs(itemDef.actions) do
			local actionDef = mod.actionDefs[actionType]

			if actionDef.requiredGroundItem and not mod.doesItemMatchSelector(groundItemID, actionDef.requiredGroundItem) then
				continue
			end

			table.insert(availableActions, {
				type = "carried_item",
				slotIndex = mod.carrySlotDefs[slotID].index,
				index = i,
				def = actionDef
			})
		end
	end

	if mobj then
		if groundItemID then
			local groundItemDef = mod.itemDefs[groundItemID]

			for i, actionType in ipairs(groundItemDef.groundActions) do
				local actionDef = mod.actionDefs[actionType]

				if actionDef.requiredCarriedItem and not findRequiredCarriedItemSlotIndex(player, actionDef.requiredCarriedItem) then
					continue
				end

				if actionDef.condition and not actionDef.condition(player, mobj) then continue end

				table.insert(availableActions, {
					type = "ground_item",
					index = i,
					def = actionDef
				})
			end
		end
	end

	local aimedFOF = mod.findAimedFOF(player)
	if aimedFOF then
		local materialID = mod.textureToSurfaceMaterial[aimedFOF.fof.toppic]
		local actionTypes = mod.fofActionDefs[materialID]

		if actionTypes then
			for i, actionType in ipairs(actionTypes) do
				local actionDef = mod.actionDefs[actionType]

				table.insert(availableActions, {
					type = "fof",
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
	local groundItemID = mobj and mod.getItemIDFromMobj(mobj)

	for _, slotID in ipairs(itemapi.dualWieldableCarrySlots) do
		local slot = player.itemapi_carrySlots[slotID]
		if not slot then continue end

		local itemDef = mod.itemDefs[slot.itemType]

		for _, actionType in ipairs(itemDef.actions) do
			local actionDef = mod.actionDefs[actionType]

			if not actionDef.requiredGroundItem or mod.doesItemMatchSelector(groundItemID, actionDef.requiredGroundItem) then
				return true
			end
		end
	end

	if groundItemID then
		local groundItemDef = mod.itemDefs[groundItemID]

		if mod.findFirstEmptyDualWieldableCarrySlot(player) then return true end

		for _, actionType in ipairs(groundItemDef.groundActions) do
			local actionDef = mod.actionDefs[actionType]

			if not actionDef.requiredCarriedItem
			or findRequiredCarriedItemSlotIndex(player, actionDef.requiredCarriedItem) then
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
	local actionDef = action.def

	local pmo = player.mo
	if not pmo then return false end

	if actionDef.type == "carried_item" then
		---@cast actionDef itemapi.ItemActionDef

		if not player.itemapi_carrySlots[action.slotIndex] then return false end

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
	elseif actionDef.type == "ground_item" then
		---@cast actionDef itemapi.GroundItemActionDef

		local mobj = action.target
		if not mobj.valid then return false end

		local dist = R_PointToDist2(pmo.x, pmo.y, mobj.x, mobj.y)
		if dist > MAX_ACTION_DIST then return false end

		if actionDef.requiredCarriedItem then
			local slot = player.itemapi_carrySlots[action.carriedItemSlotIndex]
			local carriedItemDef = slot and mod.itemDefs[slot.itemType]
			local carriedItemID = carriedItemDef and carriedItemDef.id

			if not mod.doesItemMatchSelector(carriedItemID, actionDef.requiredCarriedItem) then
				return false
			end
		end
	elseif actionDef.type == "fof" then
		---@cast actionDef itemapi.FOFActionDef

		local aimedFOF = action.target
		if not aimedFOF.fof.valid then return false end

		local dist = R_PointToDist2(pmo.x, pmo.y, aimedFOF.x, aimedFOF.y)
		if dist > MAX_ACTION_DIST then return false end

		if actionDef.requiredCarriedItem then
			local slot = player.itemapi_carrySlots[action.carriedItemSlotIndex]
			local carriedItemDef = slot and mod.itemDefs[slot.itemType]
			local carriedItemID = carriedItemDef and carriedItemDef.id

			if not mod.doesItemMatchSelector(carriedItemID, actionDef.requiredCarriedItem) then
				return false
			end
		end
	end

	return true
end

---@param player player_t
---@param slotIndex integer
---@param actionIndex integer
---@param groundItem? mobj_t
function mod.performCarriedItemAction(player, slotIndex, actionIndex, groundItem)
	local slot = player.itemapi_carrySlots[slotIndex]
	if not slot then return end

	local itemDef = mod.itemDefs[slot.itemType]
	local actionType = itemDef.actions[actionIndex]
	if not actionType then return end
	local actionDef = mod.actionDefs[actionType]

	local groundItemID = mobj and mod.getItemIDFromMobj(mobj)
	local requiredID = actionDef.requiredGroundItem
	if requiredID and not mod.doesItemMatchSelector(groundItemID, requiredID) then return end

	if player.itemapi_action then
		mod.stopAction(player)
	end

	local action = mod.spawnAction(actionType)
	action.target = player
	action.itemType = slot.itemType
	action.index = actionIndex
	action.slotIndex = slotIndex
	action.groundItem = groundItem

	if actionDef.start then
		actionDef.start(action, action.target)
	end

	table.insert(action.actors, player)
	player.itemapi_action = action

	mod.startActionAnimation(action)

	if actionDef.onActorStart then
		actionDef.onActorStart(action.target)
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

	local actionType = groundItemDef.groundActions[actionIndex]
	if not actionType then return end
	local actionDef = mod.actionDefs[actionType]

	local carriedItemSlotIndex = actionDef.requiredCarriedItem and findRequiredCarriedItemSlotIndex(player, actionDef.requiredCarriedItem)
	if actionDef.requiredCarriedItem and not carriedItemSlotIndex then return end

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
		action = mod.spawnAction(actionType)
		action.target = groundItem
		action.itemType = groundItemDef.index
		action.index = actionIndex
		action.spotIndex = spotIndex
		action.carriedItemSlotIndex = carriedItemSlotIndex

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
---@param actionIndex integer
---@param aimedFOF itemapi.AimedFOF
function mod.performFOFAction(player, actionIndex, aimedFOF)
	if not aimedFOF then return end

	local materialID = mod.textureToSurfaceMaterial[aimedFOF.fof.toppic]
	if not (materialID and mod.fofActionDefs[materialID]) then return end

	local actionType = mod.fofActionDefs[materialID][actionIndex]
	if not actionType then return end
	local actionDef = mod.actionDefs[actionType] ---@type itemapi.FOFActionDef

	local carriedItemSlotIndex = actionDef.requiredCarriedItem and findRequiredCarriedItemSlotIndex(player, actionDef.requiredCarriedItem)
	if actionDef.requiredCarriedItem and not carriedItemSlotIndex then return end

	if actionDef.condition and not actionDef.condition(player, aimedFOF) then return end

	if player.itemapi_action then
		mod.stopAction(player)
	end

	local action = mod.spawnAction(actionType)
	action.target = aimedFOF
	action.materialID = materialID
	action.index = actionIndex
	action.carriedItemSlotIndex = carriedItemSlotIndex

	if actionDef.start then
		actionDef.start(action, aimedFOF)
	end

	table.insert(action.actors, player)
	player.itemapi_action = action

	mod.startActionAnimation(action)

	if actionDef.onActorStart then
		actionDef.onActorStart(action, action.target, player)
	end
end

---@param player player_t
function mod.stopAction(player)
	local action = player.itemapi_action
	local actionDef = action.def

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
	if not playerMobj then return nil end

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

		if not (mz > z1 and mz < z2) then return nil end

		local dist = R_PointToDist2(x, y, mx, my)
		if not (dist < maxDist and mo ~= playerMobj) then return nil end

		local angle = abs(playerAngle - R_PointToAngle2(x, y, mx, my))
		if angle >= maxAngle then return nil end

		local mt = mo.type
		local state = mo.state
		local stateToItemType = mod.mobjToItemType[mt]
		if not (stateToItemType and (stateToItemType[state] or stateToItemType[S_NULL])) then return nil end

		if not mod.canPlayerPerformActionsOnMobj(player, mo) then return nil end

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

---@param player player_t
---@return itemapi.AimedFOF?
function mod.findAimedFOF(player)
	local playerMobj = player.mo
	if not playerMobj then return nil end

	local maxDist = MAX_ACTION_DIST
	local maxHeight = MAX_ACTION_HEIGHT

	local x = playerMobj.x
	local y = playerMobj.y
	local z = playerMobj.z + playerMobj.height * 2 / 3
	local minZ, maxZ = z - maxHeight, z + maxHeight

	local stepDist = 16*FU
	local dx = FixedMul(cos(playerMobj.angle), stepDist)
	local dy = FixedMul(sin(playerMobj.angle), stepDist)

	for _ = 0, maxDist, stepDist do
		local s = R_PointInSubsector(x, y).sector

		for fof in s.ffloors() do
			local fofTop = P_GetZAt(fof.t_slope, x, y, fof.topheight)
			local fofBottom = P_GetZAt(fof.b_slope, x, y, fof.bottomheight)

			if minZ <= fofTop and maxZ >= fofBottom
			and fofTop >= P_GetZAt(s.f_slope, x, y, s.floorheight) -- FOF above the ground?
			and fof.flags & FF_SWIMMABLE then
				z = min(max(z, fofBottom), fofTop)
				return { fof=fof, x=x, y=y, z=z }
			end
		end

		x = x + dx
		y = y + dy
	end

	return nil
end
