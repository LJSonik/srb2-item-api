---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Set<T>: { [T]: boolean }


---@generic T : table
---@param src T
---@param dst? table
---@return T
function gui.copy(src, dst)
	dst = dst or {}
	for k, v in pairs(src) do
		dst[k] = v
	end
	return dst
end

---@generic T : table
---@param t1 table
---@param t2 table
---@param dst? T
---@return T
function gui.merge(t1, t2, dst)
	dst = dst or {}
	for k, v in pairs(t1) do
		dst[k] = v
	end
	for k, v in pairs(t2) do
		dst[k] = v
	end
	return dst
end

---@generic T
---@param array T[]
---@return ljgui.Set<T>
function gui.arrayToSet(array)
	local set = {}
	for _, value in ipairs(array) do
		set[value] = true
	end
	return set
end

---@generic T
---@param array T[]
---@param element T
---@return integer?
function gui.findInArray(array, element)
	for i = 1, #array do
		if array[i] == element then
			return i
		end
	end
end

---@generic T
---@param array T[]
---@param element T
function gui.removeValueFromArray(array, element)
	for i = #array, 1, -1 do
		if array[i] == element then
			table.remove(array, i)
		end
	end
end

function gui.dec(x)
	if x >= 0 then
		return ("%d.%.2d"):format(x / FU, abs(x) % FU * 100 / FU)
	else
		return ("-%d.%.2d"):format(-x / FU, abs(-x) % FU * 100 / FU)
	end
end

local shiftedKeys = {
	["`"] = "~",
	["1"] = "!",
	["2"] = "@",
	["3"] = "#",
	["4"] = "$",
	["5"] = "%",
	["6"] = "^",
	["7"] = "&",
	["8"] = "*",
	["9"] = "(",
	["0"] = ")",
	["-"] = "_",
	["="] = "+",
	["["] = "{",
	["]"] = "}",
	["'"] = "\"",
	["\\"] = "|",
	[","] = "<",
	["."] = ">",
	["/"] = "?",
}

---@param key keyevent_t
---@param shifted boolean
function gui.keyToCharacter(key, shifted)
	if key.num >= input.keyNameToNum("a") and key.num <= input.keyNameToNum("z") then
		return shifted and key.name:upper() or key.name
	elseif shiftedKeys[key.name] then
		return shifted and shiftedKeys[key.name] or key.name
	elseif key.name == "space" then
		return " "
	else
		return nil
	end
end
