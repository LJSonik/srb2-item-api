--#region modules

---@class ljgui
local gui = ljrequire "ljgui.common"

--#endregion

--#region classes

---@class ljgui.ItemStyle
---@field bgColor integer
---@field bdSize? fixed_t
---@field bdColor? integer
---@field margin? table

---@class ljgui.Item : ljgui.Class
---@field depth                  integer
---@field props                  ljgui.ItemProps
---@field mouseEventsPrioritised boolean
---@field getBaseBorder          ljgui.BaseBorderGetter
---
---@field parent?    ljgui.Item
---@field children   ljgui.ItemList
---@field rooted     boolean
---
---@field modifiedAttributes     ljgui.Set<string>
---@field attributeRootDistances table<string, integer>
---
---@field layoutGenerated boolean
---@field layoutRules?     ljgui.LayoutRules
---
---@field left        fixed_t
---@field top         fixed_t
---@field cachedLeft? fixed_t
---@field cachedTop?  fixed_t
---
---@field width         fixed_t
---@field height        fixed_t
---@field contentWidth  fixed_t
---@field contentHeight fixed_t
---@field defaultWidth  fixed_t
---@field defaultHeight fixed_t
---
---@field scrollable boolean
---@field viewLeft   fixed_t
---@field viewTop    fixed_t
---
---@field style         ljgui.ItemStyle
---@field styleRules    ljgui.ItemStyle
---@field defaultStyle  ljgui.ItemStyle
local Item = gui.class()
gui.Item = Item

--#endregion

--#region static variables

Item.defaultWidth = 0
Item.defaultHeight = 0
Item.defaultStyle = {}

--#endregion

--#region methods

function Item:__init()
	self.depth = 0
	self.layoutGenerated = true
	self.modifiedAttributes = {}
	self.attributeRootDistances = {}

	self.children = gui.ItemList()
	self.rooted = false

	self.left, self.top = 0, 0
	self.cachedLeft, self.cachedTop = 0, 0

	self.width, self.height = self.defaultWidth, self.defaultHeight
	self.contentWidth, self.contentHeight = self.width, self.height

	self.scrollable = false
	self.viewLeft, self.viewTop = 0, 0
end

---@param props? ljgui.ItemProps
function Item:build(props)
	gui.applyItemProps(self, props)
end

---@param props? ljgui.ItemProps
function Item:applyProps(props)
	gui.applyItemProps(self, props)
end

-- function Item:unsetLayoutGenerated()
-- 	if self.layoutGenerated then
-- 		self.layoutGenerated = false
-- 		table.insert(gui.instance.itemLayoutsToGenerate, self)
-- 	end
-- end

---@param attributeName string
function Item:markAttributeAsModified(attributeName)
	if self.rooted then
		gui.instance.itemsWithModifiedAttributes[self] = true
	end
	self.modifiedAttributes[attributeName] = true
end

---@param x fixed_t
---@param y fixed_t
---@return boolean
function Item:isPointInside(x, y)
	local l = self.cachedLeft
	if x < l or x >= l + self.width then
		return false
	end

	local t = self.cachedTop
	if y < t or y >= t + self.height then
		return false
	end

	return true
end

---@param rules ljgui.LayoutRules
function Item:setLayoutRules(rules)
	gui.parseLayoutRules(rules)
	self.layoutRules = rules
end

---@param rules ljgui.LayoutRules
function Item:updateLayoutRules(rules)
	gui.parseLayoutRules(rules)
	self.layoutRules = gui.merge(self.layoutRules or {}, rules)
	gui.parseLayoutRules(self.layoutRules)
end

---@param style ljgui.ItemStyle
function Item:setStyle(style)
	self.style = style
end

---@param style ljgui.ItemStyle
function Item:updateStyle(style)
	self.style = gui.merge(self.style, style)
end

---@param rules table
function Item:setStyleRules(rules)
	self.styleRules = rules
end

function Item:update()
end

---@param v videolib
function Item:drawChildren(v)
	local l, t = self.cachedLeft, self.cachedTop
	if gui.pushDrawRegion(v, l, t, l + self.width, t + self.height) then
		for _, child in self.children:iterate() do
			child:draw(v)
		end

		gui.popDrawRegion()
	end
end

---@param v videolib
function Item:draw(v)
end

--#endregion

--#region item tree methods

---@param parent any
---@return ljgui.Item
function Item:attach(parent)
	self.parent = parent
	parent.children:add(self)
	self:setRooted(parent.rooted)

	self:cachePosition()

	return self
end

function Item:detach()
	self:setRooted(false)

	self.parent.children:remove(self)
	self.parent = nil
end

---@param rooted boolean
function Item:setRooted(rooted)
	if self.rooted == rooted then return end

	if rooted then
		self.rooted = rooted

		self:markAttributeAsModified("rooted")
		gui.instance.eventManager:attachItemEvents(self)

		self:update()

		-- !!! Experimental
		gui.instance.eventManager:callItemEvent(self, "Root")
	else
		-- !!! Experimental
		gui.instance.eventManager:callItemEvent(self, "Unroot")

		self.rooted = rooted

		gui.instance.itemsWithModifiedAttributes[self] = nil
		gui.instance.eventManager:detachItemEvents(self)
	end

	for _, child in self.children:iterate() do
		child:setRooted(rooted)
	end
end

--#endregion

--#region position/size methods

---@param left fixed_t
---@param top fixed_t
function Item:move(left, top)
	if left == nil then
		left = self.left
	end
	if top == nil then
		top = self.top
	end

	if left == self.left and top == self.top then return end

	self:moveRaw(left, top)

	if left ~= self.left then
		self:markAttributeAsModified("left")
	end
	if top ~= self.top then
		self:markAttributeAsModified("top")
	end
	-- self:markAttributeAsModified("position")
end

---@param left fixed_t
---@param top fixed_t
function Item:moveRaw(left, top)
	if left == nil then
		left = self.left
	end
	if top == nil then
		top = self.top
	end

	if left == self.left and top == self.top then return end

	self.left = left
	self.top = top

	self:cachePosition()
end

---@param width fixed_t
---@param height fixed_t
function Item:resize(width, height)
	if width == nil then
		width = self.width
	end
	if height == nil then
		height = self.height
	end

	if width == self.width and height == self.height then return end

	if width ~= self.width then
		self:markAttributeAsModified("width")
	end
	if height ~= self.height then
		self:markAttributeAsModified("height")
	end

	self:resizeRaw(width, height)
end

---@param width fixed_t
---@param height fixed_t
function Item:resizeRaw(width, height)
	if width == nil then
		width = self.width
	end
	if height == nil then
		height = self.height
	end

	if width == self.width and height == self.height then return end

	self.width = width
	self.height = height

	if not self.scrollable then
		self.contentWidth = width
		self.contentHeight = height
	end
end

---@param width? fixed_t
---@param height? fixed_t
function Item:resizeContent(width, height)
	self.scrollable = true

	if width == nil then
		width = self.contentWidth
	end
	if height == nil then
		height = self.contentHeight
	end

	if width == self.contentWidth and height == self.contentHeight then return end

	if width ~= self.contentWidth then
		self:markAttributeAsModified("contentWidth")
	end
	if height ~= self.contentHeight then
		self:markAttributeAsModified("contentHeight")
	end

	self:resizeContentRaw(width, height)
end

---@param width? fixed_t
---@param height? fixed_t
function Item:resizeContentRaw(width, height)
	if width == nil then
		width = self.contentWidth
	end
	if height == nil then
		height = self.contentHeight
	end

	if width == self.contentWidth and height == self.contentHeight then return end

	self.contentWidth = width
	self.contentHeight = height
end

---@param left fixed_t
---@param top fixed_t
function Item:moveView(left, top)
	if left == nil then
		left = self.viewLeft
	end
	if top == nil then
		top = self.viewTop
	end

	if left == self.viewLeft and top == self.viewTop then return end

	self.viewLeft = left
	self.viewTop = top

	self:cachePosition()
end

function Item:cachePosition()
	local parent = self.parent

	if parent then
		self.cachedLeft = parent.cachedLeft - parent.viewLeft + self.left
		self.cachedTop = parent.cachedTop - parent.viewTop + self.top
	else
		self.cachedLeft = self.left
		self.cachedTop = self.top
	end

	for _, child in self.children:iterate() do
		child:cachePosition()
	end
end

--#endregion

--#region event methods

---@param eventType string
---@param callback function
function Item:addEvent(eventType, callback)
	gui.instance.eventManager:addItemEvent(self, eventType, callback)
end

---@param eventType string
---@param callback? function
function Item:removeEvent(eventType, callback)
	gui.instance.eventManager:removeItemEvent(self, eventType, callback)
end

function Item:prioritiseMouseEvents()
	self.mouseEventsPrioritised = true
end

function Item:focus()
	gui.instance.eventManager.focusedItem = self
end

function Item:unfocus()
	local manager = gui.instance.eventManager
	if self == manager.focusedItem then
		manager.focusedItem = nil
	end
end

---@param self ljgui.Item
---@return boolean
gui.getter(Item, "focused", function(self)
	return (gui.instance.eventManager.focusedItem == self)
end)

--#endregion

--#region debugging methods

local fixedFields = gui.arrayToSet{
	"left", "top",
	"cachedLeft", "cachedTop",

	"width", "height",
	"contentWidth", "contentHeight",
}

function Item:dump(text, prefix)
	local pr = pr or print

	text = $ or "item"
	prefix = $ or ""

	pr(prefix .. text .. " = {")

	for k, v in pairs(self) do
		if type(v) == "string" then
			pr(prefix .. "    " .. tostring(k) .. ' = "' .. v .. '"')
		elseif fixedFields[k] then
			pr(prefix .. "    " .. tostring(k) .. " = " .. gui.dec(v))
		else
			pr(prefix .. "    " .. tostring(k) .. " = " .. tostring(v))
		end
	end

	for _, child in self.children:iterate() do
		child:dump("child", prefix .. "    ")
	end

	pr(prefix .. "}")
end

function Item:dumpInfo()
	(pr or print)("[Item] " .. (self.id or "?") .. ": ".. (self.debug or "?"))
end

function Item:dumpPos()
	pr(dec(self.left) .. " " .. dec(self.top))
end

function Item:dumpSize()
	pr(dec(self.width) .. " " .. dec(self.height))
end

--#endregion
