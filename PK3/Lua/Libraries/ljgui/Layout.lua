---@class ljgui
local gui = ljrequire "ljgui.common"


---@alias ljgui.BaseBorderGetter fun(item: ljgui.Item): fixed_t, fixed_t, fixed_t, fixed_t


---@class ljgui.Layout
---@field strategy string


---@class ljgui.LayoutRules
-- ---@field placementMode? "include"|"exclude"|"placeholder"
-- ---@field fitParent?     boolean
---
---@field leftMargin?   fixed_t
---@field topMargin?    fixed_t
---@field rightMargin?  fixed_t
---@field bottomMargin? fixed_t
---@field margin?       fixed_t
---
---@field leftPadding?   fixed_t
---@field topPadding?    fixed_t
---@field rightPadding?  fixed_t
---@field bottomPadding? fixed_t
---@field padding?       fixed_t


---@class ljgui.LayoutStrategy
---@field id string
---@field params? string[]
---@field compute fun(item: ljgui.Item)
---
---@field dependencies? table[]
---@field dependency?   table


---@type { [string|ljgui.LayoutStrategy]: ljgui.LayoutStrategy }
gui.layoutStrategies = {}


---@param item ljgui.Item
function gui.getDefaultBaseBorder(item)
	local bdSize = item.style.bdSize or 0
	return bdSize, bdSize, bdSize, bdSize
end

---@param rules ljgui.LayoutRules
function gui.parseLayoutRules(rules)
	rules.placementMode = $ or "include"

	rules.leftMargin = $ or 0
	rules.topMargin = $ or 0
	rules.rightMargin = $ or 0
	rules.bottomMargin = $ or 0

	rules.leftPadding = $ or 0
	rules.topPadding = $ or 0
	rules.rightPadding = $ or 0
	rules.bottomPadding = $ or 0
end

---@param id string
---@param strategy ljgui.LayoutStrategy
---@return ljgui.LayoutStrategy
function gui.addLayoutStrategy(id, strategy)
	if id then
		strategy.id = id
		gui.layoutStrategies[id] = strategy
	else
		gui.layoutStrategies[strategy] = strategy
	end

	strategy.dependencies = $ or { strategy.dependency }
	strategy.params = $ or {}

	return strategy
end

---@param methodName string
---@param item ljgui.Item
local function addOrRemoveLayoutDependencies(methodName, item)
	local strategy = gui.layoutStrategies[item.layout.strategy]
	local manager = gui.instance.dependencyManager
	local method = manager[methodName]

	for _, dep in ipairs(strategy.dependencies) do
		if dep[1] == "self" then
			method(manager, item, dep[2], item, "layout")
		elseif dep[1] == "children" then
			for _, child in item.children:iterate() do
				method(manager, child, dep[2], item, "layout")
			end
		end
	end

	for _, child in item.children:iterate() do
		method(manager, item, "layout", child, "left")
		method(manager, item, "layout", child, "top")
	end
end

---@param item ljgui.Item
---@param layout? ljgui.Layout|string
function gui.setItemLayout(item, layout)
	if type(layout) == "string" then
		layout = { strategy = layout }
	end

	if item.rooted then
		gui.updateLayoutDependenciesBeforeUnrootingItem(item)
	end

	item.layout = layout

	if item.rooted then
		gui.updateLayoutDependenciesAfterRootingItem(item)
	end
end

---@param child ljgui.Item
function gui.updateLayoutDependenciesAfterAttachingChild(child)
	local parent = child.parent
	if not parent.layout then return end

	local strategy = gui.layoutStrategies[parent.layout.strategy]
	local manager = gui.instance.dependencyManager

	for _, dep in ipairs(strategy.dependencies) do
		if dep[1] == "self" then
			manager:addDependency(parent, dep[2], parent, "layout")
		elseif dep[1] == "children" then
			manager:addDependency(child, dep[2], parent, "layout")
		end
	end

	manager:addDependency(parent, "layout", child, "left")
	manager:addDependency(parent, "layout", child, "top")

	manager:markAttributeForComputation(parent, "layout")
end

---@param child ljgui.Item
function gui.updateLayoutDependenciesBeforeDetachingChild(child)
	local parent = child.parent
	if not parent.layout then return end

	local strategy = gui.layoutStrategies[parent.layout.strategy]
	local manager = gui.instance.dependencyManager

	for _, dep in ipairs(strategy.dependencies) do
		if dep[1] == "self" then
			manager:removeDependency(parent, dep[2], parent, "layout")
		elseif dep[1] == "children" then
			manager:removeDependency(child, dep[2], parent, "layout")
		end
	end

	manager:removeDependency(parent, "layout", child, "left")
	manager:removeDependency(parent, "layout", child, "top")
end

---@param item ljgui.Item
function gui.updateLayoutDependenciesAfterRootingItem(item)
	if not item.layout then return end

	addOrRemoveLayoutDependencies("addDependency", item)

	-- This will calculate the new positions for all the children at once
	local strategy = gui.layoutStrategies[item.layout.strategy]
	gui.instance.dependencyManager:setComputationCallback(item, "layout", strategy.compute)
	gui.instance.dependencyManager:markAttributeForComputation(item, "layout")
end

---@param item ljgui.Item
function gui.updateLayoutDependenciesBeforeUnrootingItem(item)
	if not item.layout then return end

	addOrRemoveLayoutDependencies("removeDependency", item)
	gui.instance.dependencyManager:setComputationCallback(item, "layout", nil)
end
