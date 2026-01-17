---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"
local nc = ljrequire "ljnetcommand"
local bs = ljrequire "bytestream"


local netCommand_selectRecipe = nc.add(function(p, stream)
	local callbackID = bs.readUInt16(stream)
	local recipeIndex = bs.readUInt16(stream)

	local mobj = p.itemapi_mobjActionTarget

	if not (mod.craftingRecipeDefs[recipeIndex] and mobj and mobj.valid) then return end

	local onRecipeSelect = itemapi.idToEntity[callbackID]
	onRecipeSelect(mobj, recipeIndex)

	if p == consoleplayer then
		mod.closeUI()
	end
end)


---@param player player_t
---@param onRecipeSelect fun(player: player_t, recipeIndex: integer)
---@param location string?
function mod.openCraftingRecipeSelection(player, onRecipeSelect, location)
	if player == consoleplayer then
		mod.setUIMode("crafting_recipe_selection", onRecipeSelect, location)
	end
end


mod.addUIMode("crafting_recipe_selection", {
	useMouse = true,

	enter = function(onRecipeSelect, location)
		local root = gui.root

		---@type itemapi.CraftingWindow
		local craftingWindow = mod.CraftingWindow {
			location = location,

			autoPosition = "center",

			onChange = function(_, recipeIndex)
				local stream = nc.prepare(netCommand_selectRecipe)
				bs.writeUInt16(stream, itemapi.entityToID[onRecipeSelect])
				bs.writeUInt16(stream, recipeIndex)
				nc.send(consoleplayer, stream)
			end
		}

		root.craftingRecipeSelectionWindow = craftingWindow:attach(root)
		craftingWindow:focus()

		mod.disableGameKeys()
	end,

	leave = function()
		mod.client.tooltip = nil

		local root = gui.root
		root.craftingRecipeSelectionWindow = root.craftingRecipeSelectionWindow:detach()
	end,
})
