-- ---@class ljgui
-- local gui = ljrequire "ljgui.common"


-- ---@alias ljgui.ItemAttributePair { [1]: ljgui.Item, [2]: string }


-- ---@class ljgui.DependencyManager
-- ---@field dependencies ljgui.Table2D<ljgui.Item, string, ljgui.ItemAttributePair[]>
-- ---@field dependents ljgui.Table2D<ljgui.Item, string, ljgui.ItemAttributePair[]>
-- ---@field computationCallbacks ljgui.Set2D<ljgui.Item, string>
-- ---@field dirtyPool ljgui.Set2D<ljgui.Item, string>
-- ---@field modifiedAttributes ljgui.Set2D<ljgui.Item, string>
-- local Manager, base = gui.class()
-- gui.DependencyManager = Manager


-- ---@param t ljgui.Table2D
-- ---@param k1 any
-- ---@param k2 any
-- ---@param v any
-- local function insertIn2DTable(t, k1, k2, v)
-- 	local v1 = t[k1]
-- 	if not v1 then
-- 		v1 = {}
-- 		t[k1] = v1
-- 	end

-- 	local v2 = v1[k2]
-- 	if not v2 then
-- 		v2 = {}
-- 		v1[k2] = v2
-- 	end

-- 	v2[#v2 + 1] = v
-- end


-- function Manager:__init()
-- 	self.dependencies = setmetatable({}, { __mode = "k" })
-- 	self.dependents = setmetatable({}, { __mode = "k" })
-- 	self.computationCallbacks = setmetatable({}, { __mode = "k" })
-- 	self.dirtyPool = setmetatable({}, { __mode = "k" })
-- 	self.modifiedAttributes = setmetatable({}, { __mode = "k" })
-- end

-- ---@param dependencyItem ljgui.Item
-- ---@param dependencyAttribute string
-- ---@param dependentItem ljgui.Item
-- ---@param dependentAttribute string
-- function Manager:addDependency(dependencyItem, dependencyAttribute, dependentItem, dependentAttribute)
-- 	insertIn2DTable(self.dependencies, dependentItem, dependentAttribute, { dependencyItem, dependencyAttribute })
-- 	insertIn2DTable(self.dependents, dependencyItem, dependencyAttribute, { dependentItem, dependentAttribute })

-- 	self.dirtyPool[dependentItem] = $ or {}
-- end

-- ---@param dependencyItem ljgui.Item
-- ---@param dependencyAttribute string
-- ---@param dependentItem ljgui.Item
-- ---@param dependentAttribute string
-- function Manager:removeDependency(dependencyItem, dependencyAttribute, dependentItem, dependentAttribute)
-- 	local deps = self.dependencies[dependentItem][dependentAttribute]

-- 	for i = 1, #deps do
-- 		local dep = deps[i]
-- 		if dep[1] == dependentItem and dep[2] == dependentAttribute then
-- 			gui.removeIndexFromUnorderedArray(deps, i)
-- 			break
-- 		end
-- 	end
-- end

-- ---@param item ljgui.Item
-- ---@param attribute string
-- ---@param callback fun(item: ljgui.Item, attribute: string)
-- function Manager:setComputationCallback(item, attribute, callback)
-- 	self.computationCallbacks[item] = $ or {}
-- 	self.computationCallbacks[item][attribute] = $ or {}
-- 	self.computationCallbacks[item][attribute] = callback
-- end

-- ---@param manager ljgui.DependencyManager
-- ---@return ljgui.Set2D<ljgui.Item, string>
-- local function propagate(manager)
-- 	local allDeps = manager.dependents
-- 	local dirtyAttrsPool = manager.dirtyPool

-- 	local dirtyAttrs = {}

-- 	-- Stack
-- 	local size = 0
-- 	local items = {}
-- 	local attrs = {}

-- 	for item, modifiedAttributes_item in pairs(manager.modifiedAttributes) do
-- 		for attr in pairs(modifiedAttributes_item) do
-- 			-- Push
-- 			size = size + 1
-- 			items[size] = item
-- 			attrs[size] = attr
-- 		end
-- 	end

-- 	while size > 0 do
-- 		-- Pop
-- 		local item, attr = items[size], attrs[size]
-- 		size = size - 1

-- 		local allDeps_item = allDeps[item]
-- 		if allDeps_item and allDeps_item[attr] then
-- 			local deps = allDeps_item[attr]
-- 			for i = 1, #deps do
-- 				local dep = deps[i]
-- 				local depItem = dep[1]
-- 				local depAttr = dep[2]

-- 				local dirtyAttrs_depItem = dirtyAttrs[depItem]
-- 				if not (dirtyAttrs_depItem and dirtyAttrs_depItem[depAttr]) then
-- 					-- Add to set
-- 					if not dirtyAttrs_depItem then
-- 						dirtyAttrs_depItem = dirtyAttrsPool[depItem]
-- 						dirtyAttrs[depItem] = dirtyAttrs_depItem
-- 					end
-- 					dirtyAttrs_depItem[depAttr] = true

-- 					-- Push
-- 					size = size + 1
-- 					items[size] = depItem
-- 					attrs[size] = depAttr
-- 				end
-- 			end
-- 		end
-- 	end

-- 	return dirtyAttrs
-- end

-- ---@param manager ljgui.DependencyManager
-- ---@param dirtyAttrs ljgui.Set2D<ljgui.Item, string>
-- local function compute(manager, dirtyAttrs)
-- 	local allDeps = manager.dependencies
-- 	local computationCallbacks = manager.computationCallbacks

-- 	-- Stack
-- 	local traversalStack_size = 0
-- 	local traversalStack_item = {}
-- 	local traversalStack_attr = {}

-- 	-- Array
-- 	local sortedAttrs_size = 0
-- 	local sortedAttrs_item = {}
-- 	local sortedAttrs_attr = {}

-- 	while true do
-- 		-- Pick from set
-- 		local firstItem, dirtyAttrs_firstItem = next(dirtyAttrs)
-- 		if not firstItem then break end
-- 		local firstAttr = next(dirtyAttrs_firstItem)
-- 		if not firstAttr then break end

-- 		-- Push
-- 		traversalStack_size = 1
-- 		traversalStack_item[traversalStack_size] = firstItem
-- 		traversalStack_attr[traversalStack_size] = firstAttr

-- 		-- Recursively push to the stack all dirty dependencies for the current chain
-- 		while traversalStack_size > 0 do
-- 			-- Pop
-- 			local item = traversalStack_item[traversalStack_size]
-- 			local attr = traversalStack_attr[traversalStack_size]
-- 			traversalStack_size = traversalStack_size - 1

-- 			-- Push
-- 			sortedAttrs_size = sortedAttrs_size + 1
-- 			sortedAttrs_item[sortedAttrs_size] = item
-- 			sortedAttrs_attr[sortedAttrs_size] = attr

-- 			-- Remove from set
-- 			dirtyAttrs[item][attr] = nil
-- 			-- if not next(dirtyAttrs[item]) then
-- 			-- 	dirtyAttrs[item] = nil
-- 			-- end

-- 			-- Push to the stack all dirty dependencies of the current node
-- 			local allDeps_item = allDeps[item]
-- 			if allDeps_item and allDeps_item[attr] then
-- 				local deps = allDeps_item[attr]
-- 				for i = 1, #deps do
-- 					local dep = deps[i]
-- 					local depItem = dep[1]
-- 					local depAttr = dep[2]

-- 					local dirtyAttrs_depItem = dirtyAttrs[depItem]
-- 					if dirtyAttrs_depItem and dirtyAttrs_depItem[depAttr] then
-- 						-- Push
-- 						traversalStack_size = traversalStack_size + 1
-- 						traversalStack_item[traversalStack_size] = depItem
-- 						traversalStack_attr[traversalStack_size] = depAttr
-- 					end
-- 				end
-- 			end
-- 		end

-- 		for i = sortedAttrs_size, 1, -1 do
-- 			local item, attr = sortedAttrs_item[i], sortedAttrs_attr[i]

-- 			local computationCallbacksForItem = computationCallbacks[item]
-- 			if computationCallbacksForItem and computationCallbacksForItem[attr] then
-- 				computationCallbacksForItem[attr](item)
-- 			end
-- 		end
-- 	end
-- end

-- -- NOTE:
-- --
-- -- High-level pseudo-code for the algorithm used above
-- -- This is essentially a DAG with item/attribute pairs as the nodes,
-- -- traversed recursively using a stack to avoid function calls.
-- -- Cycles result in undefined computation order but will not cause infinite loops.

-- --[[
-- local function propagate(manager)
-- 	local dirtyAttrs = {}
-- 	local attrs = Stack()

-- 	for attr in pairs(manager.modifiedAttributes) do
-- 		attrs:push(attr)
-- 	end

-- 	while not attrs.empty do
-- 		local attr = attrs:pop()

-- 		for dep in manager.dependents[attr] do
-- 			if not dirtyAttrs:has(depAttr) then
-- 				dirtyAttrs:add(depAttr)
-- 				attrs:push(depAttr)
-- 			end
-- 		end
-- 	end

-- 	return dirtyAttrs
-- end

-- local function compute(attrDeps, dirtyAttrs)
-- 	local traversalStack = Stack()
-- 	local sortedAttrs = Array()

-- 	while not dirtyAttrs.empty do
-- 		traversalStack:push(dirtyAttrs.first)

-- 		while not traversalStack.empty do
-- 			local attr = traversalStack:pop()

-- 			sortedAttrs:push(attr)
-- 			dirtyAttrs:remove(attr)

-- 			for dep in attrDeps[attr] do
-- 				if dirtyAttrs:has(dep) then
-- 					traversalStack:push(dep)
-- 				end
-- 			end
-- 		end

-- 		while not sortedAttrs.empty do
-- 			local attr = sortedAttrs:pop()
-- 			computeAttribute(attr)
-- 		end
-- 	end
-- end
-- ]]

-- function Manager:propagateModifiedAttributes()
-- 	compute(self, propagate(self))
-- 	self.modifiedAttributes = {}
-- end

-- function Manager:dumpDependencyGraph()
-- 	for dependentItem, dependentAttrs in pairs(self.dependencies) do
-- 		for dependentAttr, dependencies in pairs(dependentAttrs) do
-- 			for _, dependency in ipairs(dependencies) do
-- 				local dependencyName = tostring(dependency[1])
-- 				local dependentName = tostring(dependentItem)
-- 				print(("%s.%s -> %s.%s"):format(dependencyName, dependency[2], dependentName, dependentAttr))
-- 			end
-- 		end
-- 	end

-- 	print()
-- end
