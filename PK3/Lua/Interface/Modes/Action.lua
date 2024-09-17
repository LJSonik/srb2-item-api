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

	local spotIndex
	local actionDef = mod.getActionDefFromMobj(mo, actionIndex)
	if actionDef.selectSpot then
		spotIndex = bs.readByte(stream)
	end

	mod.performGroundItemAction(p, actionIndex, mo, spotIndex)
end)

local netCommand_performMobjAction = nc.add(function(p, stream)
	local actionIndex = bs.readByte(stream)

	local mo = p.itemapi_mobjActionTarget
	if not (mo and mo.valid) then return end

	mod.performMobjAction(p, actionIndex, mo)
end)

local netCommand_storeCarriedItem = nc.add(function(p)
	local id = mod.getMainCarriedItemType(p)
	if not id then return end

	if p.itemapi_inventory:add(id) then
		mod.uncarryItem(p)
	end
end)

local netCommand_placeCarriedItem = nc.add(function(p)
	local slot = p.itemapi_carrySlots["right_hand"]
	if not slot then return end

	if mod.placeItem(p, slot.itemType) then
		mod.smartUncarryItem(p)
	end
end)

---@param p player_t
local netCommand_carryMobj = nc.add(function(p)
	local mo = p.itemapi_mobjActionTarget
	if not (mo and mo.valid) then return end

	local itemType = mod.getItemTypeFromMobj(mo)
	if itemType and mod.carryItem(p, itemType) then
		P_RemoveMobj(mo)
	end
end)


---@param mobj mobj_t
---@param actionIndex integer
---@return itemapi.GroundItemActionDef|itemapi.MobjActionDef|nil
function mod.getActionDefFromMobj(mobj, actionIndex)
	local itemDef = mod.getItemDefFromMobj(mobj)
	if itemDef then
		return itemDef.groundActions[actionIndex]
	else
		local actionDefs = mod.mobjActionDefs[mobj.type]
		return actionDefs and (actionDefs[mobj.state] or actionDefs[S_NULL])
	end
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
	elseif availableAction.type == "mobj" then
		netCommandID = netCommand_performMobjAction
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

---@param v videolib
---@param name string
---@param cmdID string
---@param x integer
---@param y integer
---@param rightAligned? boolean
local function drawActionKey(v, name, cmdID, x, y, rightAligned)
	local keyName = mod.getUICommandKeyName(cmdID):upper()
	local keyBlinkFreq = TICRATE/2
	local keyColor = (mod.client.time / keyBlinkFreq % 2 == 0) and "\x80" or "\x8f"

	v.drawString(
		x, y,
		keyColor .. keyName .. " \x84" .. name .. "\x80",
		V_ALLOWLOWERCASE | (rightAligned and V_SNAPTORIGHT or V_SNAPTOLEFT) | V_SNAPTOBOTTOM,
		rightAligned and "right" or "left"
	)
end


mod.addUIMode("action_selection", {
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

			action = function()
				if not checkSelectionValidity() then return end

				local sel = mod.client.actionSelection

				local availableAction = sel.availableActions[1]
				if not availableAction then return end

				if availableAction.type == "ground_item" then
					local actionDef = mod.getActionDefFromMobj(sel.mobj, availableAction.index)

					if actionDef.selectSpot then
						mod.client.uiMode.selectingSpot = true
						mod.setUIMode("spot_selection", 1)
					else
						mod.sendActionNetCommand(1)
					end
				else
					mod.sendActionNetCommand(1)
				end
			end
		},
		{
			id = "carry_or_store",
			name = "carry or store",
			defaultKey = "@forward",

			action = function()
				if not checkSelectionValidity() then return end

				if mod.getMainCarriedItemType(consoleplayer) then
					mod.sendNetCommand_storeCarriedItem()
				elseif mod.client.actionSelection.mobj then
					local def = mod.getItemDefFromMobj(mod.client.actionSelection.mobj)
					if def and def.carriable then
						mod.sendNetCommand_carryMobj()
					end
				end
			end
		},
		{
			id = "place",
			name = "place item on ground",
			defaultKey = "@backward",

			action = function()
				if not checkSelectionValidity() then return end

				if mod.getMainCarriedItemType(consoleplayer) then
					mod.sendNetCommand_placeCarriedItem()
				end
			end
		},
		{
			id = "cancel",

			action = function()
				mod.closeUI()
			end
		},
	},

	---@param v videolib
	draw = function(v)
		local sel = mod.client.actionSelection

		local y = 162
		for _, action in ipairs(sel.availableActions) do
			local actionDef = action.def
			drawActionKey(v, actionDef.name, "perform_action1", 16, y)
			y = y - 12
		end

		drawActionKey(v, "cancel", "cancel", 304, 162, true)

		if mod.getMainCarriedItemType(consoleplayer) then
			drawActionKey(v, "place", "place", 304, 150, true)
			drawActionKey(v, "store", "carry_or_store", 304, 138, true)
		elseif sel.mobj and sel.mobj.valid then
			local def = mod.getItemDefFromMobj(sel.mobj)
			if def and def.carriable then
				drawActionKey(v, "carry", "carry_or_store", 304, 150, true)
			end
		end
	end,
})
