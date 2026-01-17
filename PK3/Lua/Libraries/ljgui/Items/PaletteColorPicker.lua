---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.PaletteColorPickerStyle : ljgui.ItemStyle
---@field cellSize fixed_t


---@class ljgui.PaletteColorPicker : ljgui.Item
local Picker = gui.addItem("PaletteColorPicker", {
	setup = function(self)
		self:addEvent("MouseMove", self.onMouseMove)
		self:addEvent("MouseLeave", self.onMouseLeave)
		self:addEvent("LeftMousePress", self.onLeftMousePress)
	end
})
gui.PaletteColorPicker = Picker


---@type ljgui.PaletteColorPickerStyle
Picker.defaultStyle = {
	bgColor = 31
}


function Picker:getCellSize()
	return self.width / 16
end

function Picker:onMouseMove(mouse)
	local x = (mouse.x - self.cachedLeft) / self:getCellSize()
	local y = (mouse.y - self.cachedTop ) / self:getCellSize()
	self.pointedColor = x + y * 16
end

function Picker:onMouseLeave()
	self.pointedColor = nil
end

function Picker:onLeftMousePress()
	local color = self.pointedColor
	if color ~= nil then
		gui.instance.eventManager:callItemEvent(self, "ColorPick", color)
	end
	return true
end

local function drawRectangleBorders(v, l, t, w, h, borderSize, color)
	gui.drawFill(v, l, t, w, borderSize, color) -- Top
	gui.drawFill(v, l, t, borderSize, h, color) -- Left
	gui.drawFill(v, l, t + h - borderSize, w, borderSize, color) -- Bottom
	gui.drawFill(v, l + w - borderSize, t, borderSize, h, color) -- Right
end

function Picker:draw(v)
	local l, t = self.cachedLeft, self.cachedTop
	local cellSize = self:getCellSize()

	local color = 0
	for y = t, t + 15 * cellSize, cellSize do
		for x = l, l + 15 * cellSize, cellSize do
			gui.drawFill(
				v,
				x,
				y,
				cellSize,
				cellSize,
				color
			)

			color = $ + 1
		end
	end

	if self.pointedColor ~= nil then
		drawRectangleBorders(
			v,
			l + self.pointedColor % 16 * cellSize,
			t + self.pointedColor / 16 * cellSize,
			cellSize,
			cellSize,
			1*FU,
			color
		)
	end
end
