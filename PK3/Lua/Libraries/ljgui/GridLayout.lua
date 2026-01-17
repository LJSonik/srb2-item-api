---@class ljgui
local gui = ljrequire "ljgui.common"


---@param item ljgui.Item
local function calculateColumnAndRowSizes(item)
	local columnSizes, rowSizes = {}, {}
	local curCol, curRow = 1, 1
	local columns = item.layout.gridColumns

	for _, child in item.children:iterate() do
		local cr = child.layoutRules
		if not cr then continue end

		if cr.placementMode == "exclude" then continue end

		columnSizes[curCol] = max($ or 0, child.width + cr.leftMargin + cr.rightMargin)
		rowSizes[curRow] = max($ or 0, child.height + cr.topMargin + cr.bottomMargin)

		curCol = ($ % columns) + 1
		if curCol == 1 then
			curRow = $ + 1
		end
	end

	return columnSizes, rowSizes
end

gui.addLayoutStrategy("grid", {
	dependencies = {
		{ "self", "width" },
		{ "self", "height" },
	},
	params = { "gridColumns", "gridRows" },

	compute = function(item)
		local rules = item.layoutRules
		local x, y = rules.leftPadding, rules.topPadding
		local columnSizes, rowSizes = calculateColumnAndRowSizes(item)
		local curCol, curRow = 1, 1

		for _, child in item.children:iterate() do
			local cr = child.layoutRules
			if not cr then continue end

			local mode = cr.placementMode
			if mode == "exclude" then continue end

			if mode == "include" then
				child:moveRaw(x + cr.leftMargin, y + cr.topMargin)
			end

			x = x + columnSizes[curCol]
			curCol = ($ % item.layout.gridColumns) + 1
			if curCol == 1 then
				x = rules.leftPadding
				y = y + rowSizes[curRow]
				curRow = $ + 1
			end
		end
	end
})
