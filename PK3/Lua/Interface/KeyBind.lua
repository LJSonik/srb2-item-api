---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


local LONG_PRESS_DURATION = TICRATE/4

mod.gameControlToString = {
	[GC_NULL] = "GC_NULL",
	[GC_FORWARD] = "GC_FORWARD",
	[GC_BACKWARD] = "GC_BACKWARD",
	[GC_STRAFELEFT] = "GC_STRAFELEFT",
	[GC_STRAFERIGHT] = "GC_STRAFERIGHT",
	[GC_TURNLEFT] = "GC_TURNLEFT",
	[GC_TURNRIGHT] = "GC_TURNRIGHT",
	[GC_WEAPONNEXT] = "GC_WEAPONNEXT",
	[GC_WEAPONPREV] = "GC_WEAPONPREV",
	[GC_WEPSLOT1] = "GC_WEPSLOT1",
	[GC_WEPSLOT2] = "GC_WEPSLOT2",
	[GC_WEPSLOT3] = "GC_WEPSLOT3",
	[GC_WEPSLOT4] = "GC_WEPSLOT4",
	[GC_WEPSLOT5] = "GC_WEPSLOT5",
	[GC_WEPSLOT6] = "GC_WEPSLOT6",
	[GC_WEPSLOT7] = "GC_WEPSLOT7",
	[GC_WEPSLOT8] = "GC_WEPSLOT8",
	[GC_WEPSLOT9] = "GC_WEPSLOT9",
	[GC_WEPSLOT10] = "GC_WEPSLOT10",
	[GC_FIRE] = "GC_FIRE",
	[GC_FIRENORMAL] = "GC_FIRENORMAL",
	[GC_TOSSFLAG] = "GC_TOSSFLAG",
	[GC_SPIN] = "GC_SPIN",
	[GC_CAMTOGGLE] = "GC_CAMTOGGLE",
	[GC_CAMRESET] = "GC_CAMRESET",
	[GC_LOOKUP] = "GC_LOOKUP",
	[GC_LOOKDOWN] = "GC_LOOKDOWN",
	[GC_CENTERVIEW] = "GC_CENTERVIEW",
	[GC_MOUSEAIMING] = "GC_MOUSEAIMING",
	[GC_TALKKEY] = "GC_TALKKEY",
	[GC_TEAMKEY] = "GC_TEAMKEY",
	[GC_SCORES] = "GC_SCORES",
	[GC_JUMP] = "GC_JUMP",
	[GC_CONSOLE] = "GC_CONSOLE",
	[GC_PAUSE] = "GC_PAUSE",
	[GC_SYSTEMMENU] = "GC_SYSTEMMENU",
	[GC_SCREENSHOT] = "GC_SCREENSHOT",
	[GC_RECORDGIF] = "GC_RECORDGIF",
	[GC_VIEWPOINT] = "GC_VIEWPOINT",
	[GC_CUSTOM1] = "GC_CUSTOM1",
	[GC_CUSTOM2] = "GC_CUSTOM2",
	[GC_CUSTOM3] = "GC_CUSTOM3",
}

mod.gameControlNames = {
	[GC_JUMP] = "jump",
	[GC_SPIN] = "spin",

	[GC_FORWARD ] = "forward",
	[GC_BACKWARD] = "backward",

	[GC_STRAFELEFT ] = "strafe left",
	[GC_STRAFERIGHT] = "strafe right",

	[GC_TURNLEFT ] = "turn left",
	[GC_TURNRIGHT] = "turn right",

	[GC_FIRE      ] = "ring toss",
	[GC_FIRENORMAL] = "ring normal",

	[GC_TOSSFLAG] = "toss flag",

	[GC_WEAPONNEXT] = "weapon next",
	[GC_WEAPONPREV] = "weapon prev",

	[GC_WEPSLOT1 ] = "weapon 1",
	[GC_WEPSLOT2 ] = "weapon 2",
	[GC_WEPSLOT3 ] = "weapon 3",
	[GC_WEPSLOT4 ] = "weapon 4",
	[GC_WEPSLOT5 ] = "weapon 5",
	[GC_WEPSLOT6 ] = "weapon 6",
	[GC_WEPSLOT7 ] = "weapon 7",
	[GC_WEPSLOT8 ] = "weapon 8",
	[GC_WEPSLOT9 ] = "weapon 9",
	[GC_WEPSLOT10] = "weapon 10",

	[GC_CUSTOM1] = "custom 1",
	[GC_CUSTOM2] = "custom 2",
	[GC_CUSTOM3] = "custom 3",
}


---@type { [string|integer]: itemapi.UICommandDef }
mod.uiCommandDefs = {}

---@type { [string]: tic_t }
mod.client.buttonPressTimes = {}

---@type boolean
mod.client.shiftHeld = false


---@param keyName string
---@param control integer
---@return boolean
function mod.isKeyBoundToGameControl(keyName, control)
	local keyNum1, keyNum2 = input.gameControlToKeyNum(control)

	return (
		keyName == input.keyNumToName(keyNum1) or
		keyName == input.keyNumToName(keyNum2)
	)
end

---@param keyName string
---@param cmdID string
---@return boolean
function mod.isKeyBoundToUICommand(keyName, cmdID)
	local cmdDef = mod.uiCommandDefs[cmdID]

	if cmdDef.keyIsGameControl then
		return mod.isKeyBoundToGameControl(keyName, cmdDef.key)
	else
		return (keyName == cmdDef.key)
	end
end

---@param cmdID string
---@return string
function mod.getUICommandKeyName(cmdID)
	local cmdDef = mod.uiCommandDefs[cmdID]

	if cmdDef.keyIsGameControl then
		local keyNum = input.gameControlToKeyNum(cmdDef.key)
		return input.keyNumToName(keyNum)
	else
		return cmdDef.key
	end
end

---@param id string
---@param def itemapi.UICommandDef
function mod.addUICommand(id, def)
	def.index = #mod.uiCommandDefs + 1
	def.id = id
	mod.uiCommandDefs[def.index] = def
	mod.uiCommandDefs[id] = def

	local keyIsGameControl = false
	local key = def.defaultKey
	local inputType = "short"

	if key:sub(1, 6) == "short " then
		key = key:sub(7)
	elseif key:sub(1, 5) == "long " then
		key = key:sub(6)
		inputType = "long"
	end

	if key:sub(1, 1) == "@" then
		key = _G["GC_" .. key:sub(2):upper()]
		keyIsGameControl = true
	end

	def.keyIsGameControl = keyIsGameControl
	def.key = key
	def.inputType = inputType

	def.defaultKeyIsGameControl = keyIsGameControl
	def.defaultKey = key
	def.defaultInputType = inputType
end

---@param keyName string
---@return boolean
local function isKeyUsable(keyName)
	local modeDef = mod.uiModeDefs[mod.client.uiModeType]
	for _, def in ipairs(modeDef.commands) do
		if not def.modal then
			def = mod.uiCommandDefs[def.id]
		end

		if mod.isKeyBoundToUICommand(keyName, def.id) then return true end
	end

	-- for _, def in ipairs(mod.uiCommandDefs) do
	-- 	if mod.isKeyBoundToUICommand(keyName, def.id) and not def.modal then return true end
	-- end

	return false
end

---@param keyName string
---@param inputType string
local function handleInput(keyName, inputType)
	local modeDef = mod.uiModeDefs[mod.client.uiModeType]
	for _, modalDef in ipairs(modeDef.commands) do
		local def = modalDef
		if not def.modal then
			def = mod.uiCommandDefs[def.id]
		end

		if def.inputType == inputType and mod.isKeyBoundToUICommand(keyName, def.id) then
			modalDef.action()
			return
		end
	end

	-- for _, def in ipairs(mod.uiCommandDefs) do
	-- 	if def.inputType ~= inputType or def.modal
	-- 	or not mod.isKeyBoundToUICommand(keyName, def.id) then
	-- 		continue
	-- 	end

	-- 	if def.action then
	-- 		def.action()
	-- 		return
	-- 	else
	-- 		for _, modeCommandDef in ipairs(modeDef.commands) do
	-- 			if modeCommandDef.id == def.id then
	-- 				modeCommandDef.action()
	-- 				return
	-- 			end
	-- 		end
	-- 	end
	-- end
end

function mod.updateKeyBinds()
	local cl = mod.client

	local pressedKeyNames = {}
	for keyName, pressTime in pairs(cl.buttonPressTimes) do
		if cl.time - pressTime > LONG_PRESS_DURATION then
			table.insert(pressedKeyNames, keyName)
		end
	end

	for _, keyName in ipairs(pressedKeyNames) do
		cl.buttonPressTimes[keyName] = nil
		handleInput(keyName, "long")
	end
end

function mod.disableGameKeys()
	for i = 0, #gamekeydown - 1 do
		gamekeydown[i] = false
	end
end


-- !!!! Hacky workaround for 2.2.14 and earlier, which trigger key events even when the chatbox is open
mod.chatactive = false

---@param key keyevent_t
addHook("KeyDown", function(key)
	-- !!!! HACK
	if (mod.isKeyBoundToGameControl(key.name, GC_TALKKEY) or mod.isKeyBoundToGameControl(key.name, GC_TEAMKEY))
	and not mod.chatactive and netgame
	and (isserver or IsPlayerAdmin(consoleplayer) or not CV_FindVar("mute").value) then
		mod.chatactive = true
		return
	elseif mod.chatactive and (key.name == "escape" or key.name == "enter") then
		mod.chatactive = false
		return
	elseif mod.chatactive then
		return
	end

	local cl = mod.client

	if key.name == "lshift" or key.name == "rshift" then
		cl.shiftHeld = true
	end

	if gui.handleKeyDown(key) or cl.menuOpen then
		return true
	end

	if not key.repeated then
		-- Any ongoing presses get cut off if another key
		-- gets pressed before it becomes a long press
		for keyName, _ in pairs(cl.buttonPressTimes) do
			handleInput(keyName, "short")
		end
		cl.buttonPressTimes = {}

		if isKeyUsable(key.name) then
			cl.buttonPressTimes[key.name] = cl.time
			return true
		end
	end

	local modeDef = mod.uiModeDefs[cl.uiModeType]
	if not modeDef.allowMovement then return true end
end)

---@param key keyevent_t
addHook("KeyUp", function(key)
	-- !!!! HACK
	if mod.chatactive then return end

	local cl = mod.client

	if key.name == "lshift" or key.name == "rshift" then
		cl.shiftHeld = false
	end

	if gui.handleKeyUp(key) or cl.menuOpen then
		return true
	end

	if cl.buttonPressTimes[key.name] ~= nil then
		cl.buttonPressTimes[key.name] = nil
		handleInput(key.name, "short")
		return true
	end
end)
