---@class ljgui
local gui = ljrequire "ljgui.common"


local FU = FRACUNIT
local fixmul = FixedMul
local fixdiv = FixedDiv


---@type integer
local cropStackLength = 0
---@type integer[]
local cropStackL, cropStackT, cropStackR, cropStackB = {}, {}, {}, {}
---@type integer
local cropL, cropT, cropR, cropB


function gui.getScreenCenterSize(v)
	return 320 * v.dupx(), 200 * v.dupy()
end

function gui.getScreenBorderSize(v)
	local w, h = gui.getScreenCenterSize(v)
	return (v.width() - w) / 2, (v.height() - h) / 2
end

---
--- Converts 320x200-based coordinates into their
--- pixel-based (resolution-dependent) equivalent
---
---@param v videolib
---@param x fixed_t
---@param y fixed_t
---@return integer
---@return integer
function gui.greenToReal(v, x, y)
	local borderWidth, borderHeight = gui.getScreenBorderSize(v)

	return
		borderWidth  + x * v.dupx() / FU,
		borderHeight + y * v.dupy() / FU
end

---@param v videolib
---@param l fixed_t
---@param t fixed_t
---@param r fixed_t
---@param b fixed_t
---@return boolean
function gui.pushDrawRegion(v, l, t, r, b)
	if cropStackLength == 0 then
		cropL, cropT, cropR, cropB = l, t, r, b
	end

	l, t = gui.greenToReal(v, l, t)
	if l >= cropR or t >= cropB then return false end

	r, b = gui.greenToReal(v, r, b)
	if r < cropL or b < cropT then return false end

	if cropL < l then
		cropL = l
	end
	if cropT < t then
		cropT = t
	end
	if cropR > r then
		cropR = r
	end
	if cropB > b then
		cropB = b
	end

	cropStackLength = $ + 1
	cropStackL[cropStackLength] = cropL
	cropStackT[cropStackLength] = cropT
	cropStackR[cropStackLength] = cropR
	cropStackB[cropStackLength] = cropB

	return true
end

function gui.popDrawRegion()
	cropStackLength = $ - 1
	cropL = cropStackL[cropStackLength]
	cropT = cropStackT[cropStackLength]
	cropR = cropStackR[cropStackLength]
	cropB = cropStackB[cropStackLength]
end

-- !!!
local cv_o = CV_RegisterVar{"o", "0", 0, { MIN = INT32_MIN, MAX = INT32_MAX }}

---@param v videolib
---@param x fixed_t
---@param y fixed_t
---@param patch patch_t
---@param flags? integer
---@param colormap? colormap
function gui.drawPatch(v, x, y, patch, flags, colormap)
	local dupx, dupy = v.dupx(), v.dupy()
	local borderWidth, borderHeight = gui.getScreenBorderSize(v)

	x = borderWidth + x * dupx / FU

	local baseL = x - patch.leftoffset * dupx
	if baseL >= cropR then return end

	local baseR = baseL + patch.width * dupx
	if baseR < cropL then return end

	y = borderHeight + y * dupy / FU

	local baseT = y - patch.topoffset * dupy
	if baseT >= cropB then return end

	local baseB = baseT + patch.height * dupy
	if baseB < cropT then return end

	local l, r, t, b = baseL, baseR, baseT, baseB
	if l < cropL then
		l = cropL
	end
	if r > cropR then
		r = cropR
	end
	if t < cropT then
		t = cropT
	end
	if b > cropB then
		b = cropB
	end

	local sx = (l - baseL) * FU
	local sy = (t - baseT) * FU
	local w = (r - l) * FU
	local h = (b - t) * FU

	v.drawCropped(
		x * FU + sx + cv_o.value,
		y * FU + sy + cv_o.value,
		FU,
		FU,
		patch,
		(flags or 0) | V_NOSCALESTART,
		colormap,
		sx / dupx,
		sy / dupy,
		w / dupx,
		h / dupy
	)
end

---@param v videolib
---@param x fixed_t
---@param y fixed_t
---@param scale fixed_t
---@param patch patch_t
---@param flags? integer
---@param colormap? colormap
function gui.drawPatchScaled(v, x, y, scale, patch, flags, colormap)
	local dupx, dupy = v.dupx(), v.dupy()
	local borderWidth, borderHeight = gui.getScreenBorderSize(v)

	x = borderWidth + x * dupx / FU

	local baseL = x - fixmul(patch.leftoffset * dupx, scale)
	if baseL >= cropR then return end

	local baseR = baseL + fixmul(patch.width * dupx, scale)
	if baseR < cropL then return end

	y = borderHeight + y * dupy / FU

	local baseT = y - fixmul(patch.topoffset * dupy, scale)
	if baseT >= cropB then return end

	local baseB = baseT + fixmul(patch.height * dupy, scale)
	if baseB < cropT then return end

	local l, r, t, b = baseL, baseR, baseT, baseB
	if l < cropL then
		l = cropL
	end
	if r > cropR then
		r = cropR
	end
	if t < cropT then
		t = cropT
	end
	if b > cropB then
		b = cropB
	end

	local sx = (l - baseL) * FU
	local sy = (t - baseT) * FU
	local w = (r - l) * FU
	local h = (b - t) * FU

	v.drawCropped(
		x * FU + sx,
		y * FU + sy,
		scale,
		scale,
		patch,
		(flags or 0) | V_NOSCALESTART,
		colormap,
		fixdiv(sx, dupx * scale),
		fixdiv(sy, dupy * scale),
		fixdiv(w, dupx * scale),
		fixdiv(h, dupy * scale)
	)
end

---@param v videolib
---@param x fixed_t
---@param y fixed_t
---@param width fixed_t
---@param height fixed_t
---@param flags? integer
function gui.drawFill(v, x, y, width, height, flags)
	local dupx, dupy = v.dupx(), v.dupy()
	local borderWidth, borderHeight = gui.getScreenBorderSize(v)

	local l = borderWidth + x * dupx / FU
	if l >= cropR then return end

	local r = l + width * dupx / FU
	if r < cropL then return end

	local t = borderHeight + y * dupy / FU
	if t >= cropB then return end

	local b = t + height * dupy / FU
	if b < cropT then return end

	if l < cropL then
		l = cropL
	end
	if r > cropR then
		r = cropR
	end
	if t < cropT then
		t = cropT
	end
	if b > cropB then
		b = cropB
	end

	v.drawFill(l, t, r - l, b - t, (flags or 0) | V_NOSCALESTART)
end

---@param v videolib
---@param x fixed_t
---@param y fixed_t
---@param text string
---@param flags? integer
function gui.drawString(v, x, y, text, flags)
	local fontFormat = "STCFN%.3d"
	local scale = FU/2
	local curX, curY = x, y
	local dx, dy = 4*FU, 6*FU
	local spaceDx = dx / 2
	local cachePatch = v.cachePatch
	local drawPatchScaled = gui.drawPatchScaled

	for c in text:gmatch(".") do
		if c == " " then
			curX = curX + spaceDx
		elseif c == "\n" then
			curX = x
			curY = curY + dy
		else
			local patch = cachePatch(fontFormat:format(c:byte()))
			drawPatchScaled(v, curX, curY, scale, patch, flags)
			curX = curX + dx
		end
	end
end

---@param v videolib
---@param text string
---@param flags? integer
function gui.stringWidth(v, text, flags)
	return v.stringWidth(text, flags | V_ALLOWLOWERCASE, "small") * FU
end

---@param v videolib
---@param x fixed_t
---@param y fixed_t
---@param text string
---@param flags? integer
---@param align? string
function gui.drawString_old(v, x, y, text, flags, align)
	local borderWidth, borderHeight = gui.getScreenBorderSize(v)

	v.drawString(
		borderWidth  + x * v.dupx() / FU,
		borderHeight + y * v.dupy() / FU,
		text,
		(flags or 0) | V_NOSCALESTART,
		align
	)
end

---@param v videolib
---@param l fixed_t
---@param t fixed_t
---@param w fixed_t
---@param h fixed_t
---@param size file_t
---@param color integer
function gui.drawBorders(v, l, t, w, h, size, color)
	local bw = w - size -- Border width
	local bh = h - size -- Border height
	local drawFill = gui.drawFill

	drawFill(v, l       , t       , bw  , size, color) -- Top
	drawFill(v, l       , t + size, size, bh  , color) -- Left
	drawFill(v, l + size, t + bh  , bw  , size, color) -- Bottom
	drawFill(v, l + bw  , t       , size, bh  , color) -- Right
end

---@param v videolib
---@param item ljgui.Item
---@param style ljgui.ItemStyle
function gui.drawBaseItemStyle(v, item, style)
	local l, t = item.cachedLeft, item.cachedTop
	local w, h = item.width, item.height
	local bs = style.bdSize

	if style.bdSize ~= nil then
		gui.drawBorders(v, l, t, w, h, bs, style.bdColor)
		if style.bgColor ~= nil then
			gui.drawFill(v, l + bs, t + bs, w - bs - bs, h - bs - bs, style.bgColor)
		end
	elseif style.bgColor ~= nil then
		gui.drawFill(v, l, t, w, h, style.bgColor)
	end
end


-- !!! DEBUG

local savedL, savedT, savedR, savedB


function gui.saveDrawRegion()
	pr(("region: %d %d %d %d"):format(cropL, cropT, cropR, cropB))
	savedL, savedT, savedR, savedB = cropL, cropT, cropR, cropB
end

function gui.drawDrawRegion(v)
	if savedL == nil then return end
	v.drawFill(savedL, savedT, savedR - savedL, savedB - savedT, 35 | V_NOSCALESTART)
end
