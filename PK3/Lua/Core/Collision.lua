---@class itemapi
local mod = itemapi


---@param x1 fixed_t
---@param y1 fixed_t
---@param x2 fixed_t
---@param y2 fixed_t
---@param z fixed_t
---@param player player_t
---@return boolean
function mod.isGroundInAreaFlat(x1, y1, x2, y2, z, player)
	local flat = true

	---@param line line_t
	searchBlockmap("lines", function(_, line)
		if not mod.doesLineCollideWithAABB(line, x1, y1, x2, y2) then return end

		local fs = line.frontsector
		if fs.f_slope or fs.floorheight ~= z then
			flat = false
		end

		local bs = line.backsector
		if not bs or bs.f_slope or bs.floorheight ~= z then
			flat = false
		end

		if not flat then return true end
	end, player.mo, x1, x2, y1, y2)

	return flat
end

---@param x1 fixed_t
---@param y1 fixed_t
---@param z1 fixed_t
---@param x2 fixed_t
---@param y2 fixed_t
---@param z2 fixed_t
---@param player player_t
---@return boolean
function mod.doesAreaContainMobjs(x1, y1, z1, x2, y2, z2, player)
	local empty = true

	---@param mo mobj_t
	searchBlockmap("objects", function(_, mo)
		local r = mo.radius

		local mx = mo.x
		if mx + r < x1 or mx - r >= x2 then return end

		local my = mo.y
		if my + r < y1 or my - r >= y2 then return end

		local mz = mo.z
		if mz >= z2 or mz + mo.height < z1 then return end

		empty = false
		return true
	end, player.mo, x1, x2, y1, y2)

	return not empty
end
