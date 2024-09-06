---@class itemapi
local mod = itemapi


---@param l1x1 fixed_t
---@param l1y1 fixed_t
---@param l1x2 fixed_t
---@param l1y2 fixed_t
---@param l2x1 fixed_t
---@param l2y fixed_t
---@param l2x2 fixed_t
---@return boolean
function mod.doesXYLineCollideWithHorizontalXYLine(l1x1, l1y1, l1x2, l1y2, l2x1, l2y, l2x2)
	if l1y1 > l1y2 then
		l1x1, l1x2 = $2, $1
		l1y1, l1y2 = $2, $1
	end

	if l1y2 < l2y or l1y1 >= l2y then return false end

	if l2x1 > l2x2 then
		l2x1, l2x2 = $2, $1
	end

	local l1dy = l1y2 - l1y1
	local l1dx = l1x2 - l1x1

	-- Integer overflow check
	if l1dx < 0 then
		if -l1dx < 32767 * l1dy then return false end
	else
		if l1dx < 32767 * l1dy then return false end
	end

	local l1step = FixedDiv(l1dx, l1dy)
	local x = FixedMul(l1step, l2y - l1y1) + l1x1

	return (x >= l2x1 and x < l2x2)
end

---@param l1x1 fixed_t
---@param l1y1 fixed_t
---@param l1x2 fixed_t
---@param l1y2 fixed_t
---@param l2x fixed_t
---@param l2y1 fixed_t
---@param l2y2 fixed_t
---@return boolean
function mod.doesXYLineCollideWithVerticalXYLine(l1x1, l1y1, l1x2, l1y2, l2x, l2y1, l2y2)
	if l1x1 > l1x2 then
		l1y1, l1y2 = $2, $1
		l1x1, l1x2 = $2, $1
	end

	if l1x2 < l2x or l1x1 >= l2x then return false end

	if l2y1 > l2y2 then
		l2y1, l2y2 = $2, $1
	end

	local l1dx = l1x2 - l1x1
	local l1dy = l1y2 - l1y1

	-- Integer overflow check
	if l1dy < 0 then
		if -l1dy < 32767 * l1dx then return false end
	else
		if l1dy < 32767 * l1dx then return false end
	end

	local l1step = FixedDiv(l1dy, l1dx)
	local y = FixedMul(l1step, l2x - l1x1) + l1y1

	return (y >= l2y1 and y < l2y2)
end

---Note: the bounding box is assumed to have bx1<bx2 and by1<by2
---@param line line_t
---@param bx1 fixed_t
---@param by1 fixed_t
---@param bx2 fixed_t
---@param by2 fixed_t
---@return boolean
function mod.doesLineCollideWithAABB(line, bx1, by1, bx2, by2)
	local v1 = line.v1
	local v2 = line.v2

	local v1x, v2x = v1.x, v2.x

	local minX, maxX
	if v1x < v2x then
		minX, maxX = v1x, v2x
	else
		minX, maxX = v2x, v1x
	end

	if maxX < bx1 or minX >= bx2 then return false end -- Outside the box?

	local v1y, v2y = v1.y, v2.y

	local minY, maxY
	if v1y < v2y then
		minY, maxY = v1y, v2y
	else
		minY, maxY = v2y, v1y
	end

	if maxY < by1 or minY >= by2 then return false end -- Outside the box?

	-- Inside the box?
	if minX >= bx1 and maxX <= bx2 and minY >= by1 and maxY <= by2 then return true end

	return
		mod.doesXYLineCollideWithVerticalXYLine(v1x, v1y, v2x, v2y, bx1, by1, by2)
		or mod.doesXYLineCollideWithVerticalXYLine(v1x, v1y, v2x, v2y, bx2, by1, by2)
		or mod.doesXYLineCollideWithHorizontalXYLine(v1x, v1y, v2x, v2y, bx1, by1, bx2)
		or mod.doesXYLineCollideWithHorizontalXYLine(v1x, v1y, v2x, v2y, bx1, by2, bx2)
end
