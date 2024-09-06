---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.CheckboxStyle : ljgui.ItemStyle
---@field checkColor integer


---@class ljgui.Checkbox : ljgui.Item
---@field style ljgui.CheckboxStyle
---@field checked boolean
---@field pressed boolean
local Checkbox, base = gui.class(gui.Item)
gui.Checkbox = Checkbox


Checkbox.defaultWidth, Checkbox.defaultHeight = 8*FU, 8*FU

---@type ljgui.CheckboxStyle
Checkbox.defaultStyle = {
	bgColor = 31,
	bdSize = 1*FU,
	bdColor = 0,
	checkColor = 112,
}


function Checkbox:__init(props)
	base.__init(self)

	self.debug = "Checkbox"

	if props then
		self:build(props)
	end

	self.pressed = false

	self:addEvent("LeftMousePress", self.onLeftMousePress)
	self:addEvent("KeyPress", self.onKeyPress)
end

function Checkbox:build(props)
	self:applyProps(props)

	if props.checked then
		self.checked = true
	end
end

function Checkbox:onLeftMousePress()
	self.pressed = true
	self:addEvent("LeftMouseRelease", self.onLeftMouseRelease)
	return true
end

---@param mouse ljgui.Mouse
function Checkbox:onLeftMouseRelease(mouse)
	self.pressed = false
	self:removeEvent("LeftMouseRelease", self.onLeftMouseRelease)

	if mouse:isInsideItem(self) then
		self.checked = not $
		gui.instance.eventManager:callItemEvent(self, "Change", self.checked)
	end
end

---@param key keyevent_t
---@return boolean
function Checkbox:onKeyPress(key)
	if key.name ~= "enter" then return end
	self.checked = not $
	gui.instance.eventManager:callItemEvent(self, "Change", self.checked)
	return true
end

function Checkbox:draw(v)
	local style = self.style

	gui.drawBaseItemStyle(v, self, style)

	if self.checked then
		local l, t = self.cachedLeft, self.cachedTop
		local w, h = self.width, self.height

		local bs = style.bdSize or 0
		local pad = bs + FU

		gui.drawFill(v, l + pad, t + pad, w - pad * 2, h - pad * 2, style.checkColor)
	end

	self:drawChildren(v)
end
