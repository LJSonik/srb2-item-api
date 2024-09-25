---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"
local nc = ljrequire "ljnetcommand"
local bs = ljrequire "bytestream"


---@class itemapi.CraftingWindow : ljgui.Window
local CraftingWindow, base = gui.class(gui.Window)
mod.CraftingWindow = CraftingWindow


local netCommand_craftRecipe = nc.add(function(p, stream)
	local recipeIndex = bs.readUInt16(stream)

	if mod.craftingRecipeDefs[recipeIndex] then
		mod.craftRecipe(p, recipeIndex)
		mod.closeUI()
	end
end)

local function startCrafting(recipeIndex)
	local def = mod.craftingRecipeDefs[recipeIndex]
	if not def then return end

	local itemDef = mod.itemDefs[def.item]

	if itemDef.carriable then
		if not mod.canCraftRecipe(consoleplayer, recipeIndex) then return end

		local stream = nc.prepare(netCommand_craftRecipe)
		bs.writeUInt16(stream, recipeIndex)
		mod.sendNetCommand(consoleplayer, stream)
	else
		if not def:isCraftableWithInventory(consoleplayer.itemapi_inventory)
		or mod.getMainCarriedItemType(consoleplayer)
		then
			return
		end

		mod.setUIMode("large_item_placement", recipeIndex)
	end
end

---@param key keyevent_t
---@return boolean
function CraftingWindow:onKeyPress(key)
	if key.repeated then return false end

	local keyName = key.name
	if mod.handleMenuStandardKeyPress(key) then
		return true
	elseif keyName == "enter"
	or mod.isKeyBoundToUICommand(keyName, "confirm")
	or mod.isKeyBoundToUICommand(keyName, "open_action_selection") then
		startCrafting(self.navigationIndex)
		return true
	end

	return false
end

---@param element ljgui.Button
function CraftingWindow.element_onTrigger(element)
	startCrafting(element.recipeType)
end

---@param element ljgui.Button
function CraftingWindow.element_onMouseMove(element)
	mod.setMenuNavigationSelection(element.parent.parent, element.recipeType)
end

---@param oldElem ljgui.Item
---@param newElem ljgui.Item
function CraftingWindow:onNavigationChange(oldElem, newElem)
	if oldElem then
		oldElem:updateStyle({ bgColor = 31 })
	end

	if newElem then
		newElem:updateStyle({ bgColor = 16 })
	end
end

function CraftingWindow:__init(props)
	local children = {}
	for _, recipe in ipairs(mod.craftingRecipeDefs) do
		local itemDef = mod.itemDefs[recipe.item]

		table.insert(children, gui.Button {
			var_recipeType = recipe.index,

			text = ("%s (%s)"):format(itemDef.name, recipe:toString()),
			autoWidth = "FitParent",
			margin = 2*FU,

			onTrigger = CraftingWindow.element_onTrigger,
			onMouseMove = CraftingWindow.element_onMouseMove
		})
	end

	base.__init(self, {
		size = { 192*FU, 160*FU },

		movable = false,
		resizable = false,

		autoLayout = "OnePerLine",
		onKeyPress = self.onKeyPress,

		children = children
	})

	mod.addMenuNavigationToItem(self, self.mainArea, self.onNavigationChange)

	self:applyProps(props)
end


mod.addMenu("crafting", {
	name = "Craft",

	build = function()
		---@type itemapi.CraftingWindow
		return mod.CraftingWindow {
			autoPosition = "Center"
		}
	end
})
