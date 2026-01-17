---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Label : ljgui.Item
local Label = gui.addItem("Label", {
	transformProps = function(props)
		if type(props) == "string" then
			return { text = props }
		else
			return props
		end
	end,

	applyCustomProps = function(self, props)
		if props.text then
			self:setText(props.text)
		end
	end,
})
gui.Label = Label


Label.defaultWidth, Label.defaultHeight = 32*FU, 4*FU

Label.defaultStyle = {
	bgColor = 26,
	margin = { FU, FU, FU, FU }
}


---@param text string
function Label:setText(text)
	self.text = text
end

---@param v videolib
function Label:draw(v)
	local l, t = self.cachedLeft, self.cachedTop

	gui.drawBaseItemStyle(v, self, self.style)
	gui.drawString(v, l, t, self.text)
end
