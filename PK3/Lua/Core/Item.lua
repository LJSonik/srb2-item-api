---@class itemapi
local mod = itemapi


---@alias itemapi.ItemType string|integer

---@class itemapi.ItemDef
---@field id        string
---@field index     integer
---@field name      string
---@field template? string
---
---@field stackable  integer
---@field iconScale  fixed_t
---@field groups?    { [string]: any }
---@field dimensions integer[]
---
---@field placeable? boolean
---@field carriable? boolean
---@field storable?  boolean
---
---@field actions  itemapi.ItemActionDef[]
---@field action1? itemapi.ItemActionDef
---@field action2? itemapi.ItemActionDef
---@field action3? itemapi.ItemActionDef
---
---@field groundActions  itemapi.GroundItemActionDef[]
---@field groundAction1? itemapi.GroundItemActionDef
---@field groundAction2? itemapi.GroundItemActionDef
---@field groundAction3? itemapi.GroundItemActionDef
---
---@field groundTickers  table[]
---@field groundTicker1? table
---@field groundTicker2? table
---@field groundTicker3? table
---
---@field mobjType?   mobjtype_t
---@field mobjState?  statenum_t
---@field mobjSprite? spritenum_t
---@field mobjFrame?  integer
---@field mobjScale?  fixed_t
---
---@field model?      string
---@field modelScale? fixed_t
---
---@field onSpawn?   fun(mobj: mobj_t)
---@field onDespawn? fun(mobj: mobj_t)
---@field onPlace?   fun(mobj: mobj_t)
---@field onCarry?   fun(mobj: mobj_t)
---@field onUncarry? fun(mobj: mobj_t)


---@type { [itemapi.ItemType]: itemapi.ItemDef }
mod.itemDefs = {}

---@type { string: itemapi.ItemDef }
mod.itemDefTemplates = {}

---@type { [string]: itemapi.ItemDef[] }
mod.itemGroups = {}

---@type { [mobjtype_t]: { [statenum_t]: integer } }
mod.mobjToItemType = {}


-- elem1, elem2, elem3, ... => elems { 1, 2, 3 }
local function parseSugarArray(def, arrayName, sugarPrefix)
	if def[arrayName] then return end

	local array = {}

	local i = 1
	while def[sugarPrefix .. i] do
		table.insert(array, def[sugarPrefix .. i])
		def[sugarPrefix .. i] = nil
		i = i + 1
	end

	def[arrayName] = array
end

---Registers a new item type
---@param id string
---@param def itemapi.ItemDef
function mod.addItem(id, def)
	if type(id) ~= "string" then
		error("missing or invalid item ID", 2)
	end

	if def.template then
		local templateDef = mod.itemDefTemplates[def.template]

		def = mod.merge(templateDef, def)

		if templateDef.onTemplate then
			templateDef.onTemplate(def)
		end
	end

	def.index = #mod.itemDefs + 1
	def.id = id
	mod.itemDefs[def.index] = def
	mod.itemDefs[id] = def

	parseSugarArray(def, "actions", "action")
	parseSugarArray(def, "groundActions", "groundAction")
	parseSugarArray(def, "groundTickers", "groundTicker")

	def.stackable = $ or 1

	if def.placeable == nil then
		def.placeable = true
	end
	if def.carriable == nil then
		def.carriable = true
	end
	if def.storable == nil then
		def.storable = true
	end

	mod.addGroundItem(def)

	def.groups = $ or {}
	for groupID in pairs(def.groups) do
		mod.itemGroups[groupID] = $ or {}
		table.insert(mod.itemGroups[groupID], def.index)
	end

	for _, tickerDef in ipairs(def.groundTickers) do
		mod.register(tickerDef.ticker)
	end
end

---Registers a new item template
---@param id string
---@param def itemapi.ItemDef
function mod.addItemTemplate(id, def)
	if type(id) ~= "string" then
		error("missing or invalid item template ID", 2)
	end

	def.id = id
	mod.itemDefTemplates[id] = def
end

---@param itemID? itemapi.ItemType
---@param selector? string
---@return boolean
function mod.doesItemMatchSelector(itemID, selector)
	if not (itemID and selector) then return false end

	local itemDef = mod.itemDefs[itemID]

	itemID = itemDef.id

	if selector:sub(1, 6) == "group:" then
		local groupID = selector:sub(7)
		return (itemDef.groups[groupID])
	else
		return (itemID == selector)
	end
end