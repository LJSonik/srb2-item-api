---@class itemapi
local mod = itemapi


mod.addInworldWidget("image", {
	spawnMobjs = function(widget, ui)
		local mo = P_SpawnMobj(ui.x, ui.y, ui.z, MT_ITEMAPI_UI)
		widget.mobj = mo

		mo.renderflags = $ | RF_PAPERSPRITE | RF_FULLBRIGHT
		mo.sprite, mo.frame = widget.sprite, widget.frame or 0
		mo.color = widget.color or SKINCOLOR_NONE

		local scale = widget.scale or FU
		mo.spritexscale = widget.scaleX or scale
		mo.spriteyscale = widget.scaleY or scale

		mo.dispoffset = widget.layer or 0
		mo.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset
	end,

	updateMobjFacing = function(widget, ui, angle)
		angle = angle + ANGLE_90

		local mo = widget.mobj

		local offset = widget.x
		local x = ui.x + FixedMul(offset, cos(angle))
		local y = ui.y + FixedMul(offset, sin(angle))
		local z = ui.z - widget.y

		-- Add extra depth based on layer
		local offset = (widget.layer or 0) * FU
		x = x + FixedMul(offset, cos(angle - ANGLE_90))
		y = y + FixedMul(offset, sin(angle - ANGLE_90))

		P_SetOrigin(mo, x, y, z)

		mo.angle = angle
	end,

	despawnMobjs = function(widget)
		if widget.mobj and widget.mobj.valid then
			P_RemoveMobj(widget.mobj)
		end

		widget.mobj = nil
	end
})
