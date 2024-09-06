---@class ljgui
local gui = ljrequire "ljgui.common"


---@type table<string, fun(item: ljgui.Item, rules: ljgui.LayoutRules)>
local attrCalculators = {
	layout = function(item, rules)
		rules.autoLayout.generator(item)
	end,
	left = function(item, rules)
		local l, _ = rules.autoLeft.generator(item)
		item:moveRaw(l, nil)
	end,
	top = function(item, rules)
		local _, t = rules.autoTop.generator(item)
		item:moveRaw(nil, t)
	end,
	width = function(item, rules)
		local w, _ = rules.autoWidth.generator(item)
		item:resizeRaw(w, nil)
	end,
	height = function(item, rules)
		local _, h = rules.autoHeight.generator(item)
		item:resizeRaw(nil, h)
	end,
	contentWidth = function(item, rules)
		local w, _ = rules.autoContentWidth.generator(item)
		item:resizeContentRaw(w, nil)
	end,
	contentHeight = function(item, rules)
		local _, h = rules.autoContentHeight.generator(item)
		item:resizeContentRaw(nil, h)
	end,
}

-- local function prdep(srcItem, srcAttr, dstItem, dstAttr)
-- 	pr(("%s.%ss"):format(
-- 		(srcItem.id or "?"),
-- 		srcAttr,
-- 		(dstItem.id or "?"),
-- 		dstAttr
-- 	))

-- 	-- enterfunc "DEP {"
-- 	-- 	srcItem:dumpInfo()
-- 	-- 	pr(srcAttr)
-- 	-- 	pr "-->"
-- 	-- 	dstItem:dumpInfo()
-- 	-- 	pr(dstAttr)
-- 	-- exitfunc "}"
-- end

-- Mutually recursive functions
local findItemDependentAttributes, findDependentAttributes

---@param dstItem ljgui.Item
---@param depAttr ljgui.Set<string>
---@param attrRootDists table
---@param rootDist integer
function findDependentAttributes(dstItem, depAttr, attrRootDists, rootDist)
	for dstAttr, _ in pairs(depAttr) do
		local dstRootDists = dstItem.attributeRootDistances
		dstRootDists[dstAttr] = $ or 0

		if rootDist > dstRootDists[dstAttr] then
			dstRootDists[dstAttr] = $ + 1
			local i = #attrRootDists + 1
			attrRootDists[i] = { dstItem, dstAttr, rootDist, i }
			findItemDependentAttributes(dstItem, dstAttr, attrRootDists, rootDist + 1)
		end
	end
end

---@param dstItem ljgui.Item
---@param attrRootDists table
---@param rootDist integer
local function findLayoutDependentAttributes(dstItem, attrRootDists, rootDist)
	local dstRootDists = dstItem.attributeRootDistances
	dstRootDists["layout"] = $ or 0

	if rootDist > dstRootDists["layout"] then
		dstRootDists["layout"] = $ + 1
		local i = #attrRootDists + 1
		attrRootDists[i] = { dstItem, "layout", rootDist, i }

		for _, child in dstItem.children:iterate() do
			if child.layoutRules then
				findItemDependentAttributes(child, "left", attrRootDists, rootDist + 1)
				findItemDependentAttributes(child, "top", attrRootDists, rootDist + 1)

				--- !!! Probably a bug?
				-- findItemDependentAttributes(dstItem, "position", attrRootDists, rootDist + 1)
			end
		end
	end
end

---@param srcItem ljgui.Item
---@param srcAttr string
---@param attrRootDists table
---@param rootDist integer
function findItemDependentAttributes(srcItem, srcAttr, attrRootDists, rootDist)
	if srcItem.layoutRules then
		local depAttr = srcItem.layoutRules.selfDependentAttributes[srcAttr]
		if depAttr then
			findDependentAttributes(srcItem, depAttr, attrRootDists, rootDist)
		end
	end

	for _, child in srcItem.children:iterate() do
		if child.layoutRules then
			local depAttr = child.layoutRules.parentDependentAttributes[srcAttr]
			if depAttr then
				findDependentAttributes(child, depAttr, attrRootDists, rootDist)
			end
		end
	end

	local parent = srcItem.parent
	if parent then
		local parentRules = parent.layoutRules

		if parentRules then
			local depAttr = parentRules.childDependentAttributes[srcAttr]
			if depAttr then
				findDependentAttributes(parent, depAttr, attrRootDists, rootDist)
			end

			local autoLayout = parentRules.autoLayout
			if autoLayout and autoLayout.usedAttributesSet[srcAttr] then
				findLayoutDependentAttributes(parent, attrRootDists, rootDist)
			end
		end
	end

	if srcItem.layoutRules then
		local autoLayout = srcItem.layoutRules.autoLayout
		if autoLayout and autoLayout.usedSelfAttributesSet[srcAttr] then
			findLayoutDependentAttributes(srcItem, attrRootDists, rootDist)
		end
	end
end

local function compareAttrRootDistances(distInfo1, distInfo2)
	local dist1, dist2 = distInfo1[3], distInfo2[3]
	if dist1 == dist2 then
		return distInfo1[4] <= distInfo2[4]
	else
		return dist1 <= dist2
	end
end

function gui.propagateModifiedItemAttributes()
	local modifiedItems = gui.instance.itemsWithModifiedAttributes

	local attrRootDists = {}
	for item, _ in pairs(modifiedItems) do
		for attr, _ in pairs(item.modifiedAttributes) do
			findItemDependentAttributes(item, attr, attrRootDists, 1)
		end
	end

	table.sort(attrRootDists, compareAttrRootDistances)

	for i = 1, #attrRootDists do
		local attrRootDist = attrRootDists[i]
		local item = attrRootDist[1] ---@type ljgui.Item
		local attr = attrRootDist[2]
		local rules = item.layoutRules

		attrCalculators[attr](item, rules)

		item.attributeRootDistances[attr] = nil
	end

	gui.instance.itemsWithModifiedAttributes = {}
end
