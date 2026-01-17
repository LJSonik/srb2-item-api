---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.TextInput : ljgui.Item
---@field text string
---@field shiftHeld boolean
local Input = gui.addItem("TextInput", {
	setup = function(self)
		self.text = "You're supposed to type something here, buddy..."
		self.shiftHeld = false
	end
})
gui.TextInput = Input


Input.defaultWidth, Input.defaultHeight = 96*FU, 4*FU

Input.defaultStyle = {
	margin = { FU, FU, FU, FU }
}


/*---@param key keyevent_t
function Input:onKeyDown(key)
	local keyName = key.name

	local char = gui.keyToCharacter(key, self.shiftHeld)
	if char then
		self.text = self.text .. char
	elseif keyName == "lshift" or keyName == "rshift" then
		self.shiftHeld = true
	elseif keyName == "backspace" then
		self.text = self.text:sub(1, -2)
	end
end

---@param keyEvent keyevent_t
function Input:onKeyUp(keyEvent)
	if keyEvent.name == "lshift" or keyEvent.name == "rshift" then
		self.shiftHeld = false
	end
end*/

---@param v videolib
function Input:drawText(v)
	gui.drawString(v, self.cachedLeft, self.cachedTop, self.text)
end

---@param v videolib
function Input:drawCursor(v)
	local textWidth = gui.stringWidth(v, self.text) * FU
	local blinkSpeed = TICRATE/2
	if leveltime / blinkSpeed % 2 == 0 then -- !!!
		gui.drawFill(v, self.cachedLeft + textWidth, self.cachedTop, FU, self.height, 0)
	end
end

---@param v videolib
function Input:draw(v)
	self:drawText(v)
	self:drawCursor(v)
end
