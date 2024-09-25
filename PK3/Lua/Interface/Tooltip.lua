---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


---@class itemapi.Tooltip
---@field type "anywhere"|"mouse"
---@field text string
---
---@field x fixed_t
---@field y fixed_t
---
---@field anchorX fixed_t
---@field anchorY fixed_t


---@class itemapi.Client
---@field tooltip? itemapi.Tooltip
mod.client.tooltip = nil


local function getMouseTooltipPosition(v, text)
	local mouse = gui.instance.mouse

	local w, h = mod.getTooltipBoxSize(v, text)

	local x = mouse.x + 16*FU
	local y = mouse.y

	if x + w >= 320*FU then
		local newX = mouse.x - 8*FU - w
		if newX >= 0 then
			x = newX
		else
			y = y + 16*FU
		end
	end

	return x, y
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

	x = min(x, 320*FU - w)
	x = max(x, 0)
	y = min(y, 200*FU - h)
	y = max(y, 0)

	x, y = x / FU, y / FU
	w, h = w / FU, h / FU

	v.drawFill(x, y, w, h, 253)
	v.drawFill(x + bdSize, y + bdSize, w - 2 * bdSize, h - 2 * bdSize, 254)
	v.drawString(x + padding + bdSize, y + padding + bdSize, tip.text, V_ALLOWLOWERCASE, "small")
end

---@param v videolib
---@param text string
---@return fixed_t
local function calculateTextWidth(v, text)
	local totalWidth = 0

	for line in text:gmatch("[^\n]+") do
		local w = v.stringWidth(line, V_ALLOWLOWERCASE, "small")
		if w > totalWidth then
			totalWidth = w
		end
	end

	return totalWidth * FU
end

---@param v videolib
---@param text string
---@return fixed_t
---@return fixed_t
function mod.getTooltipBoxSize(v, text)
	local bdSize = 1
	local padding = 2

	local textWidth = calculateTextWidth(v, text) / FU
	local _, numNewLines = text:gsub("\n", "\n")
	local textHeight = 4 + (4 + 2) * numNewLines
	local boxWidth = textWidth + 2 * (padding + bdSize)
	local boxHeight = textHeight + 2 * (padding + bdSize)

	return boxWidth * FU, boxHeight * FU
end
