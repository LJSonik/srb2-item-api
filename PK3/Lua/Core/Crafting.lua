---@class itemapi
local mod = itemapi


local ljclass = ljrequire "ljclass"


---@type table<string|integer, itemapi.CraftingRecipeDef>
mod.craftingRecipeDefs = {}


---@class itemapi.CraftingRecipeDef : ljclass.Class
---@field id? string
---@field index integer
---
---@field item string ID of the resulting item
---@field location? string Required location (e.g. handcrafted or workbench)
---
---Example:
---```lua
---{ { "log", 10 }, "vine", "cloth" }
---```
---@field ingredients ({ [1]: string, [2]: integer } | string)[]
local RecipeDef = ljclass.localclass()
mod.CraftingRecipeDef = RecipeDef


function RecipeDef:__init()
end

---@return string
function RecipeDef:toString()
	local text = ""

	for i, ingredient in ipairs(self.ingredients) do
		if i > 1 then
			text = $ .. " "
		end
		text = $ .. ("%dx %s"):format(ingredient[2], ingredient[1])
	end

	return text
end

---@param itemType itemapi.ItemType
---@return integer
function RecipeDef:countItemType(itemType)
	local n = 0
	local itemID = itemapi.itemDefs[itemType].id

	for _, neededIngredient in ipairs(self.ingredients) do
		if neededIngredient[1] == itemID then
			n = $ + neededIngredient[2]
		end
	end

	return n
end

---@param inventory itemapi.Inventory
---@return boolean
function RecipeDef:isCraftableWithInventory(inventory)
	for _, ingredient in ipairs(self.ingredients) do
		if ingredient[2] > inventory:count(ingredient[1]) then return false end
	end

	return true
end

---@param inventory itemapi.Inventory
function RecipeDef:removeIngredientsFromInventory(inventory)
	for _, ingredient in ipairs(self.ingredients) do
		inventory:remove(ingredient[1], ingredient[2])
	end
end


---Registers a new crafting recipe
---
---Example:
---```lua
---itemapi.addCraftingRecipe({
---    item = "raft",
---    ingredients = { { "log", 10 }, "vine", "cloth" }
---})
---```
---@param id? string
---@param def itemapi.CraftingRecipeDef
---@overload fun(def)
function mod.addCraftingRecipe(id, def)
	if not def then
		def = id
	end

	for i, ingredient in ipairs(def.ingredients) do
		if type(ingredient) == "string" then
			def.ingredients[i] = { ingredient, 1 }
		end
	end

	def = mod.copy(def, RecipeDef())

	def.index = #mod.craftingRecipeDefs + 1
	mod.craftingRecipeDefs[def.index] = def
	if id then
		def.id = id
		mod.craftingRecipeDefs[id] = def
	end
end

---@param player player_t
---@param recipeType string|integer
---@return boolean
function mod.canCraftRecipe(player, recipeType)
	local recipeDef = mod.craftingRecipeDefs[recipeType]

	if not recipeDef
	or not recipeDef:isCraftableWithInventory(player.itemapi_inventory)
	or player.itemapi_carrySlots["right_hand"]
	then
		return false
	end

	local itemDef = mod.itemDefs[recipeDef.item]
	return (itemDef.carriable or mod.canPlaceLargeItem(player, recipeDef.item))
end

---@param player player_t
---@param recipeType string|integer
function mod.craftRecipe(player, recipeType)
	local def = mod.craftingRecipeDefs[recipeType]
	local itemDef = mod.itemDefs[def.item]

	if not mod.canCraftRecipe(player, recipeType) then return end

	def:removeIngredientsFromInventory(player.itemapi_inventory)

	if itemDef.carriable then
		mod.carryItem(player, def.item)
	else
		mod.placeItem(player, def.item)
	end
end
