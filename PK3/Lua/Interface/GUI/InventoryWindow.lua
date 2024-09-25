---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"
local nc = ljrequire "ljnetcommand"
local bs = ljrequire "bytestream"


local SLOT_SIZE = 16*FU
local CLICK_DURATION = TICRATE*3/8


---@class itemapi.Client
---@field draggedInventoryItem? table
mod.client.draggedInventoryItem = nil


local windowStyle = {
	bdSize = FU,
	bdColor = 25,

	titleBarSize = 8*FU,
	titleBarColor = 28,

	bgColor = 27,
}


local netCommand_carryInventoryItem = nc.add(function(p, stream)
	local slotIndex = bs.readByte(stream)

	if not p.itemapi_inventory or mod.getMainCarriedItemType(p) then return end

	local itemType = p.itemapi_inventory:removeFromSlot(slotIndex)
	if itemType then
		mod.carryItem(p, itemType)
		p.itemapi_carrySlots["right_hand"].multiple = true
	end
end)

local netCommand_moveInventoryItemBetweenPlayerAndContainer = nc.add(function(p, stream)
	local srcIsContainer = (bs.readBit(stream) == 1)
	local srcIndex = bs.readByte(stream)
	local dstIsContainer = (bs.readBit(stream) == 1)
	local dstIndex = bs.readByte(stream)

	local mo = p.itemapi_mobjActionTarget
	if not (mo and mo.valid) then return end

	---@type itemapi.Inventory
	local srcInventory = srcIsContainer and mo.inventory or p.itemapi_inventory
	local srcType, srcQuantity = srcInventory:get(srcIndex)

	---@type itemapi.Inventory
	local dstInventory = dstIsContainer and mo.inventory or p.itemapi_inventory
	local dstType, dstQuantity = dstInventory:get(dstIndex)

	srcInventory:setSlot(srcIndex, dstType, dstQuantity)
	dstInventory:setSlot(dstIndex, srcType, srcQuantity)
end)


function mod.sendNetCommand_moveInventoryItemBetweenPlayerAndContainer(srcIsContainer, srcSlotIndex, dstIsContainer, dstSlotIndex)
	local stream = nc.prepare(netCommand_moveInventoryItemBetweenPlayerAndContainer)
	bs.writeBit(stream, srcIsContainer and 1 or 0)
	bs.writeByte(stream, srcSlotIndex)
	bs.writeBit(stream, dstIsContainer and 1 or 0)
	bs.writeByte(stream, dstSlotIndex)
	mod.sendNetCommand(consoleplayer, stream)
end


---@class itemapi.InventoryWindow : ljgui.Window
local Inventory, base = gui.class(gui.Window)
mod.InventoryWindow = Inventory


function Inventory:updateKeyboardTooltip()
	local slotIndex = (self.selectedSlotY - 1) * self.inventory.numColumns + self.selectedSlotX
	local itemType = self.inventory:get(slotIndex)
	if not itemType then
		mod.client.tooltip = nil
		return
	end

	local slot = self.mainArea.children:get(slotIndex)

	mod.client.tooltip = {
		type = "anywhere",
		text = mod.itemDefs[itemType].name,

		x = slot.cachedLeft + slot.width / 2,
		y = slot.cachedTop + slot.height + FU,
		anchorX = "center"
	}
end

---@param key keyevent_t
---@return boolean
function Inventory:onKeyPress(key)
	local keyName = key.name

	if mod.handleMenuStandardKeyPress(key) then
		return true
	elseif keyName == "escape"
	or mod.isKeyBoundToUICommand(keyName, "cancel") then
		mod.closeUI()
		return true
	elseif not key.repeated and keyName == "enter"
	or mod.isKeyBoundToUICommand(keyName, "confirm")
	or mod.isKeyBoundToUICommand(keyName, "open_action_selection") then
		local slotIndex = (self.selectedSlotY - 1) * self.inventory.numColumns + self.selectedSlotX

		local stream = nc.prepare(netCommand_carryInventoryItem)
		bs.writeByte(stream, slotIndex)
		mod.sendNetCommand(consoleplayer, stream)

		mod.closeUI()
		return true
	elseif not key.repeated and keyName == "tab"
	or mod.isKeyBoundToGameControl(keyName, GC_CUSTOM3) then
			local root = gui.root
		local otherWindow = self.isContainer and root.inventoryWindow or root.containerInventoryWindow

		if otherWindow then
			otherWindow:focus()
		end

		return true
	elseif keyName == "left arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_STRAFELEFT) then
		if self.selectedSlotX > 1 then
			self.selectedSlotX = $ - 1
		else
			self.selectedSlotX = self.inventory.numColumns
		end

		self:updateKeyboardTooltip()

		return true
	elseif keyName == "right arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_STRAFERIGHT) then
		if self.selectedSlotX < self.inventory.numColumns then
			self.selectedSlotX = $ + 1
		else
			self.selectedSlotX = 1
		end

		self:updateKeyboardTooltip()

		return true
	elseif keyName == "up arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_FORWARD) then
		if self.selectedSlotY > 1 then
			self.selectedSlotY = $ - 1
		else
			self.selectedSlotY = self.numRows
		end

		self:updateKeyboardTooltip()

		return true
	elseif keyName == "down arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_BACKWARD) then
		if self.selectedSlotY < self.numRows then
			self.selectedSlotY = $ + 1
		else
			self.selectedSlotY = 1
		end

		self:updateKeyboardTooltip()

		return true
	end

	return false
end

---@param inventory itemapi.Inventory
---@return integer?
local function findFreeInventorySlot(inventory)
	for slotIndex = 1, inventory.numSlots do
		if not inventory:isSlotUsed(slotIndex) then
			return slotIndex
		end
	end

	return nil
end

---@param slot ljgui.Item
---@return boolean
function Inventory.slot_onLeftMousePress(slot)
	local window = slot.parent.parent
	local draggedItem = mod.client.draggedInventoryItem

	if slot.pressTime ~= nil then
		slot.pressTime = nil
		slot:removeEvent("Tick", Inventory.slot_onTick)
	end

	if draggedItem then
		mod.sendNetCommand_moveInventoryItemBetweenPlayerAndContainer(
			draggedItem.window.isContainer, draggedItem.slotIndex,
			window.isContainer, slot.slotIndex
		)

		if window.inventory:isSlotUsed(slot.slotIndex)
		and (window ~= draggedItem.window or slot.slotIndex ~= draggedItem.slotIndex) then
			mod.client.draggedInventoryItem = {
				window = draggedItem.window,
				slotIndex = draggedItem.slotIndex
			}
		else
			mod.client.draggedInventoryItem = nil
		end
	elseif mod.client.shiftHeld and window.inventory:isSlotUsed(slot.slotIndex) then
		local root = gui.root
		local dstWindow = window.isContainer and root.inventoryWindow or root.containerInventoryWindow

		if dstWindow then
			local dstSlotIndex = findFreeInventorySlot(dstWindow.inventory)

			if dstSlotIndex then
				mod.sendNetCommand_moveInventoryItemBetweenPlayerAndContainer(
					window.isContainer, slot.slotIndex,
					not window.isContainer, dstSlotIndex
				)
			end
		end
	else
		slot.pressTime = mod.client.time
		slot:addEvent("Tick", Inventory.slot_onTick)
	end

	return true
end

---@param slot ljgui.Item
---@param mouse ljgui.Mouse
---@return boolean
function Inventory.slot_onMouseMove(slot, mouse)
	local window = slot.parent.parent
	local numColumns = window.inventory.numColumns

	window.selectedSlotX = (slot.slotIndex - 1) % numColumns + 1
	window.selectedSlotY =  (slot.slotIndex - 1) / numColumns + 1
	window:focus()

	local itemType = window.inventory:get(slot.slotIndex)
	if itemType then
		mod.client.tooltip = {
			type = "mouse",
			text = mod.itemDefs[itemType].name
		}
	end

	if slot.pressTime ~= nil then
		mod.client.draggedInventoryItem = {
			window = window,
			slotIndex = slot.slotIndex
		}

		slot.pressTime = nil
		slot:removeEvent("Tick", Inventory.slot_onTick)
	end

	return true
end

---@param slot ljgui.Item
---@param mouse ljgui.Mouse
function Inventory.slot_onMouseLeave(slot, mouse)
	mod.client.tooltip = nil
end

---@param slot ljgui.Item
function Inventory.slot_onTick(slot)
	if mod.client.time - slot.pressTime < CLICK_DURATION then return end

	local window = slot.parent.parent

	slot.pressTime = nil
	slot:removeEvent("Tick", Inventory.slot_onTick)

	if not mod.client.draggedInventoryItem
	and window.inventory:isSlotUsed(slot.slotIndex) then
		local stream = nc.prepare(netCommand_carryInventoryItem)
		bs.writeByte(stream, slot.slotIndex)
		mod.sendNetCommand(consoleplayer, stream)

		mod.closeUI()
	end
end

---@param v videolib
---@param def itemapi.ItemDef
local function cacheItemPatch(v, def)
	local frameName = R_Frame2Char(def.mobjFrame)
	local basePatch = sprnames[def.mobjSprite]

	local patchName = basePatch .. frameName .. "0"
	if not v.patchExists(patchName) then
		patchName = basePatch .. frameName .. "1"
	end
	if not v.patchExists(patchName) then
		patchName = basePatch .. frameName .. "1" .. frameName .. "5"
	end

	return v.cachePatch(patchName)
end

---@param def itemapi.ItemDef
---@param patch patch_t
local function calculateDefaultIconScale(def, patch)
	local scale = (def.mobjScale or FU) / 2
	local maxScale = SLOT_SIZE / max(patch.width, patch.height)
	return min(scale, maxScale)
end

---@param item ljgui.Item
---@param v videolib
local function drawSlot(item, v)
	local window = item.parent.parent
	local selectedIndex = (window.selectedSlotY - 1) * window.inventory.numColumns + window.selectedSlotX
	local selected = (window.focused and selectedIndex == item.slotIndex)
	local l, t = item.cachedLeft, item.cachedTop
	local w, h = item.width, item.height

	local bgColor = selected and 22 or 26
	gui.drawFill(v, l, t, w, h, bgColor)

	local draggedItem = mod.client.draggedInventoryItem
	if draggedItem and draggedItem.window == window and draggedItem.slotIndex == item.slotIndex then
		return
	end

	local type, quantity = window.inventory:get(item.slotIndex)
	if not type then return end

	mod.drawInventoryItemStack(v, type, quantity, l, t, selected)
end

function Inventory:__init(props)
	local inventory = props.inventory

	self.numRows = (inventory.numSlots - 1) / inventory.numColumns + 1

	local children = {}
	for i = 1, inventory.numSlots do
		local slot = gui.Rectangle {
			size = { SLOT_SIZE, SLOT_SIZE },
			style = { bgColor = 26 },
			leftMargin = FU,
			topMargin = FU,

			onLeftMousePress = self.slot_onLeftMousePress,
			onMouseMove = self.slot_onMouseMove,
			onMouseLeave = self.slot_onMouseLeave,
		}

		slot.slotIndex = i
		slot.draw = drawSlot

		table.insert(children, slot)
	end

	base.__init(self, {
		var_selectedSlotX = 1,
		var_selectedSlotY = 1,
		var_inventory = inventory,
		var_isContainer = props.isContainer,

		width = inventory.numColumns * (SLOT_SIZE + FU) + 3*FU,
		height = self.numRows * (SLOT_SIZE + FU) + 11*FU,

		autoLayout = "Flow",
		style = windowStyle,
		onKeyPress = self.onKeyPress,

		children = children
	})

	self:applyProps(props)
end


---@param v videolib
---@param type itemapi.ItemType
---@param quantity integer
---@param l fixed_t
---@param t fixed_t
---@param selected boolean
function mod.drawInventoryItemStack(v, type, quantity, l, t, selected)
	local def = mod.itemDefs[type]

	local patch = cacheItemPatch(v, def)
	def.iconScale = $ or calculateDefaultIconScale(def, patch)

	local scale = def.iconScale
	if selected then
		scale = mod.sinCycle(mod.client.time, $, $ * 3 / 2, TICRATE)
	end

	local x = l + SLOT_SIZE / 2 + (patch.leftoffset - patch.width / 2) * scale
	local y = t + SLOT_SIZE / 2 + (patch.topoffset - patch.height / 2) * scale

	v.drawScaled(x, y, scale, patch)

	if quantity > 1 then
		v.drawString(l + SLOT_SIZE, t + SLOT_SIZE - 4*FU, quantity, 0, "small-fixed-right")
	end
end


mod.addMenu("inventory", {
	name = "Items",

	build = function()
		local statsWindow = mod.StatsWindow {
			title = "Stats"
		}

		statsWindow:move(4*FU, 88*FU)
		gui.root.statsWindow = statsWindow:attach(gui.root)

		---@type itemapi.InventoryWindow
		return mod.InventoryWindow {
			inventory = consoleplayer.itemapi_inventory,
			autoPosition = "Center"
		}
	end,

	destroy = function()
		mod.client.draggedInventoryItem = nil
		mod.client.tooltip = nil
		gui.root.statsWindow = gui.root.statsWindow:detach()
	end
})
