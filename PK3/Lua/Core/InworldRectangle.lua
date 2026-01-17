---@class itemapi
local mod = itemapi


freeslot("SPR_ITEMAPI_INWORLDUI_RECTANGLE")

for colorIndex = 0, 15 do
	local slotName = "SKINCOLOR_ITEMAPI_PALETTE" .. colorIndex
	freeslot(slotName)
	local slot = _G[slotName]

	local ramp = {}
	for rampIndex = 0, 15 do
		ramp[rampIndex + 1] = 16 * colorIndex + rampIndex
	end

	skincolors[slot] = {
		name = slot,
		ramp = ramp,
		accessible = false
	}
end


---@param color integer
---@return integer
---@return integer
local function getSkinColorAndFrameForPaletteColor(color)
	return SKINCOLOR_ITEMAPI_PALETTE0 + color / 16, color % 16
end


mod.addInworldWidget("rectangle", {
	spawnMobjs = function(widget, ui)
		local transFlag = 0
		if widget.opacity ~= nil then
			local trans = (FU - widget.opacity) * 10 / FU
			if trans >= 10 then
				transFlag = 0
			else
				transFlag = trans << FF_TRANSSHIFT
			end
		end

		local mo = P_SpawnMobj(ui.x, ui.y, ui.z, MT_ITEMAPI_UI)
		widget.mobj = mo

		mo.renderflags = $ | RF_PAPERSPRITE | RF_FULLBRIGHT

		local color, frame = getSkinColorAndFrameForPaletteColor(widget.color or SKINCOLOR_NONE)
		mo.sprite = SPR_ITEMAPI_INWORLDUI_RECTANGLE
		mo.color = color
		mo.frame = frame | transFlag

		mo.spritexscale = widget.width / 64
		mo.spriteyscale = widget.height / 64
		mo.dispoffset = widget.layer or 0
		mo.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset
	end,

	updateMobjFacing = function(widget, ui, angle)
		angle = angle + ANGLE_90

		local mo = widget.mobj

		-- Adjust position based on anchoring options
		local widgetX, widgetY = widget.x, widget.y
		if widget.anchorX == "right" then
			widgetX = widgetX - widget.width
		elseif widget.anchorX == "center" then
			widgetX = widgetX - widget.width / 2
		end
		if widget.anchorY == "bottom" then
			widgetY = widgetY - widget.height
		elseif widget.anchorY == "center" then
			widgetY = widgetY - widget.height / 2
		end

		local offset = widgetX
		local x = ui.x + FixedMul(offset, cos(angle))
		local y = ui.y + FixedMul(offset, sin(angle))
		local z = ui.z - widgetY

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
