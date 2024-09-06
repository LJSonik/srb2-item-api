---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Rectangle : ljgui.Item
local Rectangle, base = gui.class(gui.Item)
gui.Rectangle = Rectangle


---@type ljgui.ItemStyle
Rectangle.defaultStyle = {
	bgColor = 31
}


---@param props ljgui.ItemProps
function Rectangle:__init(props)
	base.__init(self)

	self.debug = "Rectangle"

	if props then
		self:build(props)
	end
end

function Rectangle:draw(v)
	gui.drawBaseItemStyle(v, self, self.style)
	self:drawChildren(v)
end
