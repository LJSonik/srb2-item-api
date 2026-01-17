---@class ljgui
local gui = ljrequire "ljgui.common"


---@param item ljgui.Item
local function applyStyleRules(item)
	for _, child in item.children:iterate() do
		applyStyleRules(child)
	end

	local parent = item
	while parent do
		if props and props.styleRules then
			local rules = props.styleRules

			for i = 1, #rules do
				local rule = rules[i]

				if rule.class == item.class then
					item:setStyle(rule)
					return
				end
			end
		end

		parent = parent.parent
	end
end
gui.applyStyleRules = applyStyleRules
