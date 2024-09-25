---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


local SLOT_SIZE = 16*FU


local drawMouseBase = gui.Mouse.draw

---@param v videolib
function gui.Mouse:draw(v)
	local item = mod.client.draggedInventoryItem
	if item and item.byMouse then
		local type, quantity = item.window.inventory:get(item.slotIndex)
		if type then
			local x = self.x - SLOT_SIZE / 2
			local y = self.y - SLOT_SIZE / 2
			mod.drawInventoryItemStack(v, type, quantity, x, y, false)
		end
	end

	drawMouseBase(self, v)
end
