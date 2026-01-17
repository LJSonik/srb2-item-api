---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Root : ljgui.Item
local Root = gui.addItem("Root", {
	setup = function(self)
		self:setRooted(true)

		self:move(0, 0)
		self:resize(320*FU, 200*FU)
	end
})
gui.Root = Root
