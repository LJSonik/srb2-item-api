---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Label : ljgui.Item
local Label, base = gui.class(gui.Item)
gui.Label = Label


Label.defaultWidth, Label.defaultHeight = 32*FU, 4*FU

Label.defaultStyle = {
	bgColor = 26,
	margin = { FU, FU, FU, FU }
}


function Label:__init(props)
	base.__init(self)

	self.debug = "Label"

	if type(props) == "string" then
		props = { text = props }
	end

	if props then
		self:build(props)
	end
end

function Label:build(props)
	self:setText(props.text)
	self:applyProps(props)
end

---@param text string
function Label:setText(text)
	self.text = text
end

---@param v videolib
function Label:draw(v)
	local l, t = self.cachedLeft, self.cachedTop

	gui.drawBaseItemStyle(v, self, self.style)
	gui.drawString(v, l, t, self.text)

	self:drawChildren(v)
end
