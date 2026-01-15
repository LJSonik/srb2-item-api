---@class itemapi
local mod = itemapi


---@class itemapi.CarrySlotDef
---@field id    string
---@field index integer
---@field name  string
---
---@field x fixed_t
---@field y fixed_t
---@field z fixed_t


---@class itemapi.CarrySlot
---@field itemType integer
---@field itemData any
---@field mobj mobj_t
---@field multiple? boolean


---@class player_t
---@field itemapi_carrySlots { [string|integer]: itemapi.CarrySlot }


---@type { [string|integer]: itemapi.CarrySlotDef }
mod.carrySlotDefs = {}


---Registers a new carry slot
---@param id string
---@param def itemapi.CarrySlotDef
function mod.addCarrySlot(id, def)
	if type(id) ~= "string" then
		error("missing or invalid carry slot ID", 2)
	end

	def.index = #mod.carrySlotDefs + 1
	def.id = id
	mod.carrySlotDefs[def.index] = def
	mod.carrySlotDefs[id] = def
end


mod.addCarrySlot("right_hand", {})
