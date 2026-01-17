-- LJGUI by LJ Sonic


---@class ljgui
---@field instance ljgui.Instance
---@field root ljgui.Root
---@field v videolib
local gui = ljrequire "ljgui.common"


function gui.initialise()
	gui.instance = gui.Instance()
end

---@param v videolib
function gui.update(v)
	gui.instance:update(v)
end

---@param v videolib
function gui.draw(v)
	gui.instance:draw(v)
end


for _, filename in ipairs{
	"Util.lua",
	"Class.lua",
	"Instance.lua",
	"ItemList.lua",
	"AddItem.lua",
	"Props.lua",
	"Layout.lua",
	"Style.lua",
	"AutoAttribute.lua",
	"EventManager.lua",
	"DependencyManager.lua",
	"Mouse.lua",
	"Draw.lua",
	"Debug.lua",
	"LayoutStrategies.lua",
	"AutoAttributeStrategies.lua",
	"FlowLayout.lua",
	"GridLayout.lua",
	"Feature.lua",
	"KeyboardNavigation.lua",

	"Features/MovableByMouseDrag.lua",
	"Features/ResizableByMouseDrag.lua",

	"Items/Item.lua",
	"Items/Root.lua",
	"Items/Rectangle.lua",
	"Items/Grid.lua",
	"Items/Window.lua",
	"Items/Label.lua",
	"Items/Image.lua",
	"Items/Button.lua",
	"Items/TextInput.lua",
	"Items/Slider.lua",
	"Items/VerticalScrollbar.lua",
	"Items/ListBox.lua",
	"Items/Dropdown.lua",
	"Items/Checkbox.lua",
	"Items/PaletteColorPicker.lua",
} do
	dofile("Libraries/ljgui/" .. filename)
end


return gui
