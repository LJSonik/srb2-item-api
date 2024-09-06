---@class ljgui
local gui = ljrequire "ljgui.common"

local FU = FRACUNIT


---@class ljgui.Mouse
---
---@field x fixed_t
---@field y fixed_t
---@field oldX fixed_t
---@field oldY fixed_t
---
---@field pointedItems table<integer|ljgui.Item, ljgui.Item|boolean>
---
---@field draggedItem ljgui.Item?
---@field draggedItemTickCallback fun(item: ljgui.Item, mouse: ljgui.Mouse)?
---@field draggedItemStopCallback fun(item: ljgui.Item, mouse: ljgui.Mouse)?
---
---@field enabled boolean
---@field image string
---@field flipped boolean
local Mouse = gui.class()
gui.Mouse = Mouse


function Mouse:__init()
	self.x, self.y = 0, 0
	self.oldX, self.oldY = self.x, self.y

	self.pointedItems = {}

	self:enable()
	self:setImage("LJGUI_CURSOR")
	self:flipImage(false)
end

function Mouse:move(x, y)
	self.x, self.y = x, y
end

function Mouse:enable()
	self.enabled = true
end

function Mouse:disable()
	self.enabled = false
end

---@param image string Name of the patch used to draw the cursor
function Mouse:setImage(image)
	self.image = image
end

---@param flipped boolean Whether the cursor should be horizontally flipped
function Mouse:flipImage(flipped)
	self.imageFlipped = flipped
end

function Mouse:updatePosition()
	local v = gui.v

	self.oldX, self.oldY = self.x, self.y

	local centerWidth, centerHeight = gui.getScreenCenterSize(v)
	local borderWidth, borderHeight = gui.getScreenBorderSize(v)

	local x, y = input.getCursorPosition()
	x = min(max(x - borderWidth , 0), centerWidth)
	y = min(max(y - borderHeight, 0), centerHeight)
	x = x * FU / v.dupx()
	y = y * FU / v.dupy()

	self:move(x, y)
end

---@param item ljgui.Item
---@return boolean
function Mouse:isInsideItem(item)
	return item:isPointInside(self.x, self.y)
end

-- ---@param item ljgui.Item
-- ---@return ljgui.Item?
-- function Mouse:findPointedItem(item)
-- 	if not item:isPointInside(self.x, self.y) then
-- 		return nil
-- 	end

-- 	for _, child in item.children:reverseIterate() do
-- 		local pointedChild = self:findPointedItem(child)
-- 		if pointedChild then
-- 			return pointedChild
-- 		end
-- 	end

-- 	return item
-- end

---@param item ljgui.Item
---@param pointedItems table<integer|ljgui.Item, ljgui.Item|boolean>
---@return table<integer|ljgui.Item, ljgui.Item|boolean>
function Mouse:findPointedItems(item, pointedItems)
	if not item:isPointInside(self.x, self.y) then
		return pointedItems
	end

	local prioritised = item.mouseEventsPrioritised

	if prioritised then
		pointedItems[#pointedItems + 1] = item
		pointedItems[item] = true
	end

	for _, child in item.children:reverseIterate() do
		self:findPointedItems(child, pointedItems)
	end

	if not prioritised then
		pointedItems[#pointedItems + 1] = item
		pointedItems[item] = true
	end

	return pointedItems
end

function Mouse:updateHovering()
	local manager = gui.instance.eventManager

	local oldItems = self.pointedItems
	local newItems = self:findPointedItems(gui.root, {})

	self.pointedItems = newItems

	for _, oldItem in ipairs(oldItems) do
		if not newItems[oldItem] then
			if manager:callItemEvent(oldItem, "MouseLeave", self) then
				break
			end
		end
	end

	for _, newItem in ipairs(newItems) do
		if not oldItems[newItem] then
			if manager:callItemEvent(newItem, "MouseEnter", self) then
				break
			end
		end

		if (self.x ~= self.oldX or self.y ~= self.oldY)
		and manager:callItemEvent(newItem, "MouseMove", self) then
			break
		end
	end
end

function Mouse:updateDragging()
	local item = self.draggedItem
	if not item then return end

	self.draggedItemTickCallback(item, self)
end

---@param item ljgui.Item
---@param onTick fun(item: ljgui.Item, mouse: ljgui.Mouse)
---@param onStop fun(item: ljgui.Item, mouse: ljgui.Mouse)
function Mouse:startItemDragging(item, onTick, onStop)
	if self.draggedItem then return end

	self.draggedItem = item
	self.draggedItemTickCallback = onTick
	self.draggedItemStopCallback = onStop
end

function Mouse:stopItemDragging()
	if not self.draggedItem then return end

	self.draggedItemStopCallback(self.draggedItem, self)

	self.draggedItem = nil
	self.draggedItemTickCallback = nil
	self.draggedItemStopCallback = nil
end

---@return boolean
function Mouse:pressLeftButton()
	for _, item in ipairs(self.pointedItems) do
		if gui.instance.eventManager:callItemEvent(item, "LeftMousePress", self) then
			return true
		end
	end
	return false
end

---@return boolean
function Mouse:releaseLeftButton()
	if self.draggedItem then
		self:stopItemDragging()
	end

	if gui.instance.eventManager:callGlobalItemEvent("LeftMouseRelease", self) then
		return true
	end

	-- local item = self.pointedItem
	-- if item and gui.instance.eventManager:callGlobalItemEvent(item, "LeftMouseRelease", self) then
	-- 	return true
	-- end

	return false
end

function Mouse:update()
	self:updatePosition()
	self:updateHovering()
	self:updateDragging()
end

---@param v videolib
function Mouse:draw(v)
	local patch = v.cachePatch(self.image)
	local x, y = gui.greenToReal(v, self.x, self.y)
	local f = V_NOSCALEPATCH | (self.imageFlipped and V_FLIP or 0)
	v.draw(x, y, patch, f)
end
