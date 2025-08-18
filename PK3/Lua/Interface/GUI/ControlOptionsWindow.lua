---@class itemapi
local mod = itemapi


local gui = ljrequire "ljgui"


-- Format: { GC_JUMP, "jump" }
local gameControlOptions = { { nil, "..." } }
for _, control in ipairs({
	GC_CUSTOM1,
	GC_CUSTOM2,
	GC_CUSTOM3,

	GC_JUMP,
	GC_SPIN,

	GC_FIRE,
	GC_FIRENORMAL,

	GC_TOSSFLAG,

	GC_FORWARD,
	GC_BACKWARD,

	GC_STRAFELEFT,
	GC_STRAFERIGHT,

	GC_TURNLEFT,
	GC_TURNRIGHT,

	GC_WEAPONNEXT,
	GC_WEAPONPREV,

	GC_WEPSLOT1,
	GC_WEPSLOT2,
	GC_WEPSLOT3,
	GC_WEPSLOT4,
	GC_WEPSLOT5,
	GC_WEPSLOT6,
	GC_WEPSLOT7,
	GC_WEPSLOT8,
	GC_WEPSLOT9,
	GC_WEPSLOT10,
}) do
	table.insert(gameControlOptions, { control, mod.gameControlNames[control] })
end


---@class itemapi.ControlOptionsWindow : ljgui.Window
local ControlOptionsWindow, base = gui.class(gui.Window)
mod.ControlOptionsWindow = ControlOptionsWindow


---@param grid ljgui.Item
---@param key keyevent_t
---@return boolean
local function onKeyPress(grid, key)
	if key.repeated then return false end

	local keyName = key.name

	if grid.waitingForKey then
		local element = grid.waitingForKey
		local cmdDef = mod.uiCommandDefs[element.uiCommandID]
		cmdDef.key = keyName
		grid.waitingForKey = nil
		element:update()
		return true
	end

	if mod.handleMenuStandardKeyPress(key) then
		return true
	-- elseif keyName == "enter" then
	-- 	local nav = grid.keyboardNav
	-- 	local elem = grid.children:get(nav.index)

	-- 	if nav.column == 2 then
	-- 		local cmdDef = mod.uiCommandDefs[nav.row]
	-- 		cmdDef.inputType = ($ == "short") and "long" or "short"
	-- 		elem:update()
	-- 	elseif nav.column == 3 then
	-- 		local options = {}
	-- 		for _, control in ipairs(gameControlOptions) do
	-- 			table.insert(options, {
	-- 				control[2],
	-- 				function()
	-- 					print "chose!"
	-- 				end
	-- 			})
	-- 		end

	-- 		gui.spawnListBoxAtItem(nav.item, grid, {
	-- 			options = options,
	-- 			style = { bgColor = 28 }
	-- 		})
	-- 	end

	-- 	return true
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

---@param cmd itemapi.UICommandDef
---@param grid ljgui.Item
---@param children ljgui.ItemList
local function makeLine(cmd, grid, children)
	-- Command name
	table.insert(children, gui.Label {
		-- text = ("%s: %s %s"):format(cmd.name, cmd.inputType, cmd.key:upper()),
		text = cmd.name,
		size = { 96*FU, 6*FU },

		margin = 1*FU,
		style = {}
	})

	-- Input type
	table.insert(children, gui.Button {
		size = { 32*FU, 6*FU },
		var_uiCommandID = cmd.id,

		margin = 1*FU,

		update = function(self)
			self:setText(cmd.inputType)
		end,

		action = function(self)
			local cmdDef = mod.uiCommandDefs[self.uiCommandID]
			cmdDef.inputType = ($ == "short") and "long" or "short"
			self:update()
		end
	})
	-- table.insert(children, gui.Label {
	-- 	size = { 32*FU, 6*FU },

	-- 	leftMargin = 1*FU,
	-- 	rightMargin = 1*FU,
	-- 	topMargin = 1*FU,
	-- 	bottomMargin = 1*FU,
	-- 	style = {},

	-- 	var_uiCommandID = cmd.id,

	-- 	update = function(self)
	-- 		self:setText(cmd.inputType)
	-- 	end,

	-- 	onKeyPress = function(self, key)
	-- 		if key.name ~= "enter" then return end

	-- 		local cmdDef = mod.uiCommandDefs[self.uiCommandID]
	-- 		cmdDef.inputType = ($ == "short") and "long" or "short"
	-- 		self:update()
	-- 	end
	-- })

	-- Key
	table.insert(children, gui.Dropdown {
		options = gameControlOptions,
		size = { 64*FU, 6*FU },
		var_uiCommandID = cmd.id,

		margin = 1*FU,

		listStyle = { bgColor = 28 },

		update = function(self)
			if self.parent.waitingForKey then
				self:setText("...")
			else
				local keyName = cmd.keyIsGameControl and mod.gameControlNames[cmd.key] or cmd.key
				self:setText(keyName:upper())
			end
		end,

		onChange = function(self, control)
			local cmdDef = mod.uiCommandDefs[self.uiCommandID]

			if control ~= nil then
				cmdDef.keyIsGameControl = true
				cmdDef.key = control
			else
				cmdDef.keyIsGameControl = false
				self.parent.waitingForKey = self
				self.parent:update()
			end

			self:update()
		end
	})
	-- table.insert(children, gui.Label {
	-- 	size = { 64*FU, 6*FU },

	-- 	leftMargin = 1*FU,
	-- 	rightMargin = 1*FU,
	-- 	topMargin = 1*FU,
	-- 	bottomMargin = 1*FU,
	-- 	style = {},

	-- 	var_uiCommandID = cmd.id,

	-- 	update = function(self)
	-- 		if self.parent.waitingForKey then
	-- 			self:setText("...")
	-- 		else
	-- 			self:setText(cmd.key:upper())
	-- 		end
	-- 	end,

	-- 	onKeyPress = function(self, key)
	-- 		if key.name ~= "enter" then return end

	-- 		local options = {}
	-- 		for _, control in ipairs(gameControlOptions) do
	-- 			table.insert(options, {
	-- 				control[2],
	-- 				function()
	-- 					print "chose!"
	-- 				end
	-- 			})
	-- 		end

	-- 		gui.spawnListBoxAtItem(self, self.parent, {
	-- 			options = options,
	-- 			style = { bgColor = 28 }
	-- 		})
	-- 	end
	-- })

	-- table.insert(children, gui.Button {
	-- 	text = ("%s: %s %s"):format(cmd.name, cmd.inputType, cmd.key:upper()),
	-- 	autoWidth = "fit_parent",
	-- 	margin = 2*FU,
	-- })
end

function ControlOptionsWindow:__init(props)
	local children = {}
	for _, cmd in ipairs(mod.uiCommandDefs) do
		makeLine(cmd, self, children)
	end

	self.grid = gui.Grid {
		fitParent = true,

		layout = "grid",
		layout_gridColumns = 3,

		onKeyPress = onKeyPress,

		children = children
	}

	base.__init(self, {
		size = { 256*FU, 160*FU },
		layout = "one_per_line",

		movable = false,
		resizable = false,

		self.grid
	})

	gui.addKeyboardNavigationToGrid(self.grid, onNavigation)

	self:applyProps(props)
end


mod.addMenu("control_options", {
	name = "Controls",

	build = function()
		---@type itemapi.ControlOptionsWindow
		return mod.ControlOptionsWindow {
			autoLeft = "snap_to_parent_left",
			autoLeft_snapDist = 8*FU,

			autoTop = "center",
		}
	end,

	destroy = function ()
		mod.saveControlOptions()
	end,

	focus = function(menu)
		menu.grid:focus()
	end
})
