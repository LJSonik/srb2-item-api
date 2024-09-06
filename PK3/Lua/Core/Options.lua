---@class itemapi
local mod = itemapi


---@class itemapi.Option
---@field id    string
---@field index integer
---@field name  string
---
---@field type "boolean"|"string"|"integer"
---@field defautValue any
---@field value any


---@type { [string|integer]: itemapi.Option }
mod.options = {}


---@param text string
---@param optionType string
---@return any
local function getOptionValueFromText(text, optionType)
	if optionType == "boolean" then
		return (text == "true")
	end
end

---@param optionValue any
---@param optionType string
---@return string
local function getTextFromOptionValue(optionValue, optionType)
	if optionType == "boolean" then
		return optionValue and "true" or "false"
	end
end

---Registers a new option
---@param id string
---@param def itemapi.Option
function mod.addOption(id, def)
	if type(id) ~= "string" then
		error("missing or invalid option ID", 2)
	end

	def.index = #mod.options + 1
	def.id = id
	mod.options[def.index] = def
	mod.options[id] = def
end

function mod.loadOptions()
	local fileName = "client/ItemAPI/Options.cfg"

	local file = io.openlocal(fileName, "r")
	if not file then return end

	for line in file:lines() do
		-- e.g. "option = value"
		local found, _, optionID, value = line:find("([%w_]+)%s+=%s+([%w_]+)")
		if not found then return end

		local option = mod.options[optionID]
		if option then
			option.value = getOptionValueFromText(value, option.type)
		end
	end

	file:close()
end

function mod.saveOptions()
	local file = io.openlocal("client/ItemAPI/Options.cfg", "w")

	for _, option in ipairs(mod.options) do
		local value = getTextFromOptionValue(option.value, option.type)
		file:write(("%s = %s\n"):format(option.id, value))
	end

	file:close()
end
