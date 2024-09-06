---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.ItemList
---@field items ljgui.Item[]
local List = gui.class()
gui.ItemList = List


function List:__init()
	self.items = {}
end

---@param index integer
---@return ljgui.Item
function List:get(index)
	return self.items[index]
end

---@return ljgui.Item
function List:getFront()
	local items = self.items
	return items[#items]
end

---@return ljgui.Item
function List:getBack()
	return self.items[1]
end

---@return integer
function List:getLength()
	return #self.items
end

---@param items ljgui.Item[]
---@param i integer
---@return integer?
---@return ljgui.Item?
local function iterateNext(items, i)
	i = i + 1
	local item = items[i]
	if item then
		return i, item
	end
end

---@param items ljgui.Item[]
---@param i integer
---@return integer?
---@return ljgui.Item?
local function reverseIterateNext(items, i)
	i = i - 1
	local item = items[i]
	if item then
		return i, item
	end
end

---@return fun(items: ljgui.Item[], index: integer): integer, ljgui.Item
---@return ljgui.Item[]
---@return integer
function List:iterate()
	return iterateNext, self.items, 0
end

---@return fun(items: ljgui.Item[], index: integer): integer, ljgui.Item
---@return ljgui.Item[]
---@return integer
function List:reverseIterate()
	return reverseIterateNext, self.items, #self.items + 1
end

---@param item ljgui.Item
function List:add(item)
	local items = self.items
	local depth = item.depth

	for i = #items, 1, -1 do
		if items[i].depth >= depth then
			table.insert(items, i + 1, item)
			return
		end
	end

	table.insert(items, 1, item)
end

---@param item ljgui.Item
function List:remove(item)
	gui.removeValueFromArray(self.items, item)
end
