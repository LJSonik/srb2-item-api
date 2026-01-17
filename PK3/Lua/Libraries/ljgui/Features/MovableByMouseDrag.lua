---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.MovableByMouseDrag : ljgui.Feature, ljgui.Item
---@field movableByMouseDrag boolean
---@field moving  boolean
local Movable = gui.addFeature("MovableByMouseDrag")
gui.MovableByMouseDrag = Movable

function Movable.def.applyCustomProps(self, props)
	if props.movableByMouseDrag ~= nil then
		self:setMovableByMouseDrag(props.movableByMouseDrag)
	end
end


---@param x fixed_t
---@param y fixed_t
---@return boolean
function Movable:canMoveByMouseDragAtPoint(x, y)
	return true
end

---@param movable boolean
function Movable:setMovableByMouseDrag(movable)
	self.movableByMouseDrag = movable
end

function Movable:startMoveByMouseDrag()
	self.moving = true
	gui.instance.mouse:startItemDragging(self, self.updateMoveByMouseDrag, self.stopMoveByMouseDrag)
end

function Movable:updateMoveByMouseDrag()
	local mouse = gui.instance.mouse
	local dx = mouse.x - mouse.oldX
	local dy = mouse.y - mouse.oldY
	self:move(self.left + dx, self.top + dy)
end

function Movable:stopMoveByMouseDrag()
	self.moving = false
end

---@param mouse ljgui.Mouse
function Movable:movableByMouseDrag_onMouseLeave(mouse)
	if not mouse.interacting then
		gui.instance.mouse:setImage("LJGUI_CURSOR")
		gui.instance.mouse:flipImage(false)
	end
end

---@param mouse ljgui.Mouse
---@return boolean?
function Movable:movableByMouseDrag_onLeftMousePress(mouse)
	if self.movableByMouseDrag and self:canMoveByMouseDragAtPoint(mouse.x, mouse.y) then
		self:startMoveByMouseDrag()
		return true
	end
end
