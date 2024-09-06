---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.DropdownStyle : ljgui.ItemStyle
---@field pointed ljgui.ItemStyle


---@class ljgui.Dropdown : ljgui.Item
---@field style ljgui.DropdownStyle
---@field pointed boolean
---@field text string
local Dropdown, base = gui.class(gui.Item)
gui.Dropdown = Dropdown


Dropdown.defaultWidth, Dropdown.defaultHeight = 64*FU, 8*FU

---@type ljgui.DropdownStyle
Dropdown.defaultStyle = {
	bgColor = 31,
	bdSize = 1*FU,
	bdColor = 0,

	pointed = {
		bgColor = 16,
		bdSize = 1*FU,
		bdColor = 0
	}
}


function Dropdown:__init(props)
	base.__init(self)

	self.debug = "Dropdown"

	if props then
		self:build(props)
	end

	self.pointed = false

	self:addEvent("LeftMousePress", self.onLeftMousePress)
	self:addEvent("MouseEnter", self.onMouseEnter)
	self:addEvent("MouseLeave", self.onMouseLeave)
	self:addEvent("Unroot", self.onUnroot)
end

function Dropdown:build(props)
	self:applyProps(props)

	self:setText(props.text)

	self:setOptions(props.options)
	self:setListStyle(props.listStyle)
end

---@param text string
function Dropdown:setText(text)
	self.text = text
end

---@param options table
function Dropdown:setOptions(options)
	self.options = options
end

---@param style ljgui.ItemStyle
function Dropdown:setListStyle(style)
	self.listStyle = style
end

function Dropdown:onLeftMousePress()
	if self.listBox then
		self.listBox = self.listBox:detach()
		self:focus()
		return
	end

	self.listBox = gui.spawnListBoxAtItem(self, gui.root, {
		options = self.options,
		style = self.listStyle
	})

	self.listBox:addEvent("Change", function(_, value)
		gui.instance.eventManager:callItemEvent(self, "Change", value)
		self.listBox = self.listBox:detach()
		self:focus()
	end)

	self.listBox.grid:focus()

	return true
end

function Dropdown:onMouseEnter()
	self.pointed = true
end

function Dropdown:onMouseLeave()
	self.pointed = false
end

function Dropdown:onUnroot()
	if self.listBox then
		self.listBox = self.listBox:detach()
	end
end

function Dropdown:draw(v)
	local style
	if self.pointed then
		style = self.style.pointed
	else
		style = self.style
	end

	gui.drawBaseItemStyle(v, self, style)

	local text = self.text
	if text then
		local x = self.cachedLeft + self.width / 2
		local y = self.cachedTop + self.height / 2 - 2*FU
		v.drawString(x, y, text, V_ALLOWLOWERCASE, "small-fixed-center") // !!!
	end

	self:drawChildren(v)
end
