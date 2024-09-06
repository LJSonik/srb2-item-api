---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Root : ljgui.Item
local Root, base = gui.class(gui.Item)
gui.Root = Root


function Root:__init()
	base.__init(self)

	self.debug = "Root"

	self:setRooted(true)

	self:move(0, 0)
	self:resize(320*FU, 200*FU)
end

---@param v videolib
function Root:draw(v)
	self:drawChildren(v)
end
