---@class ljgui
local gui = ljrequire "ljgui.common"


---@param item ljgui.Item
local function generateWithHorizontalMainDirection(item)
	local rules = item.layoutRules
	local mainDirection = item.layout.mainDirection or "down"
	local secondDirection = item.layout.secondDirection or "right"
	local dy = (secondDirection == "up") and -1 or 1
	local dx = (mainDirection == "left") and -1 or 1
	local itemContentHeight = item.contentHeight
	local prevColumnWidth = 0
	local leftmostItemLeft = 0

	local startY
	if dy == 1 then
		startY = rules.topPadding
	else
		startY = itemContentHeight - rules.bottomPadding
	end

	local x
	if dx == 1 then
		x = rules.leftPadding
	else
		x = 0
	end

	local y = startY

	for _, child in item.children:iterate() do
		local cr = child.layoutRules
		if not cr then continue end

		local mode = cr.placementMode
		if mode == "exclude" then continue end

		local h = (child.height + cr.topMargin + cr.bottomMargin) * dy

		local overflows
		if dy == 1 then
			overflows = (y + h > itemContentHeight)
		else
			overflows = (y + h < 0)
		end

		if overflows and y ~= startY then
			y = startY
			local w = (prevColumnWidth + cr.leftMargin + cr.rightMargin) * dx
			x = x + w
			prevColumnWidth = 0
		end

		if prevColumnWidth < child.width then
			prevColumnWidth = child.width
		end

		if mode == "include" then
			local t
			if dy == 1 then
				t = y + cr.topMargin
			else
				t = y - cr.bottomMargin - child.height
			end

			local l
			if dx == 1 then
				l = x + cr.leftMargin
			else
				l = x - cr.rightMargin - child.width
			end

			local itemMarginLeft = l - cr.leftMargin
			if leftmostItemLeft > itemMarginLeft then
				leftmostItemLeft = itemMarginLeft
			end

			child:moveRaw(l, t)
		end

		y = y + h
	end

	if leftmostItemLeft < 0 then
		for _, child in item.children:iterate() do
			local cr = child.layoutRules
			if cr and cr.placementMode == "include" then
				child:moveRaw(child.left - leftmostItemLeft, nil)
			end
		end
	end
end

---@param item ljgui.Item
local function generateWithVerticalMainDirection(item)
	local rules = item.layoutRules
	local mainDirection = item.layout.mainDirection or "down"
	local secondDirection = item.layout.secondDirection or "right"
	local dx = (secondDirection == "left") and -1 or 1
	local dy = (mainDirection == "up") and -1 or 1
	local itemContentWidth = item.contentWidth
	local prevLineHeight = 0
	local highestItemTop = 0

	local startX
	if dx == 1 then
		startX = rules.leftPadding
	else
		startX = itemContentWidth - rules.rightPadding
	end

	local y
	if dy == 1 then
		y = rules.topPadding
	else
		y = 0
	end

	local x = startX

	for _, child in item.children:iterate() do
		local cr = child.layoutRules
		if not cr then continue end

		local mode = cr.placementMode
		if mode == "exclude" then continue end

		local w = (child.width + cr.leftMargin + cr.rightMargin) * dx

		local overflows
		if dx == 1 then
			overflows = (x + w > itemContentWidth)
		else
			overflows = (x + w < 0)
		end

		if overflows and x ~= startX then
			x = startX
			local h = (prevLineHeight + cr.topMargin + cr.bottomMargin) * dy
			y = y + h
			prevLineHeight = 0
		end

		if prevLineHeight < child.height then
			prevLineHeight = child.height
		end

		if mode == "include" then
			local l
			if dx == 1 then
				l = x + cr.leftMargin
			else
				l = x - cr.rightMargin - child.width
			end

			local t
			if dy == 1 then
				t = y + cr.topMargin
			else
				t = y - cr.bottomMargin - child.height
			end

			local itemMarginTop = t - cr.topMargin
			if highestItemTop > itemMarginTop then
				highestItemTop = itemMarginTop
			end

			child:moveRaw(l, t)
		end

		x = x + w
	end

	if highestItemTop < 0 then
		for _, child in item.children:iterate() do
			local cr = child.layoutRules
			if cr and cr.placementMode == "include" then
				child:moveRaw(nil, child.top - highestItemTop)
			end
		end
	end
end

gui.addLayoutStrategy("flow", {
	dependencies = {
		{ "self", "width" },
		{ "self", "height" },
		{ "children", "width" },
		{ "children", "height" },
	},
	params = { "mainDirection", "secondDirection" },

	compute = function(item)
		local mainDirection = item.layout.mainDirection or "down"

		if mainDirection == "left" or mainDirection == "right" then
			generateWithHorizontalMainDirection(item)
		else
			generateWithVerticalMainDirection(item)
		end
	end
})
