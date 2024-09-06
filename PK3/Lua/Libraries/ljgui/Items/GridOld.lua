---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.GridOld : ljgui.Item
---@operator call(table): nil
local GridOld, base = gui.class(gui.Item)
gui.GridOld = GridOld


---@type ljgui.ItemStyle
GridOld.defaultStyle = {}

GridOld.autoPosition = "fillParent" -- !!!!
GridOld.autoSize = "fillParent" -- !!!!


function GridOld:__init(props)
	base.__init(self)

	self.debug = "GridOld"

	if props then
		self:build(props)
	end
end

function GridOld:build(props)
	self:applyProps(props)
end

---@param item ljgui.Item
local function calculateColumnAndRowSizes(item)
	local columnSizes, rowSizes = {}, {}

	local curCol, curRow = 1, 1
	for _, child in item.children:iterate() do
		if child.width ~= nil then
			columnSizes[curCol] = max($ or 0, child.width)
		end
		if child.height ~= nil then
			rowSizes[curRow] = max($ or 0, child.height)
		end

		curCol = ($ % props.columns) + 1
		if curCol == 1 then
			curRow = $ + 1
		end
	end

	return columnSizes, rowSizes
end

-- !!!!
function GridOld:generateLayout()
	print "GENERATING GRID LAYOUT"

	local rules = item.styleRules
	local x, y = rules.leftPadding, rules.topPadding
	local columnSizes, rowSizes = calculateColumnAndRowSizes(self)
	local curCol, curRow = 1, 1

	for _, child in self.children:iterate() do
		local childRules = child.layoutRules

		child:attach(self)
		child:moveRaw(x + childRules.leftMargin, y + childRules.topMargin)

		x = x + columnSizes[curCol]
		curCol = ($ % props.columns) + 1
		if curCol == 1 then
			x = rules.leftPadding
			y = y + rowSizes[curRow]
			curRow = $ + 1
		end
	end

	print "GRID LAYOUT GENERATED"
end

function GridOld:draw(v)
	-- gui.drawBaseItemStyle(v, self, self.style)
	self:drawChildren(v)
end
