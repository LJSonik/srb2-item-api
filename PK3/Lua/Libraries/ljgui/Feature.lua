---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.FeatureDef


---@class ljgui.Feature
---@field def ljgui.FeatureDef


---@param name? string
---@param def? ljgui.FeatureDef
---@return ljgui.Feature
function gui.addFeature(name, def)
	def = $ or {}

	local class = gui.class(gui.Feature)

	class.def = def

	function class:__init()
	end

	return class
end

---@param feature ljgui.Feature
---@param class ljgui.Item
function gui.includeFeatureInClass(feature, class)
	for k, v in pairs(feature) do
		if not gui.classSpecialFields[k] and k ~= "def" then
			class[k] = v
		end
	end
end
