---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Image : ljgui.Item
local Image, base = gui.class(gui.Item)
gui.Image = Image


Image.defaultWidth, Image.defaultHeight = 32*FU, 32*FU

Image.defaultStyle = {
	margin = { FU, FU, FU, FU }
}


function Image:__init(props)
	base.__init(self)

	self.debug = "Image"

	if props then
		self:setImage(props.image)
		self:build(props)
	end
end

function Image:build(props)
	self:applyProps(props)
end

---@param image string
function Image:setImage(image)
	self.image = image
end

---@param v videolib
function Image:draw(v)
	local patch = v.cachePatch(self.image)
	local l, t = self.cachedLeft, self.cachedTop
	local scale = self.width / patch.width

	gui.drawPatchScaled(v, l, t, scale, patch)
	self:drawChildren(v)
end
