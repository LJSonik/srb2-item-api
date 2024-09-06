---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.ListBox : ljgui.Item
---@field grid ljgui.Grid
---@field maxHeight? fixed_t
local ListBox, base = gui.class(gui.Item)
gui.ListBox = ListBox


---@type ljgui.ItemStyle
ListBox.defaultStyle = {
	bgColor = 31
}

---@type ljgui.ItemStyle
local elementStyle = {
	bgColor = nil,
	pointed = { bgColor = 16 },
	pressed = { bgColor = 0 }
}


---@param element ljgui.Button
local function onElementTrigger(element)
	local list = element.parent.parent
	gui.instance.eventManager:callItemEvent(list, "Change", element.value)
end

---@param grid ljgui.Item
---@param oldElem ljgui.Button
---@param newElem ljgui.Button
local function onNavigation(grid, oldElem, newElem)
	if oldElem then
		oldElem.pointed = false -- !!!
	end

	if newElem then
		newElem.pointed = true -- !!!
	end
end

---@param props ljgui.ItemProps
function ListBox:__init(props)
	base.__init(self)

	self.debug = "ListBox"
	self.options = {}

	if props then
		self:build(props)
		self.options = props.options or $
	end

	local children = {}
	for _, option in ipairs(self.options) do
		table.insert(children, gui.Button {
			text = option[2],
			var_value = option[1],
			autoWidth = "FitParent",
			height = 6*FU,
			style = elementStyle,
			onTrigger = onElementTrigger
		})
	end

	self.grid = gui.Grid {
		fitParent = true,
		autoLayout = "Grid",
		gridColumns = 1,

		children = children
	}
	-- self.grid:attach(self)

	gui.applyItemProps(self, {
		self.grid,
		gui.VerticalScrollbar {
			target = self.grid,

			autoHeight = "FitParent",
			autoLeft = "SnapToParentRight"
		}
	})

	self:setMaxHeight(self.maxHeight)
	gui.addKeyboardNavigationToGrid(self.grid, onNavigation)
end

---@param height fixed_t
function ListBox:setMaxHeight(height)
	self.maxHeight = height
	self:resize(nil, min(#self.grid.children.items * 8*FU, height or UINT32_MAX))
end

function ListBox:draw(v)
	gui.drawBaseItemStyle(v, self, self.style)
	self:drawChildren(v)
end


---@param item ljgui.Item
---@param container ljgui.Item
---@param props ljgui.ItemProps
---@return ljgui.ListBox
function gui.spawnListBoxAtItem(item, container, props)
	---@type ljgui.ListBox
	local list = gui.ListBox(props)
	list:resize(item.width, nil)
	list:updateLayoutRules{ placementMode = "exclude" }
	list:move(item.cachedLeft - container.cachedLeft, item.cachedTop + item.height - container.cachedTop)
	list:setMaxHeight(container.height - list.top)
	list:attach(container)

	return list
end
