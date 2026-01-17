-- ---@class ljgui
-- local gui = ljrequire "ljgui.common"


-- gui.addAutoLayoutStrategy({
-- 	id = "one_per_line",
-- 	usedAttributes = { "height" },
-- 	generator = function(item)
-- 		local rules = item.layoutRules
-- 		local y = rules.topPadding

-- 		for _, child in item.children:iterate() do
-- 			local cr = child.layoutRules
-- 			if not cr then continue end

-- 			local mode = cr.placementMode
-- 			if mode == "exclude" then continue end

-- 			if mode == "include" then
-- 				child:moveRaw(rules.leftPadding + cr.leftMargin, y + cr.topMargin)
-- 			end

-- 			y = y + child.height + cr.topMargin + cr.bottomMargin
-- 		end
-- 	end
-- })

-- gui.addAutoPositionStrategy({
-- 	id = "center",
-- 	type = "parent",
-- 	usedAttributes = { "width", "height" },
-- 	usedSelfAttributes = { "width", "height" },
-- 	generator = function(item)
-- 		local parent = item.parent
-- 		return
-- 			(parent.width - item.width) / 2,
-- 			(parent.height - item.height) / 2
-- 	end
-- })

-- gui.addAutoPositionStrategy({
-- 	id = "snap_to_parent_left",
-- 	type = "parent",
-- 	usedAttributes = { "width" },
-- 	usedSelfAttributes = { "width" },
-- 	params = { "snapDist" },
-- 	generator = function(item)
-- 		local parent = item.parent
-- 		local rules = item.layoutRules
-- 		local pRules = parent.layoutRules

-- 		local dist = rules.snapDist or 0

-- 		return (pRules and pRules.leftPadding or 0) + rules.leftMargin + dist, nil
-- 	end
-- })

-- gui.addAutoPositionStrategy({
-- 	id = "snap_to_parent_top",
-- 	type = "parent",
-- 	usedAttributes = { "height" },
-- 	usedSelfAttributes = { "height" },
-- 	params = { "snapDist" },
-- 	generator = function(item)
-- 		local parent = item.parent
-- 		local rules = item.layoutRules
-- 		local pRules = parent.layoutRules

-- 		local dist = rules.snapDist or 0

-- 		return nil, (pRules and pRules.topPadding or 0) + rules.topMargin + dist
-- 	end
-- })

-- gui.addAutoPositionStrategy({
-- 	id = "snap_to_parent_right",
-- 	type = "parent",
-- 	usedAttributes = { "width" },
-- 	usedSelfAttributes = { "width" },
-- 	params = { "snapDist" },
-- 	generator = function(item)
-- 		local parent = item.parent
-- 		local rules = item.layoutRules
-- 		local pRules = parent.layoutRules

-- 		local dist = rules.snapDist or 0

-- 		return parent.width - (pRules and pRules.rightPadding or 0) - item.width - rules.rightMargin - dist, nil
-- 	end
-- })


-- gui.addAutoPositionStrategy({
-- 	id = "snap_to_parent_bottom",
-- 	type = "parent",
-- 	usedAttributes = { "height" },
-- 	usedSelfAttributes = { "height" },
-- 	params = { "snapDist" },
-- 	generator = function(item)
-- 		local parent = item.parent
-- 		local rules = item.layoutRules
-- 		local pRules = parent.layoutRules

-- 		local dist = rules.snapDist or 0

-- 		return nil, parent.height - (pRules and pRules.bottomPadding or 0) - item.height - rules.bottomMargin - dist
-- 	end
-- })

-- gui.addAutoSizeStrategy({
-- 	id = "fit_parent",
-- 	type = "parent",
-- 	usedAttributes = { "width", "height" },
-- 	params = { "sizeRatio" },
-- 	generator = function(item)
-- 		local parent = item.parent
-- 		local rules = item.layoutRules
-- 		local pRules = parent.layoutRules

-- 		local ratio = item.layoutRules.sizeRatio or FU

-- 		local hBorder = rules.leftMargin + rules.rightMargin
-- 		local vBorder = rules.topMargin + rules.bottomMargin
-- 		if pRules then
-- 			hBorder = $ + pRules.leftPadding + pRules.rightPadding
-- 			vBorder = $ + pRules.topPadding + pRules.bottomPadding
-- 		end

-- 		local w = FixedMul(parent.width - hBorder, ratio)
-- 		local h = FixedMul(parent.height - vBorder, ratio)

-- 		return w, h
-- 	end
-- })

-- gui.addAutoSizeStrategy({
-- 	id = "fit_children",
-- 	type = "children",
-- 	usedAttributes = { "left", "top", "width", "height" },
-- 	generator = function(item)
-- 		local getBaseBorder = (item.getBaseBorder or gui.getDefaultBaseBorder)
-- 		local baseL, baseT, baseR, baseB = getBaseBorder(item)

-- 		local rules = item.layoutRules
-- 		local rightmost, bottommost = baseL + rules.leftPadding, baseT + rules.topPadding

-- 		for _, child in item.children:iterate() do
-- 			local childRules = child.layoutRules

-- 			local r = child.left + child.width + childRules.rightMargin
-- 			if r > rightmost then
-- 				rightmost = r
-- 			end

-- 			local b = child.top + child.height + childRules.bottomMargin
-- 			if b > bottommost then
-- 				bottommost = b
-- 			end
-- 		end

-- 		return
-- 			rightmost + baseR + rules.rightPadding,
-- 			bottommost + baseB + rules.bottomPadding
-- 	end
-- })
