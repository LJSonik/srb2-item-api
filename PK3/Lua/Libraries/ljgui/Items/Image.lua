---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Image : ljgui.Item
local Image = gui.addItem("Image", {
	applyCustomProps = function(image, props)
		if props.image then
			image:setImage(props.image)
		end
	end
})
gui.Image = Image


Image.defaultWidth, Image.defaultHeight = 32*FU, 32*FU

Image.defaultStyle = {
	margin = { FU, FU, FU, FU }
}


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
end
