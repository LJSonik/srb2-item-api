---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


---@class itemapi.MenuListUI : ljgui.Rectangle
local MenuList, base = gui.class(gui.Rectangle)
mod.MenuListUI = MenuList


---@param menuFocused boolean
function MenuList:selectElement(index, menuFocused)
	if self.selectedElementIndex then
		local old = self.children:get(self.selectedElementIndex)
		old:updateStyle({ bgColor = 31 })
	end

	self.selectedElementIndex = index

	local new = self.children:get(index)
	new:updateStyle({ bgColor = not menuFocused and 16 or 0 })
end

---@param key keyevent_t
function MenuList:onKeyPress(key)
	local keyName = key.name

	if keyName == "escape"
	or mod.isKeyBoundToUICommand(keyName, "cancel")
	or mod.isKeyBoundToUICommand(keyName, "open_menu") then
		mod.closeUI()
		return true
	elseif keyName == "enter"
	or mod.isKeyBoundToUICommand(keyName, "confirm")
	or mod.isKeyBoundToUICommand(keyName, "open_action_selection") then
			mod.focusMenu()
		return true
	elseif keyName == "up arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_FORWARD) then
		if self.selectedElementIndex > 1 then
			mod.selectMenu(self.selectedElementIndex - 1)
		else
			mod.selectMenu(#mod.menuDefs)
		end

		return true
	elseif keyName == "down arrow"
	or mod.isKeyBoundToGameControl(keyName, GC_BACKWARD) then
		if self.selectedElementIndex < #mod.menuDefs then
			mod.selectMenu(self.selectedElementIndex + 1)
		else
			mod.selectMenu(1)
		end

		return true
	end

	return false
end

---@param element ljgui.Button
local function onElementTrigger(element)
	mod.selectMenu(element.menuID)
	mod.focusMenu()
end

function MenuList:__init(props)
	local children = {}
	for _, def in ipairs(mod.menuDefs) do
		table.insert(children, gui.Button {
			var_menuID = def.id,

			text = def.name,
			width = 48*FU,

			onTrigger = onElementTrigger,
		})
	end

	base.__init(self, {
		autoLayout = "OnePerLine",
		autoSize = "FitChildren",
		onKeyPress = self.onKeyPress,

		children = children
	})

	self:applyProps(props)
end
