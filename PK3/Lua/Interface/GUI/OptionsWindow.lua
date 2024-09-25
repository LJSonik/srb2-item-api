---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


---@class itemapi.OptionsWindow : ljgui.Window
local OptionsWindow, base = gui.class(gui.Window)
mod.OptionsWindow = OptionsWindow


---@param grid ljgui.Item
---@param key keyevent_t
---@return boolean
local function onKeyPress(grid, key)
	if key.repeated then return false end

	local keyName = key.name
	if mod.handleMenuStandardKeyPress(key) then
		return true
	end

	return false
end

---@param grid ljgui.Item
---@param oldElem ljgui.Item
---@param newElem ljgui.Item
local function onNavigation(grid, oldElem, newElem)
	if oldElem then
		oldElem:updateStyle({ bgColor = 31 })
	end

	if newElem then
		newElem:updateStyle({ bgColor = 16 })
	end
end

---@param option itemapi.Option
---@param grid ljgui.Item
---@param children ljgui.ItemList
local function makeLine(option, grid, children)
	-- Option name
	table.insert(children, gui.Label {
		text = option.name,
		size = { 96*FU, 6*FU },

		leftMargin = 1*FU,
		rightMargin = 1*FU,
		topMargin = 1*FU,
		bottomMargin = 1*FU,
	})

	-- Option value
	if option.type == "boolean" then
		table.insert(children, gui.Checkbox {
			checked = option.value,
			size = { 8*FU, 8*FU },
			var_optionID = option.id,

			margin = 1*FU,

			onChange = function(self, checked)
				option.value = checked
				self:update()
			end
		})
	end
end

function OptionsWindow:__init(props)
	local children = {}
	for _, option in ipairs(mod.options) do
		makeLine(option, self, children)
	end

	self.grid = gui.Grid {
		fitParent = true,
		autoLayout = "Grid",
		gridColumns = 2,

		onKeyPress = onKeyPress,

		children = children
	}

	base.__init(self, {
		size = { 256*FU, 160*FU },
		autoLayout = "OnePerLine",

		movable = false,
		resizable = false,

		self.grid,
		gui.VerticalScrollbar {
			target = self.grid,

			autoHeight = "FitParent",
			autoLeft = "SnapToParentRight"
		}
	})

	gui.addKeyboardNavigationToGrid(self.grid, onNavigation)

	self:applyProps(props)
end


mod.addMenu("options", {
	name = "Options",

	build = function()
		---@type itemapi.OptionsWindow
		return mod.OptionsWindow {
			autoLeft = "SnapToParentLeft",
			autoTop = "Center",
			snapDist = 8*FU
		}
	end,

	destroy = function ()
		mod.saveOptions()
	end,

	focus = function(menu)
		menu.grid:focus()
	end
})
