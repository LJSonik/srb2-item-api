---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.ItemProps
---@field parsed?      boolean
---@field children?    ljgui.Item[]
---@field layoutRules? ljgui.LayoutRules
---@field style?       fixed_t
---@field styleRules?  table
---@field fitParent?   boolean
---
---@field size?   fixed_t[]
---@field width?  fixed_t
---@field height? fixed_t
---
---@field contentSize?   fixed_t[]
---@field contentWidth?  fixed_t
---@field contentHeight? fixed_t
---
---@field margin?       table<string, fixed_t>|fixed_t
---@field leftMargin?   fixed_t
---@field topMargin?    fixed_t
---@field rightMargin?  fixed_t
---@field bottomMargin? fixed_t
---
---@field padding?       table<string, fixed_t>|fixed_t
---@field leftPadding?   fixed_t
---@field topPadding?    fixed_t
---@field rightPadding?  fixed_t
---@field bottomPadding? fixed_t
---
---@field update? fun(item: ljgui.Item)
---@field draw?   fun(item: ljgui.Item, v: videolib)

local autoRuleNames = { "autoLayout", "autoLeft", "autoTop" }

local layoutFieldNames = {
	"placementMode", "fitParent",

	"autoLayout",
	"autoPosition", "autoLeft", "autoTop",
	"autoSize", "autoWidth", "autoHeight",
	"autoContentSize", "autoContentWidth", "autoContentHeight",

	"leftMargin", "topMargin",
	"rightMargin", "bottomMargin",
	"margin",

	"leftPadding", "topPadding",
	"rightPadding", "bottomPadding",
	"padding",
}

local zeroLayoutFieldNames = {
	"leftMargin", "topMargin",
	"rightMargin", "bottomMargin",

	"leftPadding", "topPadding",
	"rightPadding", "bottomPadding",
}

local propsStyleFieldNames = {
	"leftMargin", "topMargin",
	"rightMargin", "bottomMargin",
	"margin",

	"leftPadding", "topPadding",
	"rightPadding", "bottomPadding",
	"padding",
}

local eventNames = gui.arrayToSet {
	"onLeftMousePress", "onLeftMouseRelease",
	"onMouseEnter", "onMouseLeave",
	"onMouseMove",

	"onKeyPress", "onKeyRelease",

	"onTrigger", "onChange"
}


---@param props ljgui.ItemProps
local function parseLayoutRules(props)
	props.layoutRules = $ or {}
	local rules = props.layoutRules

	for _, k in ipairs(layoutFieldNames) do
		if props[k] ~= nil then
			rules[k] = props[k]
		end
	end

	local margin = rules.margin
	if margin ~= nil then
		if type(margin) ~= "table" then
			margin = { margin, margin, margin, margin }
		end
		rules.leftMargin , rules.topMargin    = margin[1], margin[2]
		rules.rightMargin, rules.bottomMargin = margin[3], margin[4]
	end

	local padding = rules.padding
	if padding ~= nil then
		if type(padding) ~= "table" then
			padding = { padding, padding, padding, padding }
		end
		rules.leftPadding , rules.topPadding    = padding[1], padding[2]
		rules.rightPadding, rules.bottomPadding = padding[3], padding[4]
	end

	if rules.fitParent then
		rules.autoPosition = "Center"
		rules.autoSize = "FitParent"
	end

	gui.parseLayoutRules(rules)

	-- if not rules.autoLayout then
	-- 	rules.autoLayout = gui.autoLayoutStrategies["OnePerLine"]
	-- end

	for _, ruleName in ipairs(autoRuleNames) do
		if rules[ruleName] then
			for _, k in ipairs(rules[ruleName].fields) do
				-- !!! Old system
				if props[k] ~= nil then
					rules[k] = props[k]
				end

				local fullRuleName = ruleName .. "_" .. k
				if props[fullRuleName] ~= nil then
					rules[fullRuleName] = props[fullRuleName]
				end
			end
		end
	end

	if rules.autoLeft or rules.autoTop then
		rules.placementMode = "exclude"
	end
end

---@param item ljgui.Item
---@param props ljgui.ItemProps
function gui.parseItemProps(item, props)
	if props.parsed then return end

	if not props.children then
		props.children = {}
		for i = 1, #props do
			props.children[i] = props[i]
			props[i] = nil
		end
	end

	local size = props.size
	if size then
		props.width, props.height = size[1], size[2]
	end

	size = props.contentSize
	if size then
		props.contentWidth, props.contentHeight = size[1], size[2]
	end

	if props.style then
		for _, k in ipairs(propsStyleFieldNames) do
			local prop = props.style[k]
			if prop ~= nil then
				error("setting margin in style table is deprecated")
				props[k] = prop
			end
		end
	end

	for _, k in ipairs(zeroLayoutFieldNames) do
		if props[k] == nil then
			props[k] = 0
		end
	end

	parseLayoutRules(props)

	props.parsed = true
end

---@param item ljgui.Item
---@param props? ljgui.ItemProps
function gui.applyItemProps(item, props)
	if not props then return end

	item.id = props.id or $ -- !!! DBG

	gui.parseItemProps(item, props)

	item:resize(props.width or item.width, props.height or item.height)

	if props.contentWidth ~= nil or props.contentHeight ~= nil then
		item:resizeContent(props.contentWidth or item.width, props.contentHeight or item.height)
	end

	for _, child in ipairs(props.children) do
		child:attach(item)
	end

	item:updateLayoutRules(props.layoutRules)

	if props.styleRules then
		gui.applyStyleRules(item)
	end

	if props.style then
		item:setStyle(props.style)
	elseif not item.style then
		item:setStyle(item.defaultStyle)
	end

	for k, v in pairs(props) do
		if eventNames[k] then
			item:addEvent(k:sub(3), v)
		end

		if k:sub(1, 4) == "var_" then
			item[k:sub(5)] = v
		end
	end

	if props.draw then
		item.draw = props.draw
	end

	if props.update then
		item.update = props.update
	end

	if props.onReady then
		props.onReady(item)
	end
end
