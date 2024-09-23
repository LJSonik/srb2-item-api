---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


---@param player player_t
---@param inventory itemapi.Inventory
function mod.openContainer(player, inventory)
	if player == consoleplayer then
		mod.setUIMode("container", inventory)
	end
end


mod.addUIMode("container", {
	useMouse = true,

	enter = function(inventory)
		local root = gui.root

		---@type itemapi.InventoryWindow
		local containerWindow = mod.InventoryWindow {
			inventory = inventory,
			isContainer = true
		}

		containerWindow:move(124*FU, 64*FU)
		root.containerInventoryWindow = containerWindow:attach(root)
		containerWindow:focus()

		---@type itemapi.InventoryWindow
		local playerWindow = mod.InventoryWindow {
			inventory = consoleplayer.itemapi_inventory
		}

		playerWindow:move(124*FU, 128*FU)
		root.inventoryWindow = playerWindow:attach(root)

		mod.disableGameKeys()
	end,

	-- update = function()
	-- 	local cl = mod.client
	-- 	local p = consoleplayer
	-- end,

	leave = function()
		mod.client.draggedInventoryItem = nil

		local root = gui.root
		root.containerInventoryWindow = root.containerInventoryWindow:detach()
		root.inventoryWindow = root.inventoryWindow:detach()
	end,

	-- commands = {
	-- },

	-- ---@param v videolib
	-- draw = function(v)
	-- end,
})
