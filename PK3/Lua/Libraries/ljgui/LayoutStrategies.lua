---@class ljgui
local gui = ljrequire "ljgui.common"


gui.addLayoutStrategy("one_per_line", {
	dependencies = {
		{ "children", "height" },
	},

	compute = function(item)
		local rules = item.layoutRules
		local y = rules.topPadding

		for _, child in item.children:iterate() do
			local cr = child.layoutRules
			if not cr then continue end

			local mode = cr.placementMode
			if mode == "exclude" then continue end

			if mode == "include" then
				child:moveRaw(rules.leftPadding + cr.leftMargin, y + cr.topMargin)
			end

			y = y + child.height + cr.topMargin + cr.bottomMargin
		end
	end
})
