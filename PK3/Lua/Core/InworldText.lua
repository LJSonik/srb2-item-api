---@class itemapi
local mod = itemapi


mod.addInworldWidget("text", {
	spawnMobjs = function(widget, ui)
		local fontDef = mod.spriteFontDefs["normal"]

		widget.textWidth = mod.calculateSpriteTextWidth(widget.text, fontDef)
		widget.textHeight = mod.calculateSpriteTextHeight(widget.text, fontDef)

		widget.mobjs = {}

		local scale = widget.scale or FU
		local color = widget.color or SKINCOLOR_WHITE

		for i = 1, #widget.text do
			local c = widget.text:sub(i, i)

			if c == "\n" then
				widget.mobjs[i] = nil
			else
				local mo = P_SpawnMobj(ui.x, ui.y, ui.z, MT_ITEMAPI_UI)
				widget.mobjs[i] = mo

				local spriteFrame = fontDef.characters[c] or fontDef.characters[" "]
				mo.sprite, mo.frame = spriteFrame[1], spriteFrame[2]

				mo.spritexscale = scale
				mo.spriteyscale = scale

				mo.renderflags = $ | RF_PAPERSPRITE | RF_FULLBRIGHT
				mo.dispoffset = widget.layer or 0
				mo.spriteyoffset = -4*FU -- Hack to work around OpenGL rendering with an extra 4 FU y-offset
				mo.color = color
			end
		end
	end,

	updateMobjFacing = function(widget, ui, angle)
		angle = angle + ANGLE_90

		local mobjs = widget.mobjs
		local fontDef = mod.spriteFontDefs["normal"]

		local scale = widget.scale or FU

		local dx = FixedMul(fontDef.width, scale) * cos(angle)
		local dy = FixedMul(fontDef.height, scale) * sin(angle)
		local newlineStep = FixedMul(fontDef.height + fontDef.lineGap, scale)

		-- Adjust position based on anchoring options
		local widgetX, widgetY = widget.x, widget.y
		if widget.anchorX == "right" then
			widgetX = widgetX - FixedMul(widget.textWidth, scale)
		elseif widget.anchorX == "center" then
			widgetX = widgetX - FixedMul(widget.textWidth, scale) / 2
		end
		if widget.anchorY == "bottom" then
			widgetY = widgetY - FixedMul(widget.textHeight, scale)
		elseif widget.anchorY == "center" then
			widgetY = widgetY - FixedMul(widget.textHeight, scale) / 2
		end

		local offset = widgetX
		local startX = ui.x + FixedMul(offset, cos(angle))
		local startY = ui.y + FixedMul(offset, sin(angle))
		local startZ = ui.z - widgetY

		-- Add extra depth based on layer
		local offset = (widget.layer or 0) * FU
		startX = startX + FixedMul(offset, cos(angle - ANGLE_90))
		startY = startY + FixedMul(offset, sin(angle - ANGLE_90))

		local x, y, z = startX, startY, startZ

		for i = 1, #widget.text do
			local mo = mobjs[i]

			if mo then
				P_SetOrigin(mo, x, y, z)
				mo.angle = angle

				x = x + dx
				y = y + dy
			else
				x, y = startX, startY
				z = z - newlineStep
			end
		end
	end,

	despawnMobjs = function(widget)
		for i = 1, #widget.text do
			local mo = widget.mobjs[i]
			if mo and mo.valid then
				P_RemoveMobj(mo)
			end
		end

		widget.mobjs = nil
	end
})
