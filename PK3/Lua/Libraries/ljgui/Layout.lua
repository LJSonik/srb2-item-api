---@class ljgui
local gui = ljrequire "ljgui.common"


---@alias ljgui.BaseBorderGetter fun(item: ljgui.Item): fixed_t, fixed_t, fixed_t, fixed_t

---@alias ljgui.LayoutGenerator fun(item: ljgui.Item)

---@class ljgui.AutoLayoutStrategy : ljgui.Class
---@field id string
---@field usedAttributes? string[]
---@field usedAttributesSet? ljgui.Set<string>
---@field usedSelfAttributes? string[]
---@field usedSelfAttributesSet? ljgui.Set<string>
---@field fields? string[]
---@field generator ljgui.LayoutGenerator
---@field parsed? boolean

---@alias ljgui.PositionOrSizeGenerator fun(item: ljgui.Item): fixed_t, fixed_t

---@class ljgui.AutoPositionOrSizeStrategy : ljgui.Class
---@field id string
---@field type "self"|"parent"|"children"
---@field usedAttributes? string[]
---@field usedSelfAttributes? string[]
---@field fields? string[]
---@field generator ljgui.PositionOrSizeGenerator
---@field parsed? boolean

---@class ljgui.LayoutRules
---@field placementMode? "include"|"exclude"|"placeholder"
---@field fitParent?     boolean
---
---@field autoLayout?   ljgui.AutoLayoutStrategy|string
---
---@field autoPosition? ljgui.AutoPositionOrSizeStrategy|string
---@field autoLeft?     ljgui.AutoPositionOrSizeStrategy|string
---@field autoTop?      ljgui.AutoPositionOrSizeStrategy|string
---
---@field autoSize?   ljgui.AutoPositionOrSizeStrategy|string
---@field autoWidth?  ljgui.AutoPositionOrSizeStrategy|string
---@field autoHeight? ljgui.AutoPositionOrSizeStrategy|string
---
---@field autoContentSize?   ljgui.AutoPositionOrSizeStrategy|string
---@field autoContentWidth?  ljgui.AutoPositionOrSizeStrategy|string
---@field autoContentHeight? ljgui.AutoPositionOrSizeStrategy|string
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
---
---@field selfDependentAttributes?   table<string, ljgui.Set<string>>
---@field parentDependentAttributes? table<string, ljgui.Set<string>>
---@field childDependentAttributes?  table<string, ljgui.Set<string>>

---@type table<string, ljgui.AutoLayoutStrategy>
gui.autoLayoutStrategies = {}
---@type table<string, ljgui.AutoPositionOrSizeStrategy>
gui.autoPositionStrategies = {}
---@type table<string, ljgui.AutoPositionOrSizeStrategy>
gui.autoSizeStrategies = {}


---@param strategy table
---@param list table<string, any>
function gui.parseAutoStrategy(strategy)
	strategy.usedAttributes = $ or {}
	strategy.usedSelfAttributes = $ or {}
	strategy.fields = $ or {}

	table.insert(strategy.usedSelfAttributes, "rooted")
	strategy.usedAttributesSet = gui.arrayToSet(strategy.usedAttributes)
	strategy.usedSelfAttributesSet = gui.arrayToSet(strategy.usedSelfAttributes)

	strategy.parsed = true
end

---@param strategy ljgui.AutoLayoutStrategy
function gui.addAutoLayoutStrategy(strategy)
	gui.parseAutoStrategy(strategy)
	gui.autoLayoutStrategies[strategy.id] = strategy
end

---@param strategy ljgui.AutoPositionOrSizeStrategy
function gui.addAutoPositionStrategy(strategy)
	gui.parseAutoStrategy(strategy)
	gui.autoPositionStrategies[strategy.id] = strategy
end

---@param strategy ljgui.AutoPositionOrSizeStrategy
function gui.addAutoSizeStrategy(strategy)
	gui.parseAutoStrategy(strategy)
	gui.autoSizeStrategies[strategy.id] = strategy
end

---@param item ljgui.Item
function gui.getDefaultBaseBorder(item)
	local bdSize = item.style.bdSize or 0
	return bdSize, bdSize, bdSize, bdSize
end

---@param rules ljgui.LayoutRules
---@param list table
---@param field1 string
---@param field2? string
---@param shortcutField? string
local function parseRulePair(rules, list, field1, field2, shortcutField)
	if shortcutField then
		local auto = rules[shortcutField]
		if auto then
			rules[field1], rules[field2] = auto, auto
		end
	end

	local auto1 = rules[field1]

	if type(auto1) == "string" then
		local strategy = list[auto1]
		if not strategy then
			error('invalid layout strategy "' .. auto1 .. '"')
		end

		auto1 = strategy
		rules[field1] = auto1
	end

	if auto1 and not auto1.parsed then
		gui.parseAutoStrategy(auto1)
	end

	if field2 then
		local auto2 = rules[field2]

		if type(rules[field2]) == "string" then
			local strategy = list[auto2]
			if not strategy then
				error('invalid layout strategy "' .. auto2 .. '"')
			end

			auto2 = strategy
			rules[field2] = auto2
		end

		if auto2 and not auto2.parsed then
			gui.parseAutoStrategy(auto2)
		end
	end
end

---@param rules ljgui.LayoutRules
---@param autoName string
---@param dstAttr string
local function parseAutoRule(rules, autoName, dstAttr)
	local auto = rules[autoName]
	if not auto then return end

	local selfDeps = rules.selfDependentAttributes
	local selfAttrs = auto.usedSelfAttributes
	for i = 1, #selfAttrs do
		local attr = selfAttrs[i]
		selfDeps[attr] = $ or {}
		selfDeps[attr][dstAttr] = true
	end

	if auto.type ~= "self" then
		local deps = (auto.type == "parent")
			and rules.parentDependentAttributes
			or rules.childDependentAttributes

		local attrs = auto.usedAttributes
		for i = 1, #attrs do
			local attr = attrs[i]
			deps[attr] = $ or {}
			deps[attr][dstAttr] = true
		end
	end
end

---@param rules ljgui.LayoutRules
local function parseDependentAttributes(rules)
	rules.selfDependentAttributes = {}
	rules.parentDependentAttributes = {}
	rules.childDependentAttributes = {}

	parseAutoRule(rules, "autoLeft", "left")
	parseAutoRule(rules, "autoTop", "top")
	parseAutoRule(rules, "autoWidth", "width")
	parseAutoRule(rules, "autoHeight", "height")
	parseAutoRule(rules, "autoContentWidth", "contentWidth")
	parseAutoRule(rules, "autoContentHeight", "contentHeight")
end

---@param rules ljgui.LayoutRules
function gui.parseLayoutRules(rules)
	parseRulePair(rules, gui.autoLayoutStrategies, "autoLayout")
	parseRulePair(rules, gui.autoPositionStrategies, "autoLeft", "autoTop", "autoPosition")
	-- parseRulePair(rules, gui.autoPositionStrategies, "autoPosition")
	parseRulePair(rules, gui.autoSizeStrategies, "autoWidth", "autoHeight", "autoSize")
	parseRulePair(rules, gui.autoSizeStrategies, "autoContentWidth", "autoContentHeight", "autoContentSize")

	parseDependentAttributes(rules)

	local auto = rules.autoLeft or rules.autoTop or rules.autoWidth or rules.autoHeight
		or rules.autoContentWidth or rules.autoContentHeight
	rules.dependencyType = auto and auto.type

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

-- ---@param rules ljgui.LayoutRules
-- function gui.parseLayoutRules(rules)
-- 	if type(rules.autoLayout) == "string" then
-- 		rules.autoLayout = gui.autoLayoutStrategies[rules.autoLayout]
-- 	end
-- 	if type(rules.autoPosition) == "string" then
-- 		rules.autoPosition = gui.autoPositionStrategies[rules.autoPosition]
-- 	end

-- 	local autoSize = rules.autoSize
-- 	if autoSize then
-- 		rules.autoWidth, rules.autoHeight = autoSize, autoSize
-- 	end
-- 	if type(rules.autoWidth) == "string" then
-- 		rules.autoWidth = gui.autoSizeStrategies[rules.autoWidth]
-- 	end
-- 	if type(rules.autoHeight) == "string" then
-- 		rules.autoHeight = gui.autoSizeStrategies[rules.autoHeight]
-- 	end

-- 	autoSize = rules.autoContentSize
-- 	if autoSize then
-- 		rules.autoContentWidth, rules.autoContentHeight = autoSize, autoSize
-- 	end
-- 	if type(rules.autoContentWidth) == "string" then
-- 		rules.autoContentWidth = gui.autoSizeStrategies[rules.autoContentWidth]
-- 	end
-- 	if type(rules.autoContentHeight) == "string" then
-- 		rules.autoContentHeight = gui.autoSizeStrategies[rules.autoContentHeight]
-- 	end

-- 	local auto = rules.autoPosition or rules.autoWidth or rules.autoHeight
-- 		or rules.autoContentWidth or rules.autoContentHeight
-- 	rules.dependencyType = auto and auto.type

-- 	rules.placementMode = $ or "include"
-- end

-- ---@param item ljgui.Item
-- ---@param autoWidth ljgui.AutoPositionOrSizeStrategy
-- ---@param autoHeight ljgui.AutoPositionOrSizeStrategy
-- ---@param dependencyType? string
-- ---@return fixed_t
-- ---@return fixed_t
-- local function calculateAutoSize(item, autoWidth, autoHeight, dependencyType)
-- 	if autoWidth and autoHeight and autoWidth.generator == autoHeight.generator
-- 	and autoWidth.type == dependencyType then
-- 		return autoWidth.generator(item)
-- 	else
-- 		local w, h, _
-- 		if autoWidth and autoWidth.type == dependencyType then
-- 			w = autoWidth.generator(item)
-- 		end
-- 		if autoHeight and autoHeight.type == dependencyType then
-- 			_, h = autoHeight.generator(item)
-- 		end
-- 		return w, h
-- 	end
-- end

-- ---@param item ljgui.Item
-- function gui.generateLayout(item)
-- 	local rules = item.layoutRules

-- 	if rules then
-- 		local w, h = calculateAutoSize(item, rules.autoWidth, rules.autoHeight, nil)
-- 		item:resizeRaw(w, h)

-- 		w, h = calculateAutoSize(item, rules.autoContentWidth, rules.autoContentHeight, nil)
-- 		item:resizeContentRaw(w, h)

-- 		if item.parent and rules.dependencyType == "parent" then
-- 			w, h = calculateAutoSize(item, rules.autoWidth, rules.autoHeight, "parent")
-- 			item:resizeRaw(w, h)

-- 			w, h = calculateAutoSize(item, rules.autoContentWidth, rules.autoContentHeight, "parent")
-- 			item:resizeContentRaw(w, h)

-- 			local autoPosition = rules.autoPosition
-- 			if autoPosition and autoPosition.type == "parent" then
-- 				local l, t = autoPosition.generator(item)
-- 				item:moveRaw(l, t)
-- 			end
-- 		end
-- 	end

-- 	-- Make sure all children have their sizes calculated before generating the layout
-- 	for _, child in item.children:iterate() do
-- 		if not child.layoutGenerated then
-- 			gui.generateLayout(child)
-- 		end
-- 	end

-- 	if rules then
-- 		-- Generate the layout
-- 		local generator = rules.autoLayout and rules.autoLayout.generator
-- 		if generator then
-- 			generator(item)
-- 		end

-- 		if rules.dependencyType == "children" then
-- 			w, h = calculateAutoSize(item, rules.autoWidth, rules.autoHeight, "children")
-- 			item:resizeRaw(w, h)

-- 			w, h = calculateAutoSize(item, rules.autoContentWidth, rules.autoContentHeight, "children")
-- 			item:resizeContentRaw(w, h)

-- 			local autoPosition = rules.autoPosition
-- 			if autoPosition and autoPosition.type == "children" then
-- 				local l, t = autoPosition.generator(item)
-- 				item:moveRaw(l, t)
-- 			end
-- 		end
-- 	end

-- 	item.layoutGenerated = true
-- end

-- ---@param item ljgui.Item
-- ---@param chainStarts ljgui.Set<ljgui.Item>
-- local function checkParents(item, chainStarts)
-- 	-- Chain start will be moved to the highest ancestor later
-- 	chainStarts[item] = nil

-- 	while true do
-- 		local parent = item.parent
-- 		local rules = parent and parent.layoutRules

-- 		if parent and parent.layoutGenerated
-- 		and rules and (rules.autoPosition and rules.autoPosition.type == "children"
-- 		or rules.autoSize and rules.autoSize.type == "children") then
-- 			item = parent
-- 			item.layoutGenerated = false
-- 		else
-- 			if parent then
-- 				if parent.layoutGenerated then
-- 					-- Highest ancestor in chain
-- 					chainStarts[parent] = true
-- 					parent.layoutGenerated = false
-- 				end
-- 			else
-- 				-- Highest ancestor in chain
-- 				chainStarts[item] = true
-- 			end

-- 			break
-- 		end
-- 	end
-- end

-- ---@param item ljgui.Item
-- ---@param chainStarts ljgui.Set<ljgui.Item>
-- local function checkChildren(item, chainStarts)
-- 	for _, child in item.children:iterate() do
-- 		local rules = child.layoutRules
-- 		if rules then
-- 			local autoPosition = rules.autoPosition
-- 			local autoSize = rules.autoSize

-- 			if autoPosition and autoPosition.type == "parent"
-- 			or autoSize and autoSize.type == "parent" then
-- 				if chainStarts[child] then
-- 					chainStarts[child] = nil
-- 				else
-- 					child.layoutGenerated = false
-- 					checkChildren(child, chainStarts)
-- 				end
-- 			end
-- 		end
-- 	end
-- end

-- ---@return ljgui.Set<ljgui.Item>
-- local function findLayoutDependencyChainStarts()
-- 	local pendingItems = gui.instance.itemLayoutsToGenerate
-- 	---@type ljgui.Set<ljgui.Item>
-- 	local chainStarts = gui.arrayToSet(pendingItems)

-- 	for i = 1, #pendingItems do
-- 		local item = pendingItems[i]

-- 		if not item.layoutGenerated and item.rooted then
-- 			checkParents(item, chainStarts)
-- 			checkChildren(item, chainStarts)
-- 		end
-- 	end

-- 	return chainStarts
-- end

-- function gui.generatePendingItemLayouts()
-- 	local items = findLayoutDependencyChainStarts()

-- 	for item, _ in pairs(items) do
-- 		if not item.layoutGenerated and item.rooted then
-- 			gui.generateLayout(item)
-- 		end
-- 	end

-- 	gui.instance.itemLayoutsToGenerate = {}
-- end
