---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.WindowStyle : ljgui.ItemStyle
---@field titleBarSize fixed_t
---@field titleBarColor integer


---@class ljgui.Window : ljgui.Item, ljgui.MovableByMouseDrag, ljgui.ResizableByMouseDrag
---@field style ljgui.WindowStyle
---@field mainArea ljgui.Rectangle
local Window = gui.addItem("Window", {
	features = { gui.MovableByMouseDrag, gui.ResizableByMouseDrag },

	applyCustomProps = function(self, props)
		if props.title then
			self:setTitle(props.title)
		end
	end
})
gui.Window = Window


Window.defaultWidth, Window.defaultHeight = 128*FU, 64*FU

---@type ljgui.WindowStyle
Window.defaultStyle = {
	bdSize = FU,
	bdColor = 25,

	titleBarSize = 8*FU,
	titleBarColor = 26,

	bgColor = 31
}


Window.layoutStrategy = gui.addLayoutStrategy(nil, {
	---@param window ljgui.Window
	compute = function(window)
		local l, t = window:getMainAreaPosition()
		window.mainArea:moveRaw(l, t)
	end
})

Window.windowWidthFromMainAreaStrategy = gui.addAutoStrategy(nil, "width", {
	dependencyType = "children",
	dependency = {"children", "width" },

	---@param window ljgui.Window
	compute = function(window)
		local l, _ = window:getMainAreaPosition()
		local w = l + window.mainArea.width + window.style.bdSize
		window:resize(w, nil)
	end
})

Window.windowHeightFromMainAreaStrategy = gui.addAutoStrategy(nil, "height", {
	dependencyType = "children",
	dependency = { "children", "height" },

	---@param window ljgui.Window
	compute = function(window)
		local _, t = window:getMainAreaPosition()
		local h = t + window.mainArea.height + window.style.bdSize
		window:resize(nil, h)
	end
})

Window.mainAreaWidthFromWindowStrategy = gui.addAutoStrategy(nil, "width", {
	dependencyType = "parent",
	dependency = {"parent", "width" },

	compute = function(mainArea)
		local w, _ = mainArea.parent:getMainAreaSize()
		mainArea:resize(w, nil)
	end
})

Window.mainAreaHeightFromWindowStrategy = gui.addAutoStrategy(nil, "height", {
	dependencyType = "parent",
	dependency = { "parent", "height" },

	compute = function(mainArea)
		local _, h = mainArea.parent:getMainAreaSize()
		mainArea:resize(nil, h)
	end
})

---@param self ljgui.Window
---@param props ljgui.ItemProps
function Window.def.setup(self, props)
	self:setMovableByMouseDrag(true)
	self:setResizableByMouseDrag(true)

	self:prioritiseMouseEvents()

	self:addEvent("LeftMousePress", self.movableByMouseDrag_onLeftMousePress)
	self:addEvent("LeftMousePress", self.resizableByMouseDrag_onLeftMousePress)
	self:addEvent("MouseMove", self.resizableByMouseDrag_onMouseMove)
	self:addEvent("MouseLeave", self.movableByMouseDrag_onMouseLeave)
	self:addEvent("MouseLeave", self.resizableByMouseDrag_onMouseLeave)

	---@type ljgui.Rectangle
	local mainArea = gui.Rectangle(props.mainArea or {})
	self.mainArea = mainArea:attach(self)

	-- This layout will be used to always keep the main area at the correct offsets
	self:setLayout({ strategy = Window.layoutStrategy })

	-- Decide whether to make the content depend on the window or the other way around based on auto-attributes
	local autoWidth, autoHeight = mainArea.autoAttributes.width, mainArea.autoAttributes.height
	local wStrategy = autoWidth  and gui.autoAttributeStrategies["width" ][autoWidth.strategy ] or nil
	local hStrategy = autoHeight and gui.autoAttributeStrategies["height"][autoHeight.strategy] or nil

	if not wStrategy then
		gui.setItemAutoAttribute(mainArea, "width", { strategy = Window.mainAreaWidthFromWindowStrategy })
	elseif wStrategy.dependencyType ~= "parent" and not self.autoAttributes.width then
		gui.setItemAutoAttribute(self, "width", { strategy = Window.windowWidthFromMainAreaStrategy })
	end

	if not hStrategy then
		gui.setItemAutoAttribute(mainArea, "height", { strategy = Window.mainAreaHeightFromWindowStrategy })
	elseif hStrategy.dependencyType ~= "parent" and not self.autoAttributes.height then
		gui.setItemAutoAttribute(self, "height", { strategy = Window.windowHeightFromMainAreaStrategy })
	end
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

function Window:canMoveByMouseDragAtPoint(x, y)
	return self:isPointInTitleBar(x, y)
end

function Window:canResizeByMouseDragAtPoint(x, y)
	return self:isPointInBorder(x, y)
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
-- 			if gui.v.RandomChance(FU / 16) then
-- 				fall(child)
-- 			end
-- 		end
-- 	else
-- 		fall(self)
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
end
