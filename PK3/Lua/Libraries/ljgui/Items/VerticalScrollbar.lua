---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.VerticalScrollbarStyle : ljgui.ItemStyle
---@field cursorHeight fixed_t
---@field cursorColor integer


---@class ljgui.VerticalScrollbar : ljgui.Item
---@field style ljgui.VerticalScrollbarStyle
---@field targetItem? ljgui.Item
local Scrollbar = gui.addItem("VerticalScrollbar", {
	setup = function(self)
		self:addEvent("LeftMousePress", self.onLeftMousePress)
	end,

	applyCustomProps = function(self, props)
		if props.target then
			self:setTargetItem(props.target)
		end
	end,
})
gui.VerticalScrollbar = Scrollbar


Scrollbar.defaultWidth, Scrollbar.defaultHeight = 8*FU, 128*FU

---@type ljgui.VerticalScrollbarStyle
Scrollbar.defaultStyle = {
	bgColor = 26,

	cursorHeight = 8*FU,
	cursorColor = 21,
}


---@param x fixed_t
---@param y fixed_t
---@return boolean
function Scrollbar:isPointInCursor(x, y)
	x = x - self.cachedLeft
	y = y - self.cachedTop

	-- local ratio = FixedDiv(self.value - self.valueMin, self.valueMax - self.valueMin)
	local ratio = 0
	local ch = self.style.cursorHeight
	local ct = FixedMul(self.height - ch, ratio)

	return y >= ct and y < ct + ch
end

---@param targetItem ljgui.Item
function Scrollbar:setTargetItem(targetItem)
	self.targetItem = targetItem
end

function Scrollbar:onLeftMousePress()
	gui.instance.mouse:startItemDragging(self, self.updateDrag, self.stopDrag)
	return true
end

---@param mouse ljgui.Mouse
function Scrollbar:updateDrag(mouse)
	local ch = self.style.cursorHeight
	local minY = self.cachedTop + ch / 2
	local ratio = FixedDiv(mouse.y - minY, self.height - ch)
	ratio = min(max(ratio, 0), FU)

	local target = self.targetItem
	local top = FixedMul(target.contentHeight - target.height, ratio)
	target:moveView(target.left, top)
end

function Scrollbar:stopDrag()
end

function Scrollbar:draw(v)
	local style = self.style
	local l, t = self.cachedLeft, self.cachedTop
	local w, h = self.width, self.height
	local target = self.targetItem
	local overflowHeight = target.contentHeight - target.height

	if overflowHeight > 0 then
		local cursorH = FixedMul(self.height, FixedDiv(target.height, target.contentHeight))
		local ratio = FixedDiv(target.viewTop, overflowHeight)

		gui.drawFill(v, l, t, w, h, style.bgColor)
		gui.drawFill(v, l, t + FixedMul(h - cursorH, ratio), w, cursorH, style.cursorColor)
	else
		gui.drawFill(v, l, t, w, h, style.cursorColor)
	end
end
