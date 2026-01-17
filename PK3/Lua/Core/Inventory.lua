---@class itemapi
local mod = itemapi


local ljclass = ljrequire "ljclass"


---@class player_t
---@field itemapi_inventory itemapi.Inventory


---@class itemapi.Inventory : ljclass.Class
---@field numSlots   integer
---@field numColumns integer
---
---@field protected types      integer[]
---@field protected quantities integer[]
---@field protected data       any[]
local Inventory = ljclass.class()
mod.Inventory = Inventory


---@param numSlots integer The number of slots
---@param numColumns integer The number of columns
function Inventory:__init(numSlots, numColumns)
	self.numSlots = numSlots
	self.numColumns = numColumns

	self.types = {}
	self.quantities = {}
	self.data = {}
end

---@param slotIndex integer The slot index
---@return integer id The numeric ID of the item contained in the slot
---@return integer quantity How many items are contained in the slot
---@return any? data Optional extra data of the item contained in the slot
function Inventory:get(slotIndex)
	return
		self.types[slotIndex],
		self.quantities[slotIndex],
		self.data[slotIndex]
end

---@param slotIndex integer The slot index
---@return boolean
function Inventory:isSlotUsed(slotIndex)
	return (self.types[slotIndex] ~= nil)
end

---Counts the quantity of an item in the inventory
---@param id itemapi.ItemType
---@return integer
function Inventory:count(id)
	if not mod.itemDefs[id] then
		error('unknown item ID "' .. id .. '"', 2)
	end
	if type(id) == "string" then
		id = mod.itemDefs[id].index
	end

	local n = 0

	for i = 1, self.numSlots do
		if self.types[i] == id then
			n = n + self.quantities[i]
		end
	end

	return n
end

---@param id itemapi.ItemType
---@return integer quantity How many times this item can be added being the inventory becomes full.
function Inventory:countFreeSpace(id)
	if not mod.itemDefs[id] then
		error('unknown item ID "' .. id .. '"', 2)
	end
	if type(id) == "string" then
		id = mod.itemDefs[id].index
	end

	local maxPerSlot = mod.itemDefs[id].stackable
	local quantity = 0

	for i = 1, self.numSlots do
		if self.types[i] ~= id then continue end
		quantity = $ + (maxPerSlot - self.quantities[i])
	end

	for i = 1, self.numSlots do
		if self.types[i] ~= nil then continue end
		quantity = $ + maxPerSlot
	end

	return quantity
end

---@param id itemapi.ItemType
---@param quantity? integer Defaults to 1
---@return boolean canAdd True if the item(s) can be added. If not, the inventory does not have enough available space.
function Inventory:canAdd(id, quantity)
	if not mod.itemDefs[id] then
		error('unknown item ID "' .. id .. '"', 2)
	end
	if quantity == nil then
		quantity = 1
	end

	return (self:countFreeSpace(id) >= quantity)
end

---@param id itemapi.ItemType
---@param quantity? integer Defaults to 1
---@param data? any
---@return boolean added True if the item(s) was/were added. If not, the inventory does not have enough available space.
function Inventory:add(id, quantity, data)
	if not mod.itemDefs[id] then
		error('unknown item ID "' .. id .. '"', 2)
	end

	if type(id) == "string" then
		id = mod.itemDefs[id].index
	end
	if quantity == nil then
		quantity = 1
	end

	if not self:canAdd(id, quantity) then return false end

	local maxPerSlot = mod.itemDefs[id].stackable

	for i = 1, self.numSlots do
		if self.types[i] ~= id then continue end

		local room = min(maxPerSlot - self.quantities[i], quantity)
		self:addToSlot(i, id, room, data)
		quantity = $ - room
		if quantity == 0 then return true end
	end

	for i = 1, self.numSlots do
		if self.types[i] ~= nil then continue end

		local room = min(maxPerSlot, quantity)
		self:addToSlot(i, id, room, data)
		quantity = $ - room
		if quantity == 0 then return true end
	end

	return true
end

---@param id itemapi.ItemType
---@param quantity? integer Defaults to 1
---@return boolean removed True if the item(s) was/were removed. If not, the inventory does not have enough of this item.
function Inventory:remove(id, quantity)
	if not mod.itemDefs[id] then
		error('unknown item ID "' .. id .. '"', 2)
	end
	if type(id) == "string" then
		id = mod.itemDefs[id].index
	end
	if quantity == nil then
		quantity = 1
	end

	if self:count(id) < quantity then return false end

	for i = 1, self.numSlots do
		if self.types[i] ~= id then continue end

		local remaining = min(self.quantities[i], quantity)
		self:removeFromSlot(i, remaining)
		quantity = $ - remaining
		if quantity == 0 then return true end
	end

	return true
end

---@param slotIndex integer The slot index
---@param id itemapi.ItemType
---@param quantity? integer Defaults to 1
---@param data? any
function Inventory:addToSlot(slotIndex, id, quantity, data)
	if not mod.itemDefs[id] then
		error('unknown item ID "' .. id .. '"', 2)
	end
	if type(id) == "string" then
		id = mod.itemDefs[id].index
	end
	if quantity == nil then
		quantity = 1
	end

	self.types[slotIndex] = id
	self.quantities[slotIndex] = ($ or 0) + quantity
	self.data[slotIndex] = data
end

---@param slotIndex integer The slot index
---@param quantity? integer Defaults to 1
---@return integer? itemType The numeric ID of the removed item, or nil if the slotIndex does not contain enough items.
function Inventory:removeFromSlot(slotIndex, quantity)
	local types = self.types
	local quantities = self.quantities
	local data = self.data

	if quantity == nil then
		quantity = 1
	end

	local id = types[slotIndex]

	if not id or quantities[slotIndex] < quantity then
		return nil
	end

	quantities[slotIndex] = $ - quantity

	if quantities[slotIndex] == 0 then
		types[slotIndex] = nil
		quantities[slotIndex] = nil
		data[slotIndex] = nil
	end

	return id
end

---@param slotIndex integer The slot index
---@param id itemapi.ItemType
---@param quantity? integer Defaults to 1
---@param data? any
function Inventory:setSlot(slotIndex, id, quantity, data)
	if not mod.itemDefs[id] then
		error('unknown item ID "' .. id .. '"', 2)
	end
	if type(id) == "string" then
		id = mod.itemDefs[id].index
	end
	if quantity == nil then
		quantity = 1
	end

	self.types[slotIndex] = id

	if id then
		self.quantities[slotIndex] = quantity
		self.data[slotIndex] = data
	else
		self.quantities[slotIndex] = nil
		self.data[slotIndex] = nil
	end
end

---Removes anything in the specified slot
---@param slotIndex integer The slot index
function Inventory:resetSlot(slotIndex)
	self.types[slotIndex] = nil
	self.quantities[slotIndex] = nil
	self.data[slotIndex] = nil
end
