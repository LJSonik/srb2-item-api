---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


---@class itemapi.Client
---@field tooltip? table
mod.client.tooltip = nil


local function getMouseTooltipPosition(v, text)
	local mouse = gui.instance.mouse

	local w, h = mod.getTooltipBoxSize(v, text)

	local x = mouse.x + 16*FU
	if x + w >= 320*FU then
		x = mouse.x - 8*FU - w
	end

	return x, mouse.y
end

---@param v videolib
function mod.drawTooltip(v)
	local tip = mod.client.tooltip

	local bdSize = 1
	local padding = 2
	local w, h = mod.getTooltipBoxSize(v, tip.text)

	local x, y
	if tip.type == "mouse" then
		x, y = getMouseTooltipPosition(v, tip.text)
	else
		x, y = tip.x, tip.y

		if tip.anchorX == "right" then
			x = x - w
		elseif tip.anchorX == "center" then
			x = x - w / 2
		end

		if tip.anchorY == "bottom" then
			y = y - h
		elseif tip.anchorY == "center" then
			y = y - h / 2
		end
	end

	x, y = x / FU, y / FU
	w, h = w / FU, h / FU

	v.drawFill(x, y, w, h, 253)
	v.drawFill(x + bdSize, y + bdSize, w - 2 * bdSize, h - 2 * bdSize, 254)
	v.drawString(x + padding + bdSize, y + padding + bdSize, tip.text, V_ALLOWLOWERCASE, "small")
end

---@param v videolib
---@param text string
---@return fixed_t
---@return fixed_t
function mod.getTooltipBoxSize(v, text)
	local bdSize = 1
	local padding = 2

	local textWidth = v.stringWidth(text, V_ALLOWLOWERCASE, "small")
	local boxWidth = textWidth + 2 * (padding + bdSize)
	local boxHeight = 4 + 2 * (padding + bdSize)

	return boxWidth * FU, boxHeight * FU
end
