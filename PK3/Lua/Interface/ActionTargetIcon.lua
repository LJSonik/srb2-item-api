---@class itemapi
local mod = itemapi

freeslot("MT_ITEMAPI_ACTIONTARGETICON", "S_ITEMAPI_ACTIONTARGETICON")

mobjinfo[MT_ITEMAPI_ACTIONTARGETICON] = {
	spawnstate = S_ITEMAPI_ACTIONTARGETICON,
	spawnhealth = 1,
	radius = 8*FU,
	height = 16*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOTHINK|MF_NOGRAVITY
}

states[S_ITEMAPI_ACTIONTARGETICON] = { SPR_LCKN, C }


---@class itemapi.Client
---@field actionTargetIconMobj? mobj_t


mod.client.actionTargetIconMobj = nil


function mod.updateActionTargetIcon()
	local cl = mod.client
	local icon = cl.actionTargetIconMobj

	local mobj
	local actionSel = cl.actionSelection
	if actionSel and actionSel.targetType == "mobj" then
		mobj = actionSel.mobj
	else
		mobj = cl.aimedMobj
	end

	if mobj and not mobj.valid then
		mobj = nil
	end

	if icon then
		if not mobj then
			if icon.valid then
				P_RemoveMobj(icon)
			end

			icon = nil
			cl.actionTargetIconMobj = nil
		end
	else
		if mobj then
			local z = mobj.z + mobj.height + 16*FU
			icon = P_SpawnMobj(mobj.x, mobj.y, z, MT_ITEMAPI_ACTIONTARGETICON)
			cl.actionTargetIconMobj = icon
		end
	end

	if icon then
		local z = mobj.z + mobj.height + 16*FU
		P_MoveOrigin(icon, mobj.x, mobj.y, z)
	end
end

function mod.uninitialiseActionTargetIcon()
	local cl = mod.client
	if cl.actionTargetIconMobj then
		if cl.actionTargetIconMobj.valid then
			P_RemoveMobj(cl.actionTargetIconMobj)
		end
		cl.actionTargetIconMobj = nil
	end
end
