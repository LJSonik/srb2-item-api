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
		local element = self.mainArea.children:get(self.navigationIndex)
		gui.instance.eventManager:callItemEvent(self, "Change", element.recipeType)
		return true
	end

	return false
end

---@param element ljgui.Button
function CraftingWindow.element_onTrigger(element)
	gui.instance.eventManager:callItemEvent(element.parent.parent, "Change", element.recipeType)
end

---@param element ljgui.Button
function CraftingWindow.element_onMouseMove(element)
	mod.setMenuNavigationSelection(element.parent.parent, element.index)
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
	base.__init(self, {
		size = { 192*FU, 160*FU },

		movable = false,
		resizable = false,

		layout = "one_per_line",
		onKeyPress = self.onKeyPress
	})

	mod.addMenuNavigationToItem(self, self.mainArea, self.onNavigationChange)

	self:applyProps(props)

	local index = 1
	for _, recipe in ipairs(mod.craftingRecipeDefs) do
		if self.location ~= recipe.location then continue end

		local itemDef = mod.itemDefs[recipe.item]

		local button = gui.Button {
			var_index = index,
			var_recipeType = recipe.index,

			text = ("%s (%s)"):format(itemDef.name, recipe:toString()),
			autoWidth = "fit_parent",
			margin = 2*FU,

			onTrigger = CraftingWindow.element_onTrigger,
			onMouseMove = CraftingWindow.element_onMouseMove
		}
		button:attach(self.mainArea)

		index = $ + 1
	end
end


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
		or consoleplayer.itemapi_carrySlots["right_hand"]
		then
			return
		end

		mod.setUIMode("large_item_placement", recipeIndex)
	end
end

mod.addMenu("crafting", {
	name = "Craft",

	build = function()
		---@type itemapi.CraftingWindow
		return mod.CraftingWindow {
			autoPosition = "center",

			onChange = function(_, recipeIndex)
				startCrafting(recipeIndex)
			end
		}
	end
})
