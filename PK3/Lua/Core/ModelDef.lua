---@class itemapi
local mod = itemapi


---@class itemapi.ModelPartDef
---@field x integer
---@field y integer
---@field z integer
---
---@field angleFromCenter integer
---@field distFromCenter integer
---
---@field angle integer
---@field vangle integer
---
---@field sx fixed_t
---@field sy fixed_t
---
---@field rotation integer
---@field scale fixed_t
---
---@field radius integer
---@field height integer
---
---@field [integer] any

---@class itemapi.ModelDef
---@field id string
---@field index integer
---@field cache table[]
---@field [integer] itemapi.ModelPartDef


local FU = FU


---@type table<string|integer, itemapi.ModelDef>
mod.modelDefs = {}


local importModelDefIntoModelDef

---@param cache table[]
---@param part itemapi.ModelPartDef
---@param translationX fixed_t
---@param translationY fixed_t
---@param translationZ fixed_t
---@param rotation angle_t
---@param scale fixed_t
local function cacheModelPartDef(cache, part, translationX, translationY, translationZ, rotation, scale)
	local partType = part[1]

	if partType == "model" then
		importModelDefIntoModelDef(cache, part, translationX, translationY, translationZ, rotation, scale)
		return
	end

	local sprite, frame = part[2], part[3]
	local x, y, z = part[4], part[5], part[6]

	local cachePart = {}
	table.insert(cache, cachePart)

	if x == nil then
		x = part.x or 0
	end
	if y == nil then
		y = part.y or 0
	end
	if z == nil then
		z = part.z or 0
	end

	x = x * FU
	y = y * FU
	z = z * FU

	if part.angleFromCenter ~= nil then
		local angle = FixedAngle(part.angleFromCenter * FU)
		local dist = part.distFromCenter * FU
		x = FixedMul(dist, cos(angle))
		y = FixedMul(dist, sin(angle))
	end

	local angleFromCenter = R_PointToAngle2(0, 0, x, y) + rotation
	local distFromCenter = FixedMul(R_PointToDist2(0, 0, x, y), scale)

	x = FixedMul(distFromCenter, cos(angleFromCenter))
	y = FixedMul(distFromCenter, sin(angleFromCenter))

	x = FixedMul(x, scale) + translationX
	y = FixedMul(y, scale) + translationY
	z = FixedMul(z, scale) + translationZ

	angleFromCenter = R_PointToAngle2(0, 0, x, y)
	distFromCenter = FixedMul(R_PointToDist2(0, 0, x, y), scale)

	local angle = FixedAngle(part.angle * FU) + rotation

	cachePart.sprite, cachePart.frame = sprite, frame

	if part.sx ~= nil then
		cachePart.sx = FixedMul(part.sx, scale)
	else
		cachePart.sx = scale
	end

	if part.sy ~= nil then
		cachePart.sy = FixedMul(part.sy, scale)
	else
		cachePart.sy = scale
	end

	if part.radius ~= nil then
		cachePart.radius = part.radius * scale
	else
		cachePart.radius = scale
	end

	if part.height ~= nil then
		cachePart.height = part.height * scale
	else
		cachePart.height = scale
	end

	if partType == "mobj" then
	elseif partType == "paper" then
		angle = $ + ANGLE_90
	elseif partType == "splat" then
		cachePart.vangle = FixedAngle((part.vangle or 0) * FU)
	end

	cachePart[1] = partType
	cachePart[2] = angle
	cachePart[3] = angleFromCenter
	cachePart[4] = distFromCenter
	cachePart[5] = z
end

---@param cache table
---@param part itemapi.ModelPartDef
---@param baseX fixed_t
---@param baseY fixed_t
---@param baseZ fixed_t
---@param baseRotation angle_t
---@param baseScale fixed_t
function importModelDefIntoModelDef(cache, part, baseX, baseY, baseZ, baseRotation, baseScale)
	local importedDef = mod.modelDefs[part[2]]

	local x, y, z = (part[3] or 0) * FU, (part[4] or 0) * FU, (part[5] or 0) * FU
	local rotation = FixedAngle((part.rotation or 0) * FU)
	local scale = part.scale or FU

	x, y, z = x + baseX, y + baseY, z + baseZ
	rotation = $ + baseRotation
	scale = FixedMul($, baseScale)

	for i = 1, #importedDef do
		cacheModelPartDef(cache, importedDef[i], x, y, z, rotation, scale)
	end
end

---Registers a new multisprite model
---@param id string
---@param def itemapi.ModelDef
function mod.addModel(id, def)
	if type(id) ~= "string" then
		error("missing or invalid model ID", 2)
	end

	def.index = #mod.modelDefs + 1
	def.id = id
	mod.modelDefs[def.index] = def
	mod.modelDefs[id] = def

	local cache = {}
	def.cache = cache

	for i = 1, #def do
		cacheModelPartDef(cache, def[i], 0, 0, 0, 0, FU)
	end
end
