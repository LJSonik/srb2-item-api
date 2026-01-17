---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.AutoAttribute
---@field strategy string


---@class ljgui.AutoAttributeStrategy
---@field id string
---@field params? string[]
---@field compute fun(item: ljgui.Item)
---
---@field dependencyType "parent"|"children"
---@field dependencies? table[]
---@field dependency?   table


---@class ljgui.AutoPositionStrategy
---@field dependencyType "parent"|"children"
---@field params? string[]
---@field compute fun(item: ljgui.Item): fixed_t, fixed_t
---
---@field leftDependencies? table[]
---@field leftDependency?   table
---@field topDependencies?  table[]
---@field topDependency?    table


---@class ljgui.AutoSizeStrategy
---@field dependencyType "parent"|"children"
---@field params? string[]
---@field compute fun(item: ljgui.Item): fixed_t, fixed_t
---
---@field widthDependencies?  table[]
---@field widthDependency?    table
---@field heightDependencies? table[]
---@field heightDependency?   table


---@type ljgui.Table2D<string, string, ljgui.AutoAttributeStrategy>
gui.autoAttributeStrategies = {}


---@param id string
---@param attribute string
---@param strategy ljgui.AutoAttributeStrategy
function gui.addAutoStrategy(id, attribute, strategy)
	gui.autoAttributeStrategies[attribute] = $ or {}
	if id then
		strategy.id = id
		gui.autoAttributeStrategies[attribute][id] = strategy
	else
		gui.autoAttributeStrategies[attribute][strategy] = strategy
	end

	strategy.dependencies = $ or { strategy.dependency }
	strategy.params = $ or {}

	return strategy
end

---@param id string
---@param strategy ljgui.AutoPositionStrategy
function gui.addAutoPositionStrategy(id, strategy)
	local leftStrategy = {
		dependencyType = strategy.dependencyType,
		dependencies = strategy.leftDependencies,
		dependency = strategy.leftDependency,

		params = strategy.params,

		compute = function(item)
			local l, _ = strategy.compute(item)
			item:moveRaw(l, nil)
		end
	}

	local topStrategy = {
		dependencyType = strategy.dependencyType,
		dependencies = strategy.topDependencies,
		dependency = strategy.topDependency,

		params = strategy.params,

		compute = function(item)
			local _, t = strategy.compute(item)
			item:moveRaw(nil, t)
		end
	}

	return
		gui.addAutoStrategy(id, "left", leftStrategy),
		gui.addAutoStrategy(id, "top", topStrategy)
end

---@param id string
---@param strategy ljgui.AutoSizeStrategy
function gui.addAutoSizeStrategy(id, strategy)
	local widthStrategy = {
		dependencyType = strategy.dependencyType,
		dependencies = strategy.widthDependencies,
		dependency = strategy.widthDependency,

		params = strategy.params,

		compute = function(item)
			local w, _ = strategy.compute(item)
			item:resizeRaw(w, nil)
		end
	}

	local heightStrategy = {
		dependencyType = strategy.dependencyType,
		dependencies = strategy.heightDependencies,
		dependency = strategy.heightDependency,

		params = strategy.params,

		compute = function(item)
			local _, h = strategy.compute(item)
			item:resizeRaw(nil, h)
		end
	}

	return
		gui.addAutoStrategy(id, "width", widthStrategy),
		gui.addAutoStrategy(id, "height", heightStrategy)
end

---@param methodName string
---@param dependencyType string
---@param dependencyAttr string
---@param dependentItem ljgui.Item
---@param dependentAttr string
---@param dependencyChild? ljgui.Item
local function addOrRemoveAutoAttributeDependencies(methodName, dependencyType, dependencyAttr, dependentItem, dependentAttr, dependencyChild)
	local manager = gui.instance.dependencyManager
	local method = manager[methodName]

	if dependencyType == "self" then
		method(manager, dependentItem, dependencyAttr, dependentItem, dependentAttr)
	elseif dependencyType == "parent" then
		if dependentItem.parent then
			method(manager, dependentItem.parent, dependencyAttr, dependentItem, dependentAttr)
		end
	elseif dependencyType == "children" then
		if dependencyChild then
			method(manager, dependencyChild, dependencyAttr, dependentItem, dependentAttr)
		else
			for _, child in dependentItem.children:iterate() do
				method(manager, child, dependencyAttr, dependentItem, dependentAttr)
			end
		end
	end
end

---@param item ljgui.Item
---@param attribute string
---@param value? ljgui.AutoAttribute|string
function gui.setItemAutoAttribute(item, attribute, value)
	if type(value) == "string" then
		value = { strategy = value }
	end

	if item.rooted then
		gui.updateAutoAttributeDependenciesBeforeUnrootingItem(item, attribute)
	end

	item.autoAttributes[attribute] = value

	if item.rooted then
		gui.updateAutoAttributeDependenciesAfterRootingItem(item, attribute)
	end
end

---@param child ljgui.Item
function gui.updateAutoAttributeDependenciesAfterAttachingChild(child)
	local manager = gui.instance.dependencyManager

	for attr, autoAttr in pairs(child.autoAttributes) do
		local strategy = gui.autoAttributeStrategies[attr][autoAttr.strategy]

		if strategy.dependencyType == "parent" then
			for _, dep in ipairs(strategy.dependencies) do
				addOrRemoveAutoAttributeDependencies("addDependency", dep[1], dep[2], child, attr, child)
			end
		end

		manager:markAttributeForComputation(child, attr)
	end

	for attr, autoAttr in pairs(child.parent.autoAttributes) do
		local strategy = gui.autoAttributeStrategies[attr][autoAttr.strategy]

		if strategy.dependencyType == "children" then
			for _, dep in ipairs(strategy.dependencies) do
				addOrRemoveAutoAttributeDependencies("addDependency", dep[1], dep[2], child, attr, child)
			end
		end

		manager:markAttributeForComputation(child, attr)
	end
end

---@param child ljgui.Item
function gui.updateAutoAttributeDependenciesBeforeDetachingChild(child)
	for attr, autoAttr in pairs(child.autoAttributes) do
		local strategy = gui.autoAttributeStrategies[attr][autoAttr.strategy]

		if strategy.dependencyType == "parent" then
			for _, dep in ipairs(strategy.dependencies) do
				addOrRemoveAutoAttributeDependencies("removeDependency", dep[1], dep[2], child, attr, child)
			end
		end
	end

	for attr, autoAttr in pairs(child.parent.autoAttributes) do
		local strategy = gui.autoAttributeStrategies[attr][autoAttr.strategy]

		if strategy.dependencyType == "children" then
			for _, dep in ipairs(strategy.dependencies) do
				addOrRemoveAutoAttributeDependencies("removeDependency", dep[1], dep[2], child, attr, child)
			end
		end
	end
end

---@param item ljgui.Item
---@param attribute string
function gui.updateAutoAttributeDependenciesAfterRootingItem(item, attribute)
	local value = item.autoAttributes[attribute]
	if not value then return end

	local strategy = gui.autoAttributeStrategies[attribute][value.strategy]

	for _, dep in ipairs(strategy.dependencies) do
		addOrRemoveAutoAttributeDependencies("addDependency", dep[1], dep[2], item, attribute, nil)
	end

	gui.instance.dependencyManager:setComputationCallback(item, attribute, strategy.compute)
	gui.instance.dependencyManager:markAttributeForComputation(item, attribute)
end

---@param item ljgui.Item
---@param attribute string
function gui.updateAutoAttributeDependenciesBeforeUnrootingItem(item, attribute)
	local value = item.autoAttributes[attribute]
	if not value then return end

	local strategy = gui.autoAttributeStrategies[attribute][value.strategy]

	for _, dep in ipairs(strategy.dependencies) do
		addOrRemoveAutoAttributeDependencies("removeDependency", dep[1], dep[2], item, attribute, nil)
	end

	gui.instance.dependencyManager:setComputationCallback(item, attribute, nil)
end
