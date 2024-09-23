---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.WindowStyle : ljgui.ItemStyle
---@field titleBarSize fixed_t
---@field titleBarColor integer


---@class ljgui.Window : ljgui.Item
---@field style ljgui.WindowStyle
---@field mainArea ljgui.Rectangle
---
---@field moving boolean
---
---@field resizing             boolean
---@field resizingHorizontally integer
---@field resizingVertically   integer
local Window, base = gui.class(gui.Item)
gui.Window = Window


Window.defaultWidth, Window.defaultHeight = 128*FU, 64*FU

---@type ljgui.WindowStyle
Window.defaultStyle = {
	bdSize = FU,
	bdColor = 25,

	titleBarSize = 8*FU,
	titleBarColor = 28,

	bgColor = 31
}


---@type ljgui.AutoLayoutStrategy
Window.layoutStrategy = {
	id = "Window.layoutStrategy",
	---@param window ljgui.Window
	generator = function(window)
		local l, t = window:getMainAreaPosition()
		window.mainArea:moveRaw(l, t)
	end
}

---@type ljgui.AutoPositionOrSizeStrategy
Window.windowSizeFromMainAreaStrategy = {
	id = "Window.windowSizeFromMainAreaStrategy",
	type = "children",
	usedAttributes = { "width", "height" },
	---@param window ljgui.Window
	generator = function(window)
		local mainArea = window.mainArea
		local style = window.style
		local l, t = window:getMainAreaPosition()

		local w = l + mainArea.width + style.bdSize
		local h = t + mainArea.height + style.bdSize
		return w, h
	end
}

---@type ljgui.AutoPositionOrSizeStrategy
Window.mainAreaSizeFromWindowStrategy = {
	id = "Window.mainAreaSizeFromWindowStrategy",
	type = "parent",
	usedAttributes = { "width", "height" },
	generator = function(mainArea)
		return mainArea.parent:getMainAreaSize()
	end
}


---@param props? ljgui.ItemProps
function Window:__init(props)
	base.__init(self)

	self.debug = "Window"

	if props then
		self:setTitle(props.title)
		self:build(props)
	end

	self:prioritiseMouseEvents()

	self:addEvent("LeftMousePress", self.onLeftMousePress)
	self:addEvent("MouseMove", self.onMouseMove)
	self:addEvent("MouseLeave", self.onMouseLeave)
end

---@param props? ljgui.ItemProps
function Window:build(props)
	self:applyProps(props)
	self.mainArea:attach(self)
end

---@param props? ljgui.ItemProps
function Window:applyProps(props)
	if not props then return end

	gui.parseItemProps(self, props)

	local children, autoLayout, autoSize
	if props then
		children, props.children = $2, {}
		autoLayout, props.layoutRules.autoLayout = $2, nil
		autoSize, props.layoutRules.autoSize = $2, nil
	end

	gui.applyItemProps(self, props)

	self.mainArea = $ or gui.Rectangle {
		id = "MainArea", -- !!! DBG
		children = children,
		autoLayout = autoLayout,
		autoSize = autoSize,
		style = {}
	}

	local wRules = self.layoutRules or {}
	local mRules = self.mainArea.layoutRules or {}
	wRules.autoLayout = Window.layoutStrategy
	if mRules.autoSize and mRules.autoSize.type == "children" then
		wRules.autoSize = Window.windowSizeFromMainAreaStrategy
	else
		mRules.autoSize = Window.mainAreaSizeFromWindowStrategy
	end
	self:updateLayoutRules(wRules)
	self.mainArea:updateLayoutRules(mRules)

	-- local wRules = self.layoutRules or {}
	-- local mRules = self.mainArea.layoutRules or {}
	-- mRules.autoLayout = wRules.autoLayout
	-- wRules.autoLayout = Window.layoutStrategy
	-- if wRules.autoSize and wRules.autoSize.type == "children" then
	-- 	mRules.autoSize = wRules.autoSize
	-- 	wRules.autoSize = Window.windowSizeFromMainAreaStrategy
	-- else
	-- 	mRules.autoSize = Window.mainAreaSizeFromWindowStrategy
	-- end
	-- self:updateLayoutRules(wRules)
	-- self.mainArea:updateLayoutRules(mRules)
end

---@param title string
function Window:setTitle(title)
	self.title = title
end

---@return fixed_t
---@return fixed_t
function Window:getMainAreaPosition()
	local style = self.style
	return style.bdSize, style.bdSize + style.titleBarSize
end

---@return fixed_t
---@return fixed_t
function Window:getMainAreaSize()
	local l, t = self:getMainAreaPosition()
	return
		self.width  - self.style.bdSize - l,
		self.height - self.style.bdSize - t
end

---@param x fixed_t
---@param y fixed_t
---@return boolean
function Window:isPointInBorder(x, y)
	local bs = max(self.style.bdSize, 4*FU)

	x = x - self.cachedLeft
	y = y - self.cachedTop

	return x < bs or x >= self.width  - bs
	or     y < bs or y >= self.height - bs
end

---@param x fixed_t
---@param y fixed_t
---@return boolean
function Window:isPointInTitleBar(x, y)
	return not self:isPointInBorder(x, y)
	and y - self.cachedTop < self.style.bdSize + self.style.titleBarSize
end

---@param item ljgui.Item
local function fallTicker(item)
	item:move(item.left + item.speedX, item.top + item.speedY)
	item.speedY = min($ + FU, 64*FU)
end

---@param item ljgui.Item
local function fall(item)
	item:detach()
	item:move(item.cachedLeft, item.cachedTop)
	item:attach(gui.root)

	item:addEvent("Tick", fallTicker)

	local mouse = gui.instance.mouse
	item.speedX = (mouse.x - mouse.oldX) / 8
	item.speedY = (mouse.y - mouse.oldY) / 8
end

-- function Window:onTick()
-- 	local mouse = gui.instance.mouse
-- 	local dx = mouse.x - mouse.oldX
-- 	local dy = mouse.y - mouse.oldY
-- 	local speed = R_PointToDist2(0, 0, dx, dy)
-- 	self:move(self.left + dx, self.top + dy)

-- 	if speed < 16*FU then return end

-- 	local mainArea = self.children:getFront()
-- 	if mainArea.children:getLength() then
-- 		for _, child in mainArea.children:reverseIterate() do
-- 			if gui.v.RandomChance(FU/16) then
-- 				fall(child)
-- 			end
-- 		end
-- 	else
-- 		fall(self)
-- 	end
-- end

---@return number
---@return number
function Window:getPointedBorders()
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

function Window:startMove()
	self.moving = true
	gui.instance.mouse:startItemDragging(self, self.updateMove, self.stopMove)
end

function Window:updateMove()
	local mouse = gui.instance.mouse
	local dx = mouse.x - mouse.oldX
	local dy = mouse.y - mouse.oldY
	self:move(self.left + dx, self.top + dy)
end

function Window:stopMove()
	self.moving = false
end

function Window:startResize()
	self.resizing = true
	self.resizingHorizontally, self.resizingVertically = self:getPointedBorders()
	gui.instance.mouse:startItemDragging(self, self.updateResize, self.stopResize)
end

---@param mouse ljgui.Mouse
function Window:updateResize(mouse)
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

function Window:stopResize()
	self.resizing = false
	self.resizingHorizontally, self.resizingVertically = 0, 0
end

---@param mouse ljgui.Mouse
---@return boolean
function Window:onMouseMove(mouse)
	if self.moving or self.resizing then return end

	local h, v = self:getPointedBorders()

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

function Window:onMouseLeave()
	if not (self.moving or self.resizing) then
		gui.instance.mouse:setImage("LJGUI_CURSOR")
		gui.instance.mouse:flipImage(false)
	end
end

---@param mouse ljgui.Mouse
---@return boolean
function Window:onLeftMousePress(mouse)
	if self:isPointInBorder(mouse.x, mouse.y) then
		self:startResize()
		return true
	elseif self:isPointInTitleBar(mouse.x, mouse.y) then
		self:startMove()
		return true
	else
		return false
	end
end

-- function Window:onLeftMouseRelease()
-- 	if self.moving then
-- 		self:stopMove()
-- 	elseif self.resizing then
-- 		self:stopResize()
-- 	end
-- end

-- ---@param width fixed_t
-- ---@param height fixed_t
-- function Window:resize(width, height)
-- 	base.resize(self, width, height)

-- 	if self.mainArea then
-- 		self.mainArea:resize(self:getMainAreaSize())
-- 	end
-- end

function Window:getBaseBorder()
	local style = self.style
	local bdSize = style.bdSize
	return bdSize, bdSize + style.titleBarSize, bdSize, bdSize
end

---@param v videolib
function Window:draw(v)
	local style = self.style
	local l, t = self.cachedLeft, self.cachedTop
	local w, h = self.width, self.height
	local bs = style.bdSize

	gui.drawBorders(v, l, t, w, h, bs, style.bdColor) -- Border
	gui.drawFill(v, l + bs, t + bs + style.titleBarSize, w - bs - bs, h - bs - bs - style.titleBarSize, style.bgColor) -- Background
	gui.drawFill(v, l + bs, t + bs, w - bs - bs, style.titleBarSize, style.titleBarColor) -- Title bar
	if self.title then
		gui.drawString(v, l + bs + 2*FU, t + bs + 2*FU, self.title) -- Title
	end
	self:drawChildren(v)
end
