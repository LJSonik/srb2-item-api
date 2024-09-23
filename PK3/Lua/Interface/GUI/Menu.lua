-- Menu elements:
--
-- Menu list
--   Inventory
--   Status
--   Options
--   Help
--   Crafting
--
-- Inventory
--
-- Item avatar & description
--
-- Status
--   Player avatar
--   Hunger
--   Thirst
--   Temperature
--   Debuffs


---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


---@class itemapi.MenuDef
---@field id string
---@field index integer
---@field build fun(): ljgui.Item
---@field focus fun(ljgui.Item)
---@field destroy fun()


---@type table<string|integer, itemapi.MenuDef>
mod.menuDefs = {}

---@type boolean
mod.client.menuOpen = false


---@param id string
---@return integer?
function mod.menuIDToIndex(id)
	for i, menu in ipairs(mod.menuDefs) do
		if menu.id == id then
			return i
		end
	end
end


---Registers a new menu
---@param id string
---@param def itemapi.MenuDef
function mod.addMenu(id, def)
	def.index = #mod.menuDefs + 1
	def.id = id
	mod.menuDefs[def.index] = def
	mod.menuDefs[id] = def
end

---@param id string|integer
function mod.selectMenu(id)
	local root = gui.root

	local index
	if type(id) == "string" then
		index = mod.menuIDToIndex(id)
	else
		index = id
		id = mod.menuDefs[index].id
	end

	local oldMenuDef = mod.menuDefs[mod.client.selectedMenuID]
	if oldMenuDef and oldMenuDef.destroy then
		oldMenuDef.destroy()
	end

	if root.menu then
		root.menu:detach()
	end

	local menu = mod.menuDefs[index].build()
	menu:attach(root)
	root.menu = menu

	root.menuList:selectElement(index, false)

	mod.client.selectedMenuID = id
end

function mod.selectNextMenu()
	local menuList = gui.root.menuList

	if menuList.selectedElementIndex < #mod.menuDefs then
		mod.selectMenu(menuList.selectedElementIndex + 1)
	else
		mod.selectMenu(1)
	end
end

function mod.selectPreviousMenu()
	local menuList = gui.root.menuList

	if menuList.selectedElementIndex > 1 then
		mod.selectMenu(menuList.selectedElementIndex - 1)
	else
		mod.selectMenu(#mod.menuDefs)
	end
end

function mod.focusMenu()
	local menuDef = mod.menuDefs[mod.client.selectedMenuID]

	if menuDef.focus then
		menuDef.focus(gui.root.menu)
	else
		gui.root.menu:focus()
	end

	local menuIndex = mod.menuIDToIndex(mod.client.selectedMenuID)
	gui.root.menuList:selectElement(menuIndex, true)
end

function mod.focusMenuList()
	local list = gui.root.menuList
	list:focus()
	list:selectElement(list.selectedElementIndex, false)
end

function mod.openMenu()
	mod.setUIMode("menu")
end

---@param key keyevent_t
---@return boolean
function mod.handleMenuStandardKeyPress(key)
	if key.repeated then return false end

	local keyName = key.name
	if mod.isKeyBoundToUICommand(keyName, "open_menu") then
		mod.closeUI()
		return true
	elseif mod.client.menuOpen and (
		keyName == "escape"
		or mod.isKeyBoundToUICommand(keyName, "cancel")
	) then
		mod.focusMenuList()
		return true
	elseif keyName == "tab" then
		if mod.client.menuOpen then
			if mod.client.shiftHeld then
				mod.selectPreviousMenu()
			else
				mod.selectNextMenu()
			end
			mod.focusMenu()
		end
		return true
	end

	return false
end


mod.addUIMode("menu", {
	useMouse = true,

	enter = function()
		---@type itemapi.MenuListUI
		local menuList = mod.MenuListUI {
			autoLeft = "SnapToParentRight",
			autoTop = "Center",
			snapDist = 8*FU
		}

		menuList:attach(gui.root)
		gui.root.menuList = menuList

		mod.selectMenu("inventory")
		mod.focusMenu()

		-- gui.instance.mouse:enable()
		mod.disableGameKeys()

		mod.client.menuOpen = true
	end,

	leave = function()
		local root = gui.root
		local menuDef = mod.menuDefs[mod.client.selectedMenuID]

		if menuDef.destroy then
			menuDef.destroy()
		end

		root.menu = root.menu:detach()
		root.menuList = root.menuList:detach()

		gui.instance.mouse:disable()

		mod.client.menuOpen = false
		mod.client.selectedMenuID = nil
	end
})
