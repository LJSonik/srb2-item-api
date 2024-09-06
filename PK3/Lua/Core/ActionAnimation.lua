---@class itemapi
local mod = itemapi


---@class itemapi.ActionAnimationDef
---@field id    string
---@field index integer
---@field start fun(mobj: mobj_t, action: itemapi.Action)
---@field tick  fun(mobj: mobj_t, action: itemapi.Action)
---@field stop  fun(mobj: mobj_t, action: itemapi.Action)


---@type { [string|integer]: itemapi.ActionAnimationDef }
mod.actionAnimationDefs = {}


---Registers a new action animation
---@param id string
---@param def itemapi.ActionAnimationDef
function mod.addActionAnimation(id, def)
	if type(id) ~= "string" then
		error("missing or invalid action animation ID", 2)
	end

	def.index = #mod.actionAnimationDefs + 1
	def.id = id
	mod.actionAnimationDefs[def.index] = def
	mod.actionAnimationDefs[id] = def
end

---@param player player_t
function mod.startPlayerActionAnimation(player)
	local action = player.itemapi_action
	local actionDef = mod.getActionDefFromPlayer(player)
	local animDef = mod.actionAnimationDefs[actionDef.animation]
	animDef.start(action.target, action)
end

---@param player player_t
function mod.updatePlayerActionAnimation(player)
	local action = player.itemapi_action
	local actionDef = mod.getActionDefFromPlayer(player)
	local animDef = mod.actionAnimationDefs[actionDef.animation]
	animDef.tick(action.target, action)
end

---@param player player_t
function mod.stopPlayerActionAnimation(player)
	local actionDef = mod.getActionDefFromPlayer(player)
	if not (actionDef and actionDef.animation) then return end

	local animDef = mod.actionAnimationDefs[actionDef.animation]
	local action = player.itemapi_action
	animDef.stop(action.target, action)
end
