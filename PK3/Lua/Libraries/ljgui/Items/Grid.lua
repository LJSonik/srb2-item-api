---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Grid : ljgui.Item
local Grid = gui.addItem("Grid", {
	setup = function(self)
		self:setLayout({ strategy="grid" })
	end
})
gui.Grid = Grid


function Grid:draw(v)
	gui.drawBaseItemStyle(v, self, self.style)
end
