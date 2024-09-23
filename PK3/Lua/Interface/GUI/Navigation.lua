---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


local function callNavigationEvent(item, oldIndex, newIndex)
	local children = item.navigationTarget.children
	local oldElem = children:get(oldIndex)
	local newElem = children:get(newIndex)
	gui.instance.eventManager:callItemEvent(item, "NavigationChange", oldElem, newElem, oldIndex, newIndex)
end

---@param item ljgui.Item
---@param key keyevent_t
---@return boolean
local function onKeyPress(item, key)
	if key.repeated then return false end

	local keyName = key.name
	local children = item.navigationTarget.children
	local oldIndex = item.navigationIndex
	local newIndex

	if keyName == "up arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_FORWARD) then
		if oldIndex > 1 then
			newIndex = oldIndex - 1
		else
			newIndex = children:getLength()
		end
	elseif keyName == "down arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_BACKWARD) then
		if oldIndex < children:getLength() then
			newIndex = oldIndex + 1
		else
			newIndex = 1
		end
	end

	if newIndex then
		mod.setMenuNavigationSelection(item, newIndex)
		return true
	else
		return false
	end
end

---@param item ljgui.Item
---@param navigationTarget ljgui.Item
---@param onChange? fun(item: ljgui.Item, oldElem?: ljgui.Item, newElem: ljgui.Item, oldIndex?: integer, newIndex: integer)
function mod.addMenuNavigationToItem(item, navigationTarget, onChange)
	item:addEvent("KeyPress", onKeyPress)
	item.navigationIndex = 1
	item.navigationTarget = navigationTarget

	if onChange then
		item:addEvent("NavigationChange", onChange)

		local newElem = navigationTarget.children:get(item.navigationIndex)
		onChange(item, nil, newElem, nil, item.navigationIndex)
	end
end

---@param item ljgui.Item
---@param index integer
function mod.setMenuNavigationSelection(item, index)
	local oldIndex = item.navigationIndex
	item.navigationIndex = index
	callNavigationEvent(item, oldIndex, index)
end
