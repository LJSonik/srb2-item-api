---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


---@class itemapi.UICommandDef
---@field id string
---@field index integer
---@field modal boolean
---@field action fun()
---
---@field keyIsGameControl boolean
---@field key string|integer Either key name or GC_ constant depending on defaultKeyIsGameControl
---@field inputType "short"|"long"
---@field defaultKeyIsGameControl boolean
---@field defaultKey string|integer
---@field defaultInputType "short"|"long"

---@alias itemapi.UIModeType
---| "game"
---| "menu"
---| "action_selection"
---| "large_item_placement"
---| "spot_selection"

---@class itemapi.UIModeDef
---@field id    string
---@field index integer
---
---@field commands itemapi.UICommandDef[]
---@field allowMovement boolean
---@field useMouse boolean
---
---@field enter  fun(...)
---@field leave  fun()
---@field update fun()
---@field draw   fun(v: videolib)

---@class itemapi.Client
---@field uiMode table
---@field uiModeType itemapi.UIModeType
---@field uiActive boolean


mod.client.uiMode = {}
mod.client.uiModeType = "game"
mod.client.uiActive = false

---@type { [string|integer]: itemapi.UIModeDef }
mod.uiModeDefs = {}


---@param id itemapi.UIModeType
---@param def itemapi.UIModeDef
function mod.addUIMode(id, def)
	def.index = #mod.uiModeDefs + 1
	def.id = id
	mod.uiModeDefs[def.index] = def
	mod.uiModeDefs[id] = def

	def.commands = $ or {}
	for _, commandDef in ipairs(def.commands) do
		if not mod.uiCommandDefs[commandDef.id] then
			commandDef.modal = true
			mod.addUICommand(commandDef.id, commandDef)
		end
	end
end

function mod.updateInterface()
	mod.updateKeyBinds()

	local def = mod.uiModeDefs[mod.client.uiModeType]
	if def.update then
		def.update()
	end

	mod.updateActionTargetIcon()
end

---@param stateType itemapi.UIModeType
function mod.setUIMode(stateType, ...)
	local cl = mod.client

	local def = mod.uiModeDefs[cl.uiModeType]
	if def.leave then
		def.leave()
	end

	cl.uiMode = {}
	cl.uiModeType = stateType
	cl.uiActive = (stateType ~= "game")

	local def = mod.uiModeDefs[cl.uiModeType]

	if def.useMouse then
		gui.instance.mouse:enable()
	else
		gui.instance.mouse:disable()
	end

	mod.disableGameKeys()

	if def.enter then
		def.enter(...)
	end
end

function mod.closeUI()
	mod.setUIMode("game")
end

function mod.uninitialiseInterface()
	mod.closeUI()
end


hud.add(function(v)
	local def = mod.uiModeDefs[mod.client.uiModeType]
	if def.draw then
		def.draw(v)
	end

	gui.update(v)
	gui.draw(v)

	if mod.client.tooltip then
		mod.drawTooltip(v)
	end
end, "game")


mod.addUICommand("confirm", {
	name = "confirm",
	defaultKey = "@jump"
})

mod.addUICommand("cancel", {
	name = "cancel",
	defaultKey = "@spin"
})


gui.initialise()
gui.instance.mouse:disable()
