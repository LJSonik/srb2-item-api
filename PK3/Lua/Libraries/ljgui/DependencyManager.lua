---@class ljgui
local gui = ljrequire "ljgui.common"


---@alias ljgui.DependencyNode { [1]: ljgui.Item, [2]: string }


---@class ljgui.DependencyManager
---@field nodes          ljgui.Table2D<ljgui.Item, string, ljgui.DependencyNode>
---@field modifiedNodes  ljgui.Set<ljgui.DependencyNode>
---@field nodesToCompute ljgui.Set<ljgui.DependencyNode>
---
---@field dependencies table<ljgui.DependencyNode, ljgui.DependencyNode[]>
---@field dependents   table<ljgui.DependencyNode, ljgui.DependencyNode[]>
---
---@field computationCallbacks table<ljgui.DependencyNode>
local Manager, base = gui.class()
gui.DependencyManager = Manager


-- local weakKeyMetatable = { __mode="k" }

-- local function setWeakKeyMetatable(t)
-- 	return setmetatable(t, weakKeyMetatable)
-- end

-- local weakValueMetatable = { __mode="v" }

-- local function setWeakValueMetatable(t)
-- 	return setmetatable(t, weakValueMetatable)
-- end

function Manager:__init()
	-- self.nodes                = setWeakKeyMetatable({})
	-- self.dependencies         = setWeakKeyMetatable({})
	-- self.dependents           = setWeakKeyMetatable({})
	-- self.computationCallbacks = setWeakKeyMetatable({})
	-- self.modifiedNodes        = setWeakKeyMetatable({})
	-- self.nodesToCompute       = setWeakKeyMetatable({})

	self.nodes = {}
	self.dependencies = {}
	self.dependents = {}
	self.computationCallbacks = {}
	self.modifiedNodes = {}
	self.nodesToCompute = {}
end

---@protected
---@param item ljgui.Item
---@param attribute string
function Manager:getNode(item, attribute)
	local nodesByAttr = self.nodes[item]
	if not nodesByAttr then
		nodesByAttr = {}
		-- nodesByAttr = setWeakValueMetatable({})
		self.nodes[item] = nodesByAttr
	end

	local node = nodesByAttr[attribute]
	if not node then
		node = { item, attribute }
		-- node = setWeakValueMetatable({ item, attribute })
		nodesByAttr[attribute] = node
	end

	return node
end

---@param dependencyItem ljgui.Item
---@param dependencyAttribute string
---@param dependentItem ljgui.Item
---@param dependentAttribute string
function Manager:addDependency(dependencyItem, dependencyAttribute, dependentItem, dependentAttribute)
	local dependencyNode = self:getNode(dependencyItem, dependencyAttribute)
	local dependentNode = self:getNode(dependentItem, dependentAttribute)

	self.dependencies[dependentNode] = $ or {}
	self.dependents[dependencyNode] = $ or {}

	table.insert(self.dependencies[dependentNode], dependencyNode)
	table.insert(self.dependents[dependencyNode], dependentNode)
end

---@param dependencyItem ljgui.Item
---@param dependencyAttribute string
---@param dependentItem ljgui.Item
---@param dependentAttribute string
function Manager:removeDependency(dependencyItem, dependencyAttribute, dependentItem, dependentAttribute)
	local dependencyNode = self:getNode(dependencyItem, dependencyAttribute)
	local dependentNode = self:getNode(dependentItem, dependentAttribute)

	gui.removeValueFromUnorderedArray(self.dependencies[dependentNode], self:getNode(dependencyItem, dependencyAttribute))
	gui.removeValueFromUnorderedArray(self.dependents[dependencyNode], self:getNode(dependentItem, dependentAttribute))
end

---@param item ljgui.Item
---@param attribute string
---@param callback fun(item: ljgui.Item, attribute: string)
function Manager:setComputationCallback(item, attribute, callback)
	local node = self:getNode(item, attribute)
	self.computationCallbacks[node] = callback
end

---@param item ljgui.Item
---@param attribute string
function Manager:markAttributeAsModified(item, attribute)
	local node = self:getNode(item, attribute)
	self.modifiedNodes[node] = true
end

---@param item ljgui.Item
---@param attribute string
function Manager:markAttributeForComputation(item, attribute)
	local node = self:getNode(item, attribute)
	self.nodesToCompute[node] = true
end

---@protected
---@param dependents table<string, ljgui.DependencyNode[]>
---@param modifiedNodes ljgui.Set<ljgui.DependencyNode>
---@param nodesToCompute ljgui.Set<ljgui.DependencyNode>
---@return ljgui.Set<ljgui.DependencyNode>
local function propagate(dependents, modifiedNodes, nodesToCompute)
	---@type ljgui.Set<ljgui.DependencyNode>
	local dirtyNodes = {}

	-- Stack
	local numNodes = 0
	local nodes = {}

	for node in pairs(nodesToCompute) do
		modifiedNodes[node] = true
		dirtyNodes[node] = true
	end

	for node in pairs(modifiedNodes) do
		-- Push
		numNodes = numNodes + 1
		nodes[numNodes] = node
	end

	while numNodes > 0 do
		-- Pop
		local node = nodes[numNodes]
		numNodes = numNodes - 1

		if dependents[node] then
			local deps = dependents[node]
			for i = 1, #deps do
				local dep = deps[i]

				if not dirtyNodes[dep] then
					dirtyNodes[dep] = true

					-- Push
					numNodes = numNodes + 1
					nodes[numNodes] = dep
				end
			end
		end
	end

	return dirtyNodes
end

---@protected
---@param dependencies table<string, ljgui.DependencyNode[]>
---@param computationCallbacks table<ljgui.DependencyNode>
---@param dirtyNodes ljgui.Set<ljgui.DependencyNode>
local function compute(dependencies, computationCallbacks, dirtyNodes)
	-- Stack
	local traversalStackSize = 0
	local traversalStack = {}

	-- Array
	local numSortedNodes = 0
	local sortedNodes = {}

	while true do
		local firstNode = next(dirtyNodes)
		if not firstNode then break end

		-- Push
		traversalStackSize = 1
		traversalStack[traversalStackSize] = firstNode

		-- Recursively push to the stack all dirty dependencies for the current chain
		while traversalStackSize > 0 do
			-- Pop
			local node = traversalStack[traversalStackSize]
			traversalStackSize = traversalStackSize - 1

			-- Push
			numSortedNodes = numSortedNodes + 1
			sortedNodes[numSortedNodes] = node

			dirtyNodes[node] = nil

			-- Push to the stack all dirty dependencies of the current node
			if dependencies[node] then
				local deps = dependencies[node]
				for i = 1, #deps do
					local depNode = deps[i]

					if dirtyNodes[depNode] then
						-- Push
						traversalStackSize = traversalStackSize + 1
						traversalStack[traversalStackSize] = depNode
					end
				end
			end
		end

		for i = numSortedNodes, 1, -1 do
			local node = sortedNodes[i]
			local callback = computationCallbacks[node]

			if callback then
				callback(node[1], node[2])
			end
		end

		numSortedNodes = 0
	end
end

-- NOTE:
--
-- High-level pseudo-code for the algorithm used above
-- This is essentially a DAG with item/attribute pairs as the nodes,
-- traversed recursively using a stack to avoid function calls.
-- Cycles result in undefined computation order but will not cause infinite loops.

--[[
local function propagate(manager)
	local dirtyNodes = {}
	local nodes = Stack()

	for node in pairs(manager.modifiedNodes) do
		nodes:push(node)
	end

	while not nodes.empty do
		local node = nodes:pop()

		for dep in manager.dependents[node] do
			if not dirtyNodes:has(depNode) then
				dirtyNodes:add(depNode)
				nodes:push(depNode)
			end
		end
	end

	return dirtyNodes
end

local function compute(nodeDeps, dirtyNodes)
	local traversalStack = Stack()
	local sortedNodes = Array()

	while not dirtyNodes.empty do
		traversalStack:push(dirtyNodes.first)

		while not traversalStack.empty do
			local node = traversalStack:pop()

			sortedNodes:push(node)
			dirtyNodes:remove(node)

			for dep in nodeDeps[node] do
				if dirtyNodes:has(dep) then
					traversalStack:push(dep)
				end
			end
		end

		while not sortedNodes.empty do
			local node = sortedNodes:pop()
			computeNode(node)
		end
	end
end
]]

function Manager:propagateModifiedAttributes()
	local dirtyNodes = propagate(self.dependents, self.modifiedNodes, self.nodesToCompute)
	compute(self.dependencies, self.computationCallbacks, dirtyNodes)

	self.modifiedNodes = {}
	-- self.modifiedNodes = setWeakKeyMetatable({})
	self.nodesToCompute = {}
	-- self.nodesToCompute = setWeakKeyMetatable({})
end

function Manager:dumpGraph()
	for dependent, dependencies in pairs(self.dependencies) do
		for _, dependency in ipairs(dependencies) do
			local dependencyName = tostring(dependency[1])
			local dependentName = tostring(dependent[1])
			print(("%s.%s -> %s.%s"):format(dependencyName, dependency[2], dependentName, dependent[2]))
		end
	end

	print()
end
