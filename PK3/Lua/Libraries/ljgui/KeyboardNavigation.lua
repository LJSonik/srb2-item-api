---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.KeyboardNavigation
---@field index integer
---@field column integer
---@field row integer
---@field item ljgui.Item

---@class ljgui.Item
---@field keyboardNav? ljgui.KeyboardNavigation


local function getIndex(c, r, numColumns)
	return (r - 1) * numColumns + c
end

---@param item ljgui.Item
---@param key keyevent_t
---@return boolean
local function onKeyPress(item, key)
	if key.repeated then return false end

	local numElems = item.children:getLength()
	local numColumns = item.layoutRules.gridColumns
	local numRows = (numElems - 1) / numColumns + 1

	local nav = item.keyboardNav
	local c, r = nav.column, nav.row
	local oldIndex = nav.index

	local dc, dr = 0, 0
	local keyName = key.name
	if keyName == "left arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_STRAFELEFT) then
		dc = -1
	elseif keyName == "right arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_STRAFERIGHT) then
		dc = 1
	elseif keyName == "up arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_FORWARD) then
		dr = -1
	elseif keyName == "down arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_BACKWARD) then
		dr = 1
	else
		return false
	end

	repeat
		c = c + dc
		r = r + dr

		if c < 1 then
			c = numColumns
		elseif c > numColumns then
			c = 1
		end

		if r < 1 then
			r = numRows
		elseif r > numRows then
			r = 1
		end
	until getIndex(c, r, numColumns) <= numElems

	nav.column = c
	nav.row = r
	nav.index = getIndex(c, r, numColumns)
	nav.item = item.children:get(nav.index)

	local oldElem = item.children:get(oldIndex)
	local newElem = item.children:get(nav.index)
	newElem:focus()
	gui.instance.eventManager:callItemEvent(item, "KeyboardNavigation", oldElem, newElem, oldIndex, nav.index)

	return true
end

---@param item ljgui.Item
---@param onNavigation? fun(item: ljgui.Item, oldElem?: ljgui.Item, newElem: ljgui.Item, oldIndex?: integer, newIndex: integer)
function gui.addKeyboardNavigationToGrid(item, onNavigation)
	item:addEvent("KeyPress", onKeyPress)

	local nav = {
		column = 1,
		row = 1,
		index = 1,
		item = item.children:get(1)
	}
	item.keyboardNav = nav

	if onNavigation then
		item:addEvent("KeyboardNavigation", onNavigation)

		local newElem = item.children:get(nav.index)
		onNavigation(item, nil, newElem, nil, nav.index)
	end
end
