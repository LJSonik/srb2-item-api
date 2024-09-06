---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"
local nc = ljrequire "ljnetcommand"
local bs = ljrequire "bytestream"


local SLOT_SIZE = 16*FU
local NUM_SLOTS_X, NUM_SLOTS_Y = 4, 2


local windowStyle = {
	bdSize = FU,
	bdColor = 25,

	titleBarSize = 8*FU,
	titleBarColor = 28,

	bgColor = 27,
}

---@type boolean
mod.client.inventoryOpen = false


local netCommand_carryInventoryItem = nc.add(function(p, stream)
	local slotIndex = bs.readByte(stream)

	if mod.getMainCarriedItemType(p) then return end

	local itemType = p.itemapi_inventory:removeFromSlot(slotIndex)
	if itemType then
		mod.carryItem(p, itemType)
	end
end)


---@param key keyevent_t
local function onWindowKeyPress(window, key)
	if key.name == "escape" then
		mod.closeInventory()
		return true
	elseif key.name == "enter" then
		local slotIndex = (window.selectedSlotY - 1) * NUM_SLOTS_X + window.selectedSlotX

		local stream = nc.prepare(netCommand_carryInventoryItem)
		bs.writeByte(stream, slotIndex)
		mod.sendNetCommand(consoleplayer, stream)

		mod.closeInventory()
	elseif key.name == "left arrow" then
		if window.selectedSlotX > 1 then
			window.selectedSlotX = $ - 1
		else
			window.selectedSlotX = NUM_SLOTS_X
		end
	elseif key.name == "right arrow" then
		if window.selectedSlotX < NUM_SLOTS_X then
			window.selectedSlotX = $ + 1
		else
			window.selectedSlotX = 1
		end
	elseif key.name == "up arrow" then
		if window.selectedSlotY > 1 then
			window.selectedSlotY = $ - 1
		else
			window.selectedSlotY = NUM_SLOTS_Y
		end
	elseif key.name == "down arrow" then
		if window.selectedSlotY < NUM_SLOTS_Y then
			window.selectedSlotY = $ + 1
		else
			window.selectedSlotY = 1
		end
	end
end

---@param item ljgui.Item
---@param v videolib
local function drawSlot(item, v)
	local window = item.parent.parent
	local selectedIndex = (window.selectedSlotY - 1) * NUM_SLOTS_X + window.selectedSlotX
	local selected = (selectedIndex == item.slotIndex)
	local l, t = item.cachedLeft, item.cachedTop
	local w, h = item.width, item.height

	local bgColor = selected and 22 or 26
	gui.drawFill(v, l, t, w, h, bgColor)

	local type, quantity = consoleplayer.itemapi_inventory:get(item.slotIndex)
	if not type then return end

	local def = mod.itemDefs[type]

	local scale = FU/2
	if selected then
		scale = mod.sinCycle(leveltime, $, $ * 3 / 2, TICRATE)
	end

	local basePatch = sprnames[def.mobjSprite] + R_Frame2Char(def.mobjFrame)
	local patchName = basePatch .. "0"
	if not v.patchExists(patchName) then
		patchName = basePatch .. "1"
	end
	local patch = v.cachePatch(patchName)

	local x = l + SLOT_SIZE / 2 + (patch.leftoffset - patch.width / 2) * scale
	local y = t + SLOT_SIZE / 2 + (patch.topoffset - patch.height / 2) * scale

	v.drawScaled(x, y, scale, patch)

	if quantity > 1 then
		v.drawString(l + SLOT_SIZE, t + SLOT_SIZE - 4*FU, quantity, 0, "small-fixed-right")
	end
end

function mod.openInventory()
	local children = {}
	for i = 1, NUM_SLOTS_X * NUM_SLOTS_Y do
		local slot = gui.Rectangle {
			size = { SLOT_SIZE, SLOT_SIZE },
			style = { bgColor = 26 },
			leftMargin = FU,
			topMargin = FU,
		}

		slot.slotIndex = i
		slot.draw = drawSlot

		table.insert(children, slot)
	end

	---@type ljgui.Window
	local window = gui.Window {
		title = " ",

		autoPosition = "Center",
		width = NUM_SLOTS_X * (SLOT_SIZE + FU) + 3*FU,
		height = NUM_SLOTS_Y * (SLOT_SIZE + FU) + 11*FU,

		autoLayout = "Flow",
		style = windowStyle,
		onKeyPress = onWindowKeyPress,

		children = children
	}

	window.selectedSlotX = 1
	window.selectedSlotY = 1

	window:attach(gui.root)
	window:focus()
	gui.root.inventoryWindow = window

	-- gui.instance.mouse:enable()

	for i = 0, #gamekeydown - 1 do
		gamekeydown[i] = false
	end

	mod.client.inventoryOpen = true
end

function mod.closeInventory()
	gui.root.inventoryWindow:detach()
	gui.instance.mouse:disable()
	mod.client.inventoryOpen = false
end
