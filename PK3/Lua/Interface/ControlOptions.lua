---@class itemapi
local mod = itemapi


function mod.loadControlOptions()
	local fileName = "client/ItemAPI/Controls.cfg"

	local file = io.openlocal(fileName, "r")
	if not file then return end

	for line in file:lines() do
		local keyIsGameControl = false

		-- e.g. "action = long @jump"
		local found, _, cmdID, inputType, key = line:find("([%w_]+)%s+=%s+([%w_]+)%s+(@?[%w_]+)")
		if not found then return end

		local cmdDef = mod.uiCommandDefs[cmdID]
		if not cmdDef then continue end

		if not (inputType == "short" or inputType == "long") then continue end

		if key:sub(1, 1) == "@" then
			keyIsGameControl = true
			key = _G["GC_" .. key:sub(2):upper()]
			if key == nil then continue end
		elseif input.keyNameToNum(key) == nil then
			continue
		end

		cmdDef.keyIsGameControl = keyIsGameControl
		cmdDef.inputType = inputType
		cmdDef.key = key
	end

	file:close()
end

function mod.saveControlOptions()
	local file = io.openlocal("client/ItemAPI/Controls.cfg", "w")

	for _, cmdDef in ipairs(mod.uiCommandDefs) do
		local keyID = cmdDef.keyIsGameControl
			and ("@" .. mod.gameControlToString[cmdDef.key]:sub(4):lower())
			or cmdDef.key

		file:write(("%s = %s %s\n"):format(cmdDef.id, cmdDef.inputType, keyID))
	end

	file:close()
end
