-- Cache parts:
-- [1]: type
-- [2]: angle
-- [3]: angle from center
-- [4]: distance from center
-- [5]: z-position


---@class itemapi
local mod = itemapi


---@class itemapi.Model
---@field index integer
---@field type integer
---@field clientside? boolean
---@field parts? mobj_t[] Only used for solid models
---@field mobj? mobj_t Only used if attached to a mobj
---
---@field x fixed_t
---@field y fixed_t
---@field z fixed_t
---@field rotation angle_t
---@field scale fixed_t


---@class itemapi.ModelAvatar
---@field [integer] mobj_t


local FU = FU


---@type itemapi.Model[]
mod.vars.models = {}

---@type itemapi.Model[]
mod.client.models = {}

---@type itemapi.ModelAvatar[]
mod.client.modelAvatars = {}

---@type itemapi.ModelAvatar[]
mod.client.clientModelAvatars = {}


freeslot("MT_ITEMAPI_MODELPART", "S_ITEMAPI_MODELPART")

mobjinfo[MT_ITEMAPI_MODELPART] = {
	spawnstate = S_ITEMAPI_MODELPART,
	spawnhealth = 1,
	radius = 4*FU,
	height = 8*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOTHINK|MF_NOGRAVITY
}

states[S_ITEMAPI_MODELPART] = {}


freeslot("MT_ITEMAPI_SOLIDMODELPART", "S_ITEMAPI_SOLIDMODELPART")

mobjinfo[MT_ITEMAPI_SOLIDMODELPART] = {
	spawnstate = S_ITEMAPI_SOLIDMODELPART,
	spawnhealth = 1,
	radius = 4*FU,
	height = 8*FU,
	flags = MF_SOLID|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOGRAVITY|MF_NOSECTOR
}

states[S_ITEMAPI_SOLIDMODELPART] = {}


---@param cache table[]
---@param solid? boolean
---@return mobj_t[]
local function spawnPartsFromDefCache(cache, solid)
	local parts = {}

	for i = 1, #cache do
		local partDef = cache[i]
		local partType = partDef[1]

		local type = solid and MT_ITEMAPI_SOLIDMODELPART or MT_ITEMAPI_MODELPART
		local mo = P_SpawnMobj(0, 0, 0, type)
		parts[i] = mo

		if solid then
			mo.flags = $ | MF_SOLID
		end

		mo.sprite, mo.frame = partDef.sprite, partDef.frame
		mo.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset

		if partDef.flip then
			mo.renderflags = $ | RF_HORIZONTALFLIP
		end

		if partType == "paper" then
			mo.renderflags = $ | RF_PAPERSPRITE

			if solid then
				mo.flags = $ | MF_PAPERCOLLISION
			end
		elseif partType == "splat" then
			mo.renderflags = $ | RF_FLOORSPRITE | RF_NOSPLATBILLBOARD | RF_SLOPESPLAT
			P_CreateFloorSpriteSlope(mo)
			mo.floorspriteslope.zangle = partDef.vangle
		end
	end

	return parts
end

---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param id string|integer
---@param clientside boolean
---@return itemapi.Model
local function spawnModel(x, y, z, id, clientside)
	local models = clientside and mod.client.models or mod.vars.models
	local def = mod.modelDefs[id]
	local index = #models + 1

	---@type itemapi.Model
	local model = {
		index = index,
		type = def.index,
		clientside = clientside or nil
	}

	table.insert(models, model)
	mod.setModelTransform(model, x, y, z, 0, FU)

	return model
end

---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param id string|integer
---@return itemapi.Model
function mod.spawnModel(x, y, z, id)
	return spawnModel(x, y, z, id, false)
end

---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param id string|integer
---@return itemapi.Model
function mod.spawnSolidModel(x, y, z, id)
	local def = mod.modelDefs[id]
	local index = #mod.vars.models + 1

	---@type itemapi.Model
	local model = {
		index = index,
		type = def.index
	}

	table.insert(mod.vars.models, model)
	model.parts = spawnPartsFromDefCache(def.cache, true)
	mod.setModelTransform(model, x, y, z, 0, FU)

	return model
end

---@param mobj mobj_t
---@param id string|integer
---@return itemapi.Model
function mod.spawnModelOnMobj(mobj, id)
	local model = spawnModel(mobj.x, mobj.y, mobj.z, id, false)
	model.mobj = mobj
	return model
end

---@param mobj mobj_t
---@param id string|integer
---@return itemapi.Model
function mod.spawnSolidModelOnMobj(mobj, id)
	local model = mod.spawnSolidModel(mobj.x, mobj.y, mobj.z, id)
	model.mobj = mobj
	return model
end

---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param id string|integer
---@return itemapi.Model
function mod.spawnClientModel(x, y, z, id)
	return spawnModel(x, y, z, id, true)
end

---@param model itemapi.Model
function mod.despawnModel(model)
	local i = model.index
	local models = model.clientside and mod.client.models or mod.vars.models
	local avatars = model.clientside and mod.client.clientModelAvatars or mod.client.modelAvatars
	local highestIndex = #models

	models[i] = models[highestIndex]
	models[i].index = i
	models[highestIndex] = nil

	mod.removeEntityFromCullingSystem("model", model, model.x, model.y)

	avatars[i] = avatars[highestIndex]
	avatars[highestIndex] = nil
end

---@param model itemapi.Model
---@param id string|integer
function mod.setModelType(model, id)
	local def = mod.modelDefs[id]

	mod.removeEntityFromCullingSystem("model", model, model.x, model.y)
	model.type = def.index
	mod.addEntityToCullingSystem("model", model, model.x, model.y)
end

function mod.updateModels()
	local models = mod.vars.models

	for i = #models, 1, -1 do
		local model = models[i]

		local mo = model.mobj
		if not mo then continue end

		if not mo.valid then
			mod.despawnModel(model)
			continue
		end

		local x, y, z = mo.x, mo.y, mo.z
		local rotation = mo.angle
		if x == model.x and y == model.y and z == model.z and rotation == model.rotation then continue end

		mod.setModelTransform(model, x, y, z, rotation)
	end
end

---@param model itemapi.Model
---@param parts mobj_t[]
local function applyTransform(model, parts)
	local def = mod.modelDefs[model.type]
	local defCache = def.cache

	local x, y, z = model.x, model.y, model.z
	local rotation = model.rotation
	local scale = model.scale

	for i = 1, #defCache do
		local cachePart = defCache[i]
		local mo = parts[i]

		local partType = cachePart[1]
		local angle = cachePart[2] + rotation
		local angleFromCenter = cachePart[3] + rotation
		local distFromCenter = FixedMul(cachePart[4], scale)
		local pz = FixedMul(cachePart[5], scale)

		local px = FixedMul(distFromCenter, cos(angleFromCenter))
		local py = FixedMul(distFromCenter, sin(angleFromCenter))
		px, py, pz = x + px, y + py, z + pz

		P_MoveOrigin(mo, px, py, pz)
		mo.angle = angle

		if cachePart.sx ~= nil then
			mo.spritexscale = FixedMul(cachePart.sx, scale)
		else
			mo.spritexscale = scale
		end

		if cachePart.sy ~= nil then
			mo.spriteyscale = FixedMul(cachePart.sy, scale)
		else
			mo.spriteyscale = scale
		end

		if cachePart.radius ~= nil then
			mo.radius = FixedMul(cachePart.radius, scale)
		else
			mo.radius = scale
		end

		if cachePart.height ~= nil then
			mo.height = FixedMul(cachePart.height, scale)
		else
			mo.height = scale
		end

		if partType == "splat" then
			local slope = mo.floorspriteslope
			slope.o = { x = px, y = py, z = pz }
			slope.xydirection = angle
		end
	end
end

---@param model itemapi.Model
---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param rotation? angle_t
---@param scale? fixed_t
function mod.setModelTransform(model, x, y, z, rotation, scale)
	local oldX, oldY = model.x, model.y

	model.x, model.y, model.z = x, y, z

	if rotation ~= nil then
		model.rotation = rotation
	end

	if scale ~= nil then
		model.scale = scale
	end

	if model.parts then
		applyTransform(model, model.parts)
	else
		local avatars = model.clientside and mod.client.clientModelAvatars or mod.client.modelAvatars
		if avatars[model.index] then
			applyTransform(model, avatars[model.index])
		end

		if oldX ~= nil then
			mod.moveEntityInCullingSystem("model", model, oldX, oldY, x, y)
		else
			mod.addEntityToCullingSystem("model", model, model.x, model.y)
		end
	end
end

function mod.initialiseModelAvatars()
	mod.client.modelAvatars = {}
	mod.client.clientModelAvatars = {}

	for _, models in ipairs{ mod.vars.models, mod.client.models } do
		for i = 1, #models do
			local model = models[i]
			mod.addEntityToCullingSystem("model", model, model.x, model.y)
		end
	end
end

function mod.uninitialiseModelAvatars()
	mod.client.modelAvatars = {}
	mod.client.clientModelAvatars = {}
end

function mod.uninitialiseModels()
	mod.vars.models = {}
	mod.client.models = {}
	mod.uninitialiseModelAvatars()
end


mod.addCullableEntity("model", {
	---@param model itemapi.Model
	spawn = function(model)
		local index = model.index
		local avatars = model.clientside and mod.client.clientModelAvatars or mod.client.modelAvatars
		local def = mod.modelDefs[model.type]

		if avatars[index] or model.parts then return end

		avatars[index] = spawnPartsFromDefCache(def.cache)
		applyTransform(model, avatars[index])
	end,

	---@param model itemapi.Model
	despawn = function(model)
		local index = model.index
		local avatars = model.clientside and mod.client.clientModelAvatars or mod.client.modelAvatars
		local avatar = avatars[index]

		if not avatar then return end

		for i = 1, #avatar do
			local mo = avatar[i]
			if mo.valid then
				P_RemoveMobj(mo)
			end
		end

		avatars[index] = nil
	end,
})
