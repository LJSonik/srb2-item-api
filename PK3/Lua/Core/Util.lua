---@class itemapi
local mod = itemapi


---@class itemapi.Set<T>: { [T]: boolean }


---@generic T : table
---@param src T
---@param dst? table
---@return T
function mod.copy(src, dst)
	dst = dst or {}
	for k, v in pairs(src) do
		dst[k] = v
	end
	return dst
end

---@generic T : table
---@param t1 table
---@param t2 table
---@return T
function mod.merge(t1, t2)
	local dst = {}
	for k, v in pairs(t1) do
		dst[k] = v
	end
	for k, v in pairs(t2) do
		dst[k] = v
	end
	return dst
end

function mod.filter(array, cond)
	local filteredArray = {}

	for i = #array, 1, -1 do
		local v = array[i]
		if cond(v) then
			filteredArray[#filteredArray + 1] = v
		end
	end

	return filteredArray
end

---@generic T
---@param array T[]
---@return itemapi.Set<T>
function mod.arrayToSet(array)
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
function mod.findInArray(array, element)
	for i = 1, #array do
		if array[i] == element then
			return i
		end
	end
end

---@generic T
---@param array T[]
---@param element T
function mod.removeValueFromArray(array, element)
	for i = #array, 1, -1 do
		if array[i] == element then
			table.remove(array, i)
		end
	end
end

---@param value number
---@param min number
---@param max number
function mod.minMax(value, min, max)
	if value < min then
		value = min
	end

	if value > max then
		value = max
	end

	return value
end

---@param t fixed_t
---@param min number
---@param max number
---@return number
function mod.easeLinear(t, min, max)
	return min + FixedMul(t, max - min)
end

---@param time tic_t
---@param low number
---@param high number
---@param speed tic_t
---@return number
function mod.sinCycle(time, low, high, speed)
	local base = sin(time % speed * FU / speed * FU)
	return low + FixedMul(base + FU, (high - low) / 2)
end

---@param a fixed_t
---@param b fixed_t
---@return fixed_t
function mod.randomFixed(a, b)
	return P_RandomRange(a / 256, b / 256) * 256
end

---@return angle_t
function mod.randomAngle()
	return P_RandomRange(-32768, 32767) * 65536
end

---@param t any[]
---@return any
function mod.randomElement(t)
	return t[P_RandomRange(1, #t)]
end

---@param x fixed_t
---@param y fixed_t
---@param radius fixed_t
---@return fixed_t
---@return fixed_t
function mod.randomPointInCircle(x, y, radius)
	radius = $ / FU
	local rx, ry
	repeat
		rx = P_RandomRange(-radius, radius) * FU
		ry = P_RandomRange(-radius, radius) * FU
	until R_PointToDist2(0, 0, rx, ry) <= radius * FU
	return x + rx, y + ry
end

---@param angle angle_t
---@return angle_t
function mod.snapAngleToCardinalDirection(angle)
	angle = $ / 4
	if angle < 0 then
		angle = $ + ANGLE_90
	end
	return (angle + ANGLE_11hh) / ANGLE_22h * ANGLE_90
end

---@param x fixed_t
---@param y fixed_t
---@param px fixed_t
---@param py fixed_t
---@param rotation angle_t
---@return fixed_t
---@return fixed_t
function mod.rotatePointAroundPivot(x, y, px, py, rotation)
	local dist = R_PointToDist2(px, py, x, y)
	local shiftedAngle = R_PointToAngle2(px, py, x, y) + rotation

	return
		px + FixedMul(cos(shiftedAngle), dist),
		py + FixedMul(sin(shiftedAngle), dist)
end

---@param s string
---@return spritenum_t
---@return number
function mod.parseSpriteFramePair(s)
	local _, _, spritePart, framePart = s:find("(.*):(.*)")

	local sprite = _G["SPR_" .. spritePart]

	local frame
	if tonumber(frame) ~= nil then
		frame = tonumber(framePart)
	else
		frame = R_Char2Frame(framePart)
	end

	return sprite, frame
end

---@param s string
---@return { [1]: spritenum_t, [2]: number }[]
function mod.parseSpriteFramePairs(s)
	local _, _, spritePart, framePart = s:find("(.*):(.*)")

	local sprite = _G["SPR_" .. spritePart]

	local _, _, firstFramePart, lastFramePart = framePart:find("(.*)-(.*)")

	if not firstFramePart then
		firstFramePart, lastFramePart = framePart, framePart
	end

	local firstFrame
	if tonumber(firstFramePart) ~= nil then
		firstFrame = tonumber(firstFramePart)
	else
		firstFrame = R_Char2Frame(firstFramePart)
	end

	local lastFrame
	if tonumber(lastFramePart) ~= nil then
		lastFrame = tonumber(lastFramePart)
	else
		lastFrame = R_Char2Frame(lastFramePart)
	end

	local sprites = {}
	for frame = firstFrame, lastFrame do
		table.insert(sprites, { sprite, frame })
	end

	return sprites
end
