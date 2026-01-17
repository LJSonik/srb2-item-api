---@class ljgui
local gui = ljrequire "ljgui.common"

---@param item ljgui.Item
local function dumpItems(item)
	gui.dumpItem(item)

	for _, child in item.children:iterate() do
		dumpItems(child)
	end
end

function gui.dumpItems()
	enterfunc "DUMP ITEMS {"
	dumpItems(gui.root)
	exitfunc "} DUMP ITEMS"
end

---@param item ljgui.Item
local function dumpItemTree(item)
	item:dumpInfo()

	enterfunc "{"

	for _, child in item.children:iterate() do
		dumpItemTree(child)
	end

	exitfunc "}"
end

function gui.dumpItemTree(item)
	enterfunc "DUMP ITEM TREE {"
	dumpItemTree(item or gui.root)
	exitfunc "} DUMP ITEM TREE"
end

---@param item ljgui.Item
function gui.dumpItem(item)
	local infos = {}

	table.insert(infos, "debug: " .. (item.debug or "?"))

	table.insert(infos, "position: " .. gui.dec(item.left) .. ", " .. gui.dec(item.top))
	table.insert(infos, "size: " .. gui.dec(item.width) .. ", " .. gui.dec(item.height))
	table.insert(infos, "contentSize: " .. gui.dec(item.contentWidth) .. ", " .. gui.dec(item.contentHeight))

	local rules = item.layoutRules
	if rules then
		-- table.insert(infos, "margin: " .. gui.dec(rules.leftMargin) .. ", " .. gui.dec(rules.topMargin) .. ", " .. gui.dec(rules.rightMargin) .. ", " .. gui.dec(rules.bottomMargin))
		-- table.insert(infos, "padding: " .. gui.dec(rules.leftPadding) .. ", " .. gui.dec(rules.topPadding) .. ", " .. gui.dec(rules.rightPadding) .. ", " .. gui.dec(rules.bottomPadding))
	end

	pr("[ITEM " .. (item.id or "?") .. "]")
	pr(table.concat(infos, "\n"))
	pr()
end

---@param item ljgui.Item
---@param id string
---@param foundItem? ljgui.Item
---@return ljgui.Item
local function findItemById(item, id, foundItem)
	if item.id == id then
		if foundItem then
			error("item with ID " .. id .. "found more than once")
		end
		foundItem = item
	end

	for _, child in item.children:iterate() do
		foundItem = findItemById(child, id, foundItem)
	end

	return foundItem
end

---@param id string
---@return ljgui.Item
function gui.findItemById(id)
	return findItemById(gui.root, id)
end

---@param id string
function gui.dumpItemById(id)
	local item = findItemById(gui.root, id)
	if item then
		gui.dumpItem(item)
	else
		pr("no item with ID " .. id)
	end
end
