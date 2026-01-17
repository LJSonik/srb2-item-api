---@class itemapi
local mod = itemapi


local ljclass = ljrequire "ljclass"


---@class itemapi.InworldWidgetDef
---@field id string
---@field index integer
---
---@field spawnMobjs fun(widget: itemapi.InworldWidget, ui: itemapi.InworldUI)
---@field despawnMobjs fun(widget: itemapi.InworldWidget)
---@field updateMobjFacing fun(widget: itemapi.InworldWidget, ui: itemapi.InworldUI, angle: angle_t)


---@type table<string|integer, itemapi.InworldWidgetDef>
mod.inworldWidgetDefs = {}


---@class itemapi.InworldWidget : ljclass.Class
---@field type integer
local InworldWidget = ljclass.class()
mod.InworldWidget = InworldWidget


function InworldWidget:__init(id)
	self.type = mod.inworldWidgetDefs[id].index
end


---@param id string
---@param def itemapi.InworldWidgetDef
function mod.addInworldWidget(id, def)
	if type(id) ~= "string" then
		error("missing or invalid in-world widget ID", 2)
	end

	def.index = #mod.inworldWidgetDefs + 1
	def.id = id
	mod.inworldWidgetDefs[def.index] = def
	mod.inworldWidgetDefs[id] = def
end
