---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Rectangle : ljgui.Item
local Rectangle = gui.addItem("Rectangle")
gui.Rectangle = Rectangle


---@type ljgui.ItemStyle
Rectangle.defaultStyle = {
	bgColor = 31
}


function Rectangle:draw(v)
	gui.drawBaseItemStyle(v, self, self.style)
end
