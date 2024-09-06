---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


local LONG_PRESS_DURATION = TICRATE / 3

local handledKeyNames = mod.arrayToSet{
	"e",
	"f",
	"up arrow",
	"down arrow",
	"escape",
}

mod.remappedKeyNames = {
	["a"] = "left arrow",
	["d"] = "right arrow",
	["w"] = "up arrow",
	["s"] = "down arrow",

	["k"] = "enter",
	["lctrl"] = "escape",
}


mod.client.buttonPressTimes = {}


---@param keyName string
---@return string
function mod.remapKeyName(keyName)
	return mod.remappedKeyNames[keyName] or keyName
end

---@param keyName string
local function handleKeyPress(keyName)
	keyName = mod.remapKeyName($)

	local UIModeDef = mod.UIModeDefs[mod.client.uiModeType]
	if UIModeDef.shortPress then
		UIModeDef.shortPress(keyName)
	end
end

---@param keyName string
local function handleLongKeyPress(keyName)
	keyName = mod.remapKeyName($)

	local UIModeDef = mod.UIModeDefs[mod.client.uiModeType]
	if UIModeDef.longPress then
		UIModeDef.longPress(keyName)
	end
end


addHook("PlayerCmd", function()
	local cl = mod.client

	local pressedKeyNames = {}
	for keyName, pressTime in pairs(cl.buttonPressTimes) do
		if cl.time - pressTime > LONG_PRESS_DURATION then
			table.insert(pressedKeyNames, keyName)
		end
	end

	for _, keyName in ipairs(pressedKeyNames) do
		cl.buttonPressTimes[keyName] = nil
		handleLongKeyPress(keyName)
	end
end)

---@param key keyevent_t
addHook("KeyDown", function(key)
	local cl = mod.client

	if gui.handleKeyDown(key) or cl.menuOpen then
		return true
	end

	local keyName = key.name
	if cl.uiModeType == "action_selection" or cl.uiModeType == "large_item_placement" then
		keyName = mod.remapKeyName($)
	end

	if handledKeyNames[keyName] and not key.repeated then
		cl.buttonPressTimes[keyName] = cl.time
		return true
	end
end)

---@param key keyevent_t
addHook("KeyUp", function(key)
	local cl = mod.client
	local pressTimes = cl.buttonPressTimes

	if gui.handleKeyUp(key) or cl.menuOpen then
		return true
	end

	local keyName = key.name
	if cl.uiModeType == "action_selection" or cl.uiModeType == "large_item_placement" then
		keyName = mod.remapKeyName($)
	end

	if pressTimes[keyName] ~= nil then
		pressTimes[keyName] = nil
		handleKeyPress(keyName)
		return true
	end
end)
