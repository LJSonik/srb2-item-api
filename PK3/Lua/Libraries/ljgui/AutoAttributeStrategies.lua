---@class ljgui
local gui = ljrequire "ljgui.common"


gui.addAutoSizeStrategy("fit_children", {
	dependencyType = "children",

	widthDependencies = {
		{ "children", "left" },
		{ "children", "width" },
	},

	heightDependencies = {
		{ "children", "top" },
		{ "children", "height" },
	},

	compute = function(item)
		local getBaseBorder = (item.getBaseBorder or gui.getDefaultBaseBorder)
		local baseL, baseT, baseR, baseB = getBaseBorder(item)

		local rules = item.layoutRules
		local rightmost, bottommost = baseL + rules.leftPadding, baseT + rules.topPadding

		for _, child in item.children:iterate() do
			local childRules = child.layoutRules

			local r = child.left + child.width + childRules.rightMargin
			if r > rightmost then
				rightmost = r
			end

			local b = child.top + child.height + childRules.bottomMargin
			if b > bottommost then
				bottommost = b
			end
		end

		return
			rightmost + baseR + rules.rightPadding,
			bottommost + baseB + rules.bottomPadding
	end
})

gui.addAutoPositionStrategy("center", {
	dependencyType = "parent",

	leftDependencies = {
		{ "self", "width" },
		{ "parent", "width" },
	},

	topDependencies = {
		{ "self", "height" },
		{ "parent", "height" },
	},

	compute = function(item)
		local parent = item.parent
		return
			(parent.width - item.width) / 2,
			(parent.height - item.height) / 2
	end
})

gui.addAutoPositionStrategy("snap_to_parent_left", {
	dependencyType = "parent",
	params = { "snapDist" },

	compute = function(item)
		local parent = item.parent
		local rules = item.layoutRules
		local pRules = parent.layoutRules

		local dist = item.autoAttributes.left.snapDist or 0

		return (pRules and pRules.leftPadding or 0) + rules.leftMargin + dist, nil
	end
})

gui.addAutoPositionStrategy("snap_to_parent_top", {
	dependencyType = "parent",
	params = { "snapDist" },

	compute = function(item)
		local parent = item.parent
		local rules = item.layoutRules
		local pRules = parent.layoutRules

		local dist = item.autoAttributes.top.snapDist or 0

		return nil, (pRules and pRules.topPadding or 0) + rules.topMargin + dist
	end
})

gui.addAutoPositionStrategy("snap_to_parent_right", {
	dependencyType = "parent",
	params = { "snapDist" },

	leftDependencies = {
		{ "self", "width" },
		{ "parent", "width" },
	},

	compute = function(item)
		local parent = item.parent
		local rules = item.layoutRules
		local pRules = parent.layoutRules

		local dist = item.autoAttributes.left.snapDist or 0

		return parent.width - (pRules and pRules.rightPadding or 0) - item.width - rules.rightMargin - dist, nil
	end
})


gui.addAutoPositionStrategy("snap_to_parent_bottom", {
	dependencyType = "parent",
	params = { "snapDist" },

	topDependencies = {
		{ "self", "height" },
		{ "parent", "height" },
	},

	compute = function(item)
		local parent = item.parent
		local rules = item.layoutRules
		local pRules = parent.layoutRules

		local dist = item.autoAttributes.top.snapDist or 0

		return nil, parent.height - (pRules and pRules.bottomPadding or 0) - item.height - rules.bottomMargin - dist
	end
})

gui.addAutoSizeStrategy("fit_parent", {
	dependencyType = "parent",
	widthDependency = { "parent", "width" },
	heightDependency = { "parent", "height" },
	params = { "sizeRatio" },

	compute = function(item)
		local parent = item.parent
		local rules = item.layoutRules
		local pRules = parent.layoutRules

		local wRatio = item.autoAttributes.width and item.autoAttributes.width.sizeRatio or FU
		local hRatio = item.autoAttributes.height and item.autoAttributes.height.sizeRatio or FU

		local hBorder = rules.leftMargin + rules.rightMargin
		local vBorder = rules.topMargin + rules.bottomMargin
		if pRules then
			hBorder = $ + pRules.leftPadding + pRules.rightPadding
			vBorder = $ + pRules.topPadding + pRules.bottomPadding
		end

		local w = FixedMul(parent.width - hBorder, wRatio)
		local h = FixedMul(parent.height - vBorder, hRatio)

		return w, h
	end
})
