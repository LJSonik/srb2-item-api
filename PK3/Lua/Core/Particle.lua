---@class itemapi
local mod = itemapi


freeslot("MT_ITEMAPI_PARTICLE", "S_ITEMAPI_PARTICLE")

mobjinfo[MT_ITEMAPI_PARTICLE] = {
	spawnstate = S_ITEMAPI_PARTICLE,
	spawnhealth = 1,
	radius = 4*FU,
	height = 8*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOGRAVITY
}

states[S_ITEMAPI_PARTICLE] = { SPR_NULL, 0 }


---@return mobj_t[]
function mod.spawnParticlePool()
	return {}
end
