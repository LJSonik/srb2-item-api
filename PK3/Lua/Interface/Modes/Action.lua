---@class itemapi
local mod = itemapi


local nc = ljrequire "ljnetcommand"
local bs = ljrequire "bytestream"


---@class itemapi.ActionSelection
---@field targetType "carried_item"|"mobj"
---@field mobj? mobj_t
---@field availableActions table[]


---@class player_t
---@field itemapi_mobjActionTarget mobj_t


---@class itemapi.Client
---@field actionSelection? itemapi.ActionSelection
---@field aimedMobj? mobj_t
mod.client.actionSelection = nil
mod.client.aimedMobj = nil


local netCommand_stopMobjActionSelection = nc.add(function(p)
	p.itemapi_mobjActionTarget = nil
end)

local netCommand_startMobjActionSelection = nc.add(function(p)
	p.itemapi_mobjActionTarget = mod.findAimedMobj(p)

	if p == consoleplayer
	and mod.client.uiModeType == "action_selection"
	and p.itemapi_mobjActionTarget ~= mod.client.actionSelection.mobj then
		mod.closeActionSelection()
	end
end)

local netCommand_performCarriedItemAction = nc.add(function(p, stream)
	local index = bs.readByte(stream)
	mod.performCarriedItemAction(p, index)
end)

local netCommand_performGroundItemAction = nc.add(function(p, stream)
	local actionIndex = bs.readByte(stream)

	local mo = p.itemapi_mobjActionTarget
	if not (mo and mo.valid) then return end

	local actionDef = mod.getActionDefFromMobj(mo, actionIndex)
	if not actionDef then return end

	local spotIndex
	if actionDef.selectSpot then
		spotIndex = bs.readByte(stream)
	end

	mod.performGroundItemAction(p, actionIndex, mo, spotIndex)
end)

local netCommand_performFOFAction = nc.add(function(p, stream)
	local actionIndex = bs.readByte(stream)

	local aimedFOF = mod.findAimedFOF(p)
	if not aimedFOF then return end

	mod.performFOFAction(p, actionIndex, aimedFOF)
end)

local netCommand_storeCarriedItem = nc.add(function(p)
	local slot = p.itemapi_carrySlots["right_hand"]
	if not slot then return end

	local itemDef = mod.itemDefs[slot.itemType]
	if not itemDef.storable then return end

	if p.itemapi_inventory:add(slot.itemType, 1, slot.itemData) then
		mod.uncarryItem(p)
	end
end)

local netCommand_placeCarriedItem = nc.add(function(p)
	local slot = p.itemapi_carrySlots["right_hand"]
	if not slot then return end

	if mod.placeItem(p, slot.itemType, slot.itemData) then
		mod.smartUncarryItem(p)
	end
end)

---@param p player_t
local netCommand_carryMobj = nc.add(function(p)
	local mo = p.itemapi_mobjActionTarget
	if not (mo and mo.valid) then return end

	local def = mod.getItemDefFromMobj(mo)
	if not def then return end

	if not def.carriable
	or def.getCarriable and not def.getCarriable(mo) then
		return
	end

	if def.index and mod.carryItem(p, def.index) then
		local slot = p.itemapi_carrySlots["right_hand"]
		slot.itemData = mo.itemapi_data
		P_RemoveMobj(mo)
	end
end)


---@param mobj mobj_t
---@param actionIndex integer
---@return itemapi.GroundItemActionDef?
function mod.getActionDefFromMobj(mobj, actionIndex)
	local itemDef = mod.getItemDefFromMobj(mobj)
	if not itemDef then return nil end

	local actionType = itemDef.groundActions[actionIndex]
	return actionType and mod.actionDefs[actionType]
end

---@return boolean
local function checkSelectionValidity()
	local mobj = mod.client.actionSelection.mobj
	if mobj and not mobj.valid then
		mod.closeUI()
		return false
	end

	return true
end

function mod.openActionSelection()
	local cl = mod.client

	if cl.uiActive then return end

	if cl.aimedMobj and not cl.aimedMobj.valid then
		cl.aimedMobj = nil
	end

	local availableActions = mod.findAvailableActions(consoleplayer, mod.client.aimedMobj)
	if #availableActions == 0 and not (mod.getMainCarriedItemType(consoleplayer) or mod.client.aimedMobj) then
		return
	end

	local groundItemUsable = false
	for _, action in ipairs(availableActions) do
		if action.type == "ground_item" and action.def.requiredCarriedItem then
			groundItemUsable = true
		end
	end

	if groundItemUsable then
		availableActions = mod.filter(availableActions, function(action)
			return (action.type == "ground_item" and action.def.requiredCarriedItem)
		end)
	end

	mod.setUIMode("action_selection", availableActions, mod.client.aimedMobj)
end

function mod.closeActionSelection()
	mod.closeActionSelectionData()
	mod.closeUI()
end

function mod.closeActionSelectionData()
	local cl = mod.client

	if not cl.actionSelection then return end

	-- !!!!
	if cl.actionSelection.targetType == "mobj" then
		mod.sendNetCommand(consoleplayer, nc.prepare(netCommand_stopMobjActionSelection))
	end

	cl.actionSelection = nil
end

---@param availableActionIndex integer
---@param spotIndex? boolean
function mod.sendActionNetCommand(availableActionIndex, spotIndex)
	local availableAction = mod.client.actionSelection.availableActions[availableActionIndex]
	if not availableAction then return end

	local netCommandID
	if availableAction.type == "carried_item" then
		netCommandID = netCommand_performCarriedItemAction
	elseif availableAction.type == "ground_item" then
		netCommandID = netCommand_performGroundItemAction
	elseif availableAction.type == "fof" then
		netCommandID = netCommand_performFOFAction
	end

	local stream = nc.prepare(netCommandID)
	bs.writeByte(stream, availableAction.index)
	if spotIndex ~= nil then
		bs.writeByte(stream, spotIndex)
	end
	mod.sendNetCommand(consoleplayer, stream)

	mod.closeActionSelection()
end

function mod.sendNetCommand_storeCarriedItem()
	mod.sendNetCommand(consoleplayer, nc.prepare(netCommand_storeCarriedItem))
	mod.closeActionSelection()
end

function mod.sendNetCommand_placeCarriedItem()
	mod.sendNetCommand(consoleplayer, nc.prepare(netCommand_placeCarriedItem))
	mod.closeActionSelection()
end

function mod.sendNetCommand_carryMobj()
	mod.sendNetCommand(consoleplayer, nc.prepare(netCommand_carryMobj))
	mod.closeActionSelection()
end

---@param availableActionIndex integer
---@return boolean
local function checkActionCondition(availableActionIndex)
	local sel = mod.client.actionSelection

	local availableAction = sel.availableActions[availableActionIndex]
	if not availableAction then return false end

	if availableAction.type == "ground_item" then
		local actionDef = mod.getActionDefFromMobj(sel.mobj, availableAction.index)
		if actionDef.condition then
			return actionDef.condition(consoleplayer, sel.mobj)
		end
	end

	return true
end

---@param availableActionIndex integer
local function performAction(availableActionIndex)
	if not checkSelectionValidity() then return end

	local sel = mod.client.actionSelection

	local availableAction = sel.availableActions[availableActionIndex]
	if not availableAction then return end

	if availableAction.type == "ground_item" then
		local actionDef = mod.getActionDefFromMobj(sel.mobj, availableAction.index)

		if actionDef.selectSpot then
			mod.client.uiMode.selectingSpot = true
			mod.setUIMode("spot_selection", availableActionIndex)
		else
			mod.sendActionNetCommand(availableActionIndex)
		end
	else
		mod.sendActionNetCommand(availableActionIndex)
	end
end


mod.addUIMode("action_selection", {
	showCommands = true,

	enter = function(availableActions, mobj)
		local cl = mod.client

		cl.actionSelection = {
			availableActions = availableActions,
			mobj = mobj
		}

		if mobj then
			mod.sendNetCommand(consoleplayer, nc.prepare(netCommand_startMobjActionSelection))
		end
	end,

	update = function()
		if not checkSelectionValidity() then return end
	end,

	leave = function()
		if not mod.client.uiMode.selectingSpot then
			mod.closeActionSelectionData()
		end
	end,

	commands = {
		{
			id = "perform_action1",
			name = "perform action 1",
			defaultKey = "@custom1",

			getName = function()
				return mod.client.actionSelection.availableActions[1].def.name
			end,
			condition = function()
				return checkActionCondition(1)
			end,
			action = function()
				performAction(1)
			end
		},
		{
			id = "perform_action2",
			name = "perform action 2",
			defaultKey = "@custom2",

			getName = function()
				return mod.client.actionSelection.availableActions[2].def.name
			end,
			condition = function()
				return checkActionCondition(2)
			end,
			action = function()
				performAction(2)
			end
		},
		{
			id = "perform_action3",
			name = "perform action 3",
			defaultKey = "@custom3",

			getName = function()
				return mod.client.actionSelection.availableActions[3].def.name
			end,
			condition = function()
				return checkActionCondition(3)
			end,
			action = function()
				performAction(3)
			end
		},
		{
			id = "carry_or_store",
			name = "carry/store",
			defaultKey = "@forward",
			showOnRight = true,

			getName = function()
				return mod.getMainCarriedItemType(consoleplayer) and "store" or "carry"
			end,

			condition = function()
				local itemType = mod.getMainCarriedItemType(consoleplayer)

				if itemType then
					local def = mod.itemDefs[itemType]
					return (def and def.storable ~= false)
				else
					local sel = mod.client.actionSelection
					if not (sel.mobj and sel.mobj.valid) then return false end
					local def = mod.getItemDefFromMobj(sel.mobj)
					return (def and def.carriable ~= false and not (def.getCarriable and not def.getCarriable(sel.mobj)))
				end
			end,

			action = function()
				if not checkSelectionValidity() then return end

				local itemType = mod.getMainCarriedItemType(consoleplayer)

				if itemType then
					local def = mod.itemDefs[itemType]
					if def.storable then
						mod.sendNetCommand_storeCarriedItem()
					end
				elseif mod.client.actionSelection.mobj then
					local mo = mod.client.actionSelection.mobj
					local def = mod.getItemDefFromMobj(mo)
					if def and def.carriable and not (def.getCarriable and not def.getCarriable(mo)) then
						mod.sendNetCommand_carryMobj()
					end
				end
			end
		},
		{
			id = "place",
			name = "place",
			defaultKey = "@backward",
			showOnRight = true,

			condition = function()
				local itemType = mod.getMainCarriedItemType(consoleplayer)
				if itemType then
					local def = mod.itemDefs[itemType]
					return (def and def.placeable ~= false)
				else
					return false
				end
			end,

			action = function()
				if not checkSelectionValidity() then return end

				if mod.getMainCarriedItemType(consoleplayer) then
					mod.sendNetCommand_placeCarriedItem()
				end
			end
		},
		{
			id = "cancel",
			showOnRight = true,

			action = function()
				mod.closeUI()
			end
		},
	},
})
