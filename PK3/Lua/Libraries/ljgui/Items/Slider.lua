---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.SliderStyle : ljgui.ItemStyle
---@field cursorWidth fixed_t
---@field cursorColor integer


---@class ljgui.Slider : ljgui.Item
---@field style ljgui.SliderStyle
---
---@field value    number
---@field valueMin number
---@field valueMax number
local Slider = gui.addItem("Slider", {
	setup = function(self)
		self.valueMin, self.valueMax = 0, FU
		self.value = (self.valueMin + self.valueMax) / 2

		self:addEvent("LeftMousePress", self.onLeftMousePress)
		-- self:addEvent("MouseEnter", self.onMouseEnter)
		-- self:addEvent("MouseLeave", self.onMouseLeave)
	end,

	applyCustomProps = function(self, props)
		if props.action then
			self:addEvent("ValueChange", props.action)
		end

		if props.range then
			self.valueMin, self.valueMax = props.range[1], props.range[2]
			self.value = (self.valueMin + self.valueMax) / 2
		end
	end,
})
gui.Slider = Slider


Slider.defaultWidth, Slider.defaultHeight = 128*FU, 6*FU

---@type ljgui.SliderStyle
Slider.defaultStyle = {
	bgColor = 26,

	cursorWidth = 3*FU,
	cursorColor = 21,

	margin = { FU, FU, FU, FU }
}


---@param x fixed_t
---@param y fixed_t
---@return boolean
function Slider:isPointInCursor(x, y)
	x = x - self.cachedLeft
	y = y - self.cachedTop

	local ratio = FixedDiv(self.value - self.valueMin, self.valueMax - self.valueMin)
	local cw = self.style.cursorWidth
	local cl = FixedMul(self.width - cw, ratio)

	return x >= cl and x < cl + cw
end

function Slider:onLeftMousePress()
	gui.instance.mouse:startItemDragging(self, self.updateDrag, self.stopDrag)
	return true
end

---@param mouse ljgui.Mouse
function Slider:updateDrag(mouse)
	local oldValue = self.value

	local cw = self.style.cursorWidth
	local minX = self.cachedLeft + cw / 2
	local ratio = FixedDiv(mouse.x - minX, self.width - cw)
	ratio = min(max(ratio, 0), FU)
	self.value = self.valueMin + FixedMul(self.valueMax - self.valueMin, ratio)

	if self.value ~= oldValue then
		gui.instance.eventManager:callItemEvent(self, "ValueChange", self.value)
	end
end

function Slider:stopDrag()
end

function Slider:draw(v)
	local style = self.style
	local ratio = FixedDiv(self.value - self.valueMin, self.valueMax - self.valueMin)
	local l, t = self.cachedLeft, self.cachedTop
	local w, h = self.width, self.height
	local cw = style.cursorWidth

	gui.drawFill(v, l, t, w, h, style.bgColor)
	gui.drawFill(v, l + FixedMul(w - cw, ratio), t, cw, h, style.cursorColor)

	-- local style = self.style
	-- local l, t = self.cachedLeft, self.cachedTop
	-- local w, h = self.width, self.height
	-- local cw = style.cursorWidth

	-- gui.drawFill(v, l, t, w, h, style.bgColor)
	-- gui.drawFill(v, l + w / 2 - cw / 2, t, cw, h, style.cursorColor)
end
