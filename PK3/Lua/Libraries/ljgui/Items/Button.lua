---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.ButtonStyle : ljgui.ItemStyle
---@field pointed ljgui.ItemStyle
---@field pressed ljgui.ItemStyle


---@class ljgui.Button : ljgui.Item
---@field style ljgui.ButtonStyle
---@field pointed boolean
---@field pressed boolean
---@field text string
local Button = gui.addItem("Button", {
	setup = function(self)
		self.pointed = false
		self.pressed = false

		self:addEvent("LeftMousePress", self.onLeftMousePress)
		self:addEvent("MouseEnter", self.onMouseEnter)
		self:addEvent("MouseLeave", self.onMouseLeave)
		self:addEvent("KeyPress", self.onKeyPress)
	end,

	applyCustomProps = function(self, props)
		if props.action then
			self:addEvent("Trigger", props.action)
		end

		if props.text then
			self:setText(props.text)
		end
	end,
})
gui.Button = Button


Button.defaultWidth, Button.defaultHeight = 64*FU, 8*FU

---@type ljgui.ButtonStyle
Button.defaultStyle = {
	margin = { FU, FU, FU, FU },

	bgColor = 31,
	bdSize = 1*FU,
	bdColor = 0,

	pointed = {
		bgColor = 16,
		bdSize = 1*FU,
		bdColor = 0
	},

	pressed = {
		bgColor = 0,
		bdSize = 1*FU,
		bdColor = 0
	}
}


---@param text string
function Button:setText(text)
	self.text = text
end

function Button:onLeftMousePress()
	self.pressed = true
	self:addEvent("LeftMouseRelease", self.onLeftMouseRelease)
	return true
end

---@param mouse ljgui.Mouse
function Button:onLeftMouseRelease(mouse)
	self.pressed = false
	self:removeEvent("LeftMouseRelease", self.onLeftMouseRelease)

	if mouse:isInsideItem(self) then
		gui.instance.eventManager:callItemEvent(self, "Trigger")
	end
end

function Button:onMouseEnter()
	self.pointed = true
end

function Button:onMouseLeave()
	self.pointed = false
end

---@param key keyevent_t
---@return boolean?
function Button:onKeyPress(key)
	if key.name ~= "enter" then return nil end
	gui.instance.eventManager:callItemEvent(self, "Trigger")
	return true
end

function Button:draw(v)
	local style
	if self.pressed then
		style = self.style.pressed
	elseif self.pointed then
		style = self.style.pointed
	else
		style = self.style
	end

	gui.drawBaseItemStyle(v, self, style)

	local text = self.text
	if text then
		local x = self.cachedLeft + self.width / 2
		local y = self.cachedTop + self.height / 2 - 2*FU
		v.drawString(x, y, text, V_ALLOWLOWERCASE, "small-fixed-center") -- !!!
	end
end
