---@class itemapi
local mod = itemapi


---@class itemapi.ActionAnimationDef
---@field id    string
---@field index integer
---@field start fun(mobj: mobj_t, state: table, params: table, player: player_t)
---@field tick  fun(mobj: mobj_t, state: table, params: table, player: player_t)
---@field stop  fun(mobj: mobj_t, state: table, params: table, player: player_t)


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

	local mobj
	if action.type == "carried_item" then
		mobj = player.itemapi_carrySlots["right_hand"].mobj
	else
		mobj = action.target
	end

	action.animations = {}

	for _, animParams in ipairs(actionDef.animations) do
		local anim = {}
		table.insert(action.animations, anim)

		local animDef = mod.actionAnimationDefs[animParams.type]
		if animDef.start then
			animDef.start(mobj, anim, animParams, player)
		end
	end
end

---@param player player_t
function mod.updatePlayerActionAnimation(player)
	local action = player.itemapi_action
	local actionDef = mod.getActionDefFromPlayer(player)

	local mobj
	if action.type == "carried_item" then
		mobj = player.itemapi_carrySlots["right_hand"].mobj
	else
		mobj = action.target
	end

	for i, animParams in ipairs(actionDef.animations) do
		local animDef = mod.actionAnimationDefs[animParams.type]
		if animDef.tick then
			animDef.tick(mobj, action.animations[i], animParams, player)
		end
	end
end

---@param player player_t
function mod.stopPlayerActionAnimation(player)
	local action = player.itemapi_action
	local actionDef = mod.getActionDefFromPlayer(player)
	if not actionDef then return end

	local mobj
	if action.type == "carried_item" then
		mobj = player.itemapi_carrySlots["right_hand"].mobj
	else
		mobj = action.target
	end

	for i, animParams in ipairs(actionDef.animations) do
		local animDef = mod.actionAnimationDefs[animParams.type]
		if animDef.stop then
			animDef.stop(mobj, action.animations[i], animParams, player)
		end
	end
end
