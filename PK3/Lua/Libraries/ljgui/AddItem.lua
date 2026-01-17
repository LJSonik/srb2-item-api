---@class ljgui
local gui = ljrequire "ljgui.common"


local function applyBaseProps(item, class, props)
	local base = class.base
	if base == gui.Item then return end

	local def = class.def
	local baseDef = base.def

	local baseProps = def.baseProps
	if type(baseProps) == "function" then
		baseProps = baseProps(props, item)
	end

	applyBaseProps(item, base, baseProps)

	if baseDef.setup then
		baseDef.setup(item, baseProps)
	end

	item:applyProps(baseProps)
end

---@param name? string
---@param def? ljgui.ItemDef
---@return ljgui.Item
---@return ljgui.Item
function gui.addItem(name, def)
	def = $ or {}
	def.features = $ or {}
	def.baseProps = $ or {}

	local class, base = gui.class(def.base or gui.Item)

	class.def = def
	class.debug = name

	for _, feature in ipairs(def.features) do
		gui.includeFeatureInClass(feature, class)
	end

	---@param props ljgui.ItemProps
	function class:__init(props)
		gui.Item.__init(self)

		applyBaseProps(self, class, props)

		if def.transformProps then
			props = def.transformProps(props)
		end
		if def.setup then
			def.setup(self, props)
		end
		self:applyProps(props)
	end

	return class, base
end
