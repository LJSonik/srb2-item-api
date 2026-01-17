---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.ItemProps
---@field parsed?   boolean
---@field children? ljgui.Item[]
---
---@field layout?      ljgui.Layout
---@field layoutRules? ljgui.LayoutRules
---
---@field autoLeft?     string|table
---@field autoTop?      string|table
---@field autoPosition? string|table
---
---@field autoWidth?  string|table
---@field autoHeight? string|table
---@field autoSize?   string|table
---
---@field autoContentLeft? string|table
---@field autoContentTop?  string|table
---@field autoContentSize? string|table
---
---@field fitParent? boolean
---
---@field style?      fixed_t
---@field styleRules? table
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


local autoAttrPairs = {
	{ "left"       , "top"       , "autoLeft"       , "autoTop"       , "autoPosition"    },
	{ "width"      , "height"    , "autoWidth"      , "autoHeight"    , "autoSize"        },
	{ "contentLeft", "contentTop", "autoContentLeft", "autoContentTop", "autoContentSize" },
}

local layoutFieldNames = {
	"placementMode",

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

	gui.parseLayoutRules(rules)
end

---@param props ljgui.ItemProps
local function parseLayout(props)
	local layout = props.layout
	if not layout then return end

	if type(layout) == "string" then
		local strategy = gui.layoutStrategies[layout]
		if not strategy then
			error('unknown layout strategy "' .. layout .. '"')
		end

		layout = { strategy = layout }
		props.layout = layout
	end

	local strategy = gui.layoutStrategies[layout.strategy]

	-- e.g. layout="flow", layout_mainDirection="left" => layout = { strategy="flow", mainDirection="left" }
	if strategy then
		for _, paramName in ipairs(strategy.params) do
			local fieldValue = props["layout_" .. paramName]
			if fieldValue ~= nil then
				layout[paramName] = fieldValue
			end
		end
	end
end

---@param props ljgui.ItemProps
---@param attrName string
---@param fieldName string
local function parseAutoField(props, attrName, fieldName)
	local field = props[fieldName]
	if not field then return end

	if type(field) == "string" then
		local strategy = gui.autoAttributeStrategies[attrName][field]
		if not strategy then
			error('unknown auto-attribute strategy "' .. field .. '"')
		end

		field = { strategy = field }
		props[fieldName] = field
	end

	local strategy = gui.autoAttributeStrategies[attrName][field.strategy]

	-- e.g. autoX="snap_left", autoX_snapDist=42*FU => autoX = { strategy="snap_left", snapDist=42*FU }
	for _, paramName in ipairs(strategy.params) do
		local fieldValue = props[fieldName .. "_" .. paramName]
		if fieldValue ~= nil then
			field[paramName] = fieldValue
		end
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
				error("setting margin or padding in style tables is deprecated")
				props[k] = prop
			end
		end
	end

	for _, k in ipairs(zeroLayoutFieldNames) do
		if props[k] == nil then
			props[k] = 0
		end
	end

	parseLayout(props)

	-- Convenient shortcut!
	if props.fitParent then
		props.autoPosition = "center"
		props.autoSize = "fit_parent"
	end

	for _, autoPair in ipairs(autoAttrPairs) do
		-- e.g. autoSize => autoWidth + autoHeight
		local shortcutName = autoPair[5]
		if shortcutName and props[shortcutName] then
			local field = props[shortcutName]
			props[autoPair[3]], props[autoPair[4]] = field, field
			props[shortcutName] = nil
		end

		parseAutoField(props, autoPair[1], autoPair[3])
		parseAutoField(props, autoPair[2], autoPair[4])
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
		item:setStyle(item.defaultStyle) -- !!!
	end

	for k, v in pairs(props) do
		if eventNames[k] then
			item:addEvent(k:sub(3), v)
		end

		if k:sub(1, 4) == "var_" then
			item[k:sub(5)] = v
		end
	end

	if props.layout then
		gui.setItemLayout(item, props.layout)
	end

	for _, autoPair in ipairs(autoAttrPairs) do
		if props[autoPair[3]] then
			gui.setItemAutoAttribute(item, autoPair[1], props[autoPair[3]])
		end

		if props[autoPair[4]] then
			gui.setItemAutoAttribute(item, autoPair[2], props[autoPair[4]])
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
