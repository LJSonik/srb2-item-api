---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.ResizableByMouseDrag : ljgui.Feature
---@field resizable boolean
---
---@field resizing             boolean
---@field resizingHorizontally integer
---@field resizingVertically   integer
local Resizable = gui.addFeature("ResizableByMouseDrag")
gui.ResizableByMouseDrag = Resizable

function Resizable.def.applyCustomProps(self, props)
	if props.resizableByMouseDrag ~= nil then
		self:setResizableByMouseDrag(props.resizableByMouseDrag)
	end
end


---@param x fixed_t
---@param y fixed_t
---@return boolean
function Resizable:canResizeByMouseDragAtPoint(x, y)
	local bs = max(self.style.bdSize, 4*FU)

	x = x - self.cachedLeft
	y = y - self.cachedTop

	return x < bs or x >= self.width  - bs
	or     y < bs or y >= self.height - bs
end

---@return number
---@return number
function Resizable:getPointedBordersForMouseDrag()
	local mouse = gui.instance.mouse
	local x = mouse.x - self.cachedLeft
	local y = mouse.y - self.cachedTop
	local bs = max(self.style.bdSize, 4*FU)

	local h = 0
	if x < bs then
		h = -1
	elseif x >= self.width - bs then
		h = 1
	end

	local v = 0
	if y < bs then
		v = -1
	elseif y >= self.height - bs then
		v = 1
	end

	return h, v
end

---@param resizable boolean
function Resizable:setResizableByMouseDrag(resizable)
	self.resizableByMouseDrag = resizable
end

function Resizable:startResizeByMouseDrag()
	self.resizing = true
	self.resizingHorizontally, self.resizingVertically = self:getPointedBordersForMouseDrag()
	gui.instance.mouse:startItemDragging(self, self.updateResizeByMouseDrag, self.stopResizeByMouseDrag)
end

---@param mouse ljgui.Mouse
function Resizable:updateResizeByMouseDrag(mouse)
	-- local mouse = gui.instance.mouse
	local x = mouse.x - self.parent.cachedLeft
	local y = mouse.y - self.parent.cachedTop
	-- local dx = mouse.x - mouse.oldX
	-- local dy = mouse.y - mouse.oldY

	local l, t = self.left, self.top
	local r, b = l + self.width, t + self.height
	local minSize = 64*FU

	if self.resizingHorizontally == -1 then
		l = min(x, r - minSize)
	elseif self.resizingHorizontally == 1 then
		r = max(x, l + minSize)
	end

	if self.resizingVertically == -1 then
		t = min(y, b - minSize)
	elseif self.resizingVertically == 1 then
		b = max(y, t + minSize)
	end

	-- if self.resizingHorizontally == -1 then
	-- 	l = min(l + dx, r - minSize)
	-- elseif self.resizingHorizontally == 1 then
	-- 	r = max(r + dx, l + minSize)
	-- end

	-- if self.resizingVertically == -1 then
	-- 	t = min(t + dy, b - minSize)
	-- elseif self.resizingVertically == 1 then
	-- 	b = max(b + dy, t + minSize)
	-- end

	self:move(l, t)
	self:resize(r - l, b - t)
end

function Resizable:stopResizeByMouseDrag()
	self.resizing = false
	self.resizingHorizontally, self.resizingVertically = 0, 0
end

---@param mouse ljgui.Mouse
---@return boolean?
function Resizable:resizableByMouseDrag_onMouseMove(mouse)
	if not self.resizableByMouseDrag or mouse.interacting then return end

	local h, v = self:getPointedBordersForMouseDrag()

	local suffix = ""
	if h then
		suffix = v and "_RESIZEHV" or "_RESIZEH"
	else
		suffix = v and "_RESIZEV" or ""
	end

	mouse:setImage("LJGUI_CURSOR" .. suffix)
	mouse:flipImage(h ~= v)

	return (suffix ~= "")
end

---@param mouse ljgui.Mouse
function Resizable:resizableByMouseDrag_onMouseLeave(mouse)
	if not mouse.interacting then
		gui.instance.mouse:setImage("LJGUI_CURSOR")
		gui.instance.mouse:flipImage(false)
	end
end

---@param mouse ljgui.Mouse
---@return boolean?
function Resizable:resizableByMouseDrag_onLeftMousePress(mouse)
	if self.resizableByMouseDrag and self:canResizeByMouseDragAtPoint(mouse.x, mouse.y) then
		self:startResizeByMouseDrag()
		return true
	end
end
