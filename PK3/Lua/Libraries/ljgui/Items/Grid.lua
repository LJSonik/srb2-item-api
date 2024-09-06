---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Grid : ljgui.Item
local Grid, base = gui.class(gui.Item)
gui.Grid = Grid


---@param props ljgui.ItemProps
function Grid:__init(props)
	base.__init(self)

	self.debug = "Grid"

	self:setLayoutRules({ autoLayout = "Grid" })

	if props then
		self:build(props)
	end
end

function Grid:draw(v)
	gui.drawBaseItemStyle(v, self, self.style)
	self:drawChildren(v)
end
