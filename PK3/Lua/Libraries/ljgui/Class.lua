---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Class
---@field class ljgui.Class
---@field base ljgui.Class
---@field __getters table<string, ljgui.Getter>
---@field __setters table<string, ljgui.Setter>


---@alias ljgui.Getter<C, V> fun(class: C): V
---@alias ljgui.Setter<C, V> fun(class: C, value: V)


gui.classSpecialFields = gui.arrayToSet{
	"class",
	"base",

	"__getters",
	"__setters",

	"__index",
	"__newindex",
}

---@generic P
---@param parent? P
---@return ljgui.Class
---@return P
function gui.class(parent)
	local class = {}
	local getters = {}
	local setters = {}

	if parent then
		for k, v in pairs(parent) do
			class[k] = v
		end
		for k, getter in pairs(parent.__getters) do
			getters[k] = getter
		end
		for k, setter in pairs(parent.__setters) do
			setters[k] = setter
		end
	end

	class.class = class
	class.base = parent
	class.__getters = getters
	class.__setters = setters

	class.__index = function(object, k)
		local v = class[k]
		if v ~= nil then
			return v
		end

		local getter = getters[k]
		if getter then
			return getter(object)
		else
			return nil
		end
	end

	class.__newindex = function(object, k, v)
		local setter = setters[k]
		if setter then
			setter(object, v)
		else
			rawset(object, k, v)
		end
	end

	setmetatable(class, {
		__call = function(_, ...)
			local object = setmetatable({}, class)

			if object.__init then
				object:__init(...)
			end

			return object
		end
	})

	return class, parent
end

---@generic C : ljgui.Class
---@generic V
---@param class C
---@param name string
---@param callback ljgui.Getter<C, V>
function gui.getter(class, name, callback)
	class.__getters[name] = callback
end

---@generic C : ljgui.Class
---@generic V
---@param class C
---@param name string
---@param callback ljgui.Setter<C, V>
function gui.setter(class, name, callback)
	class.__setters[name] = callback
end

---@generic C : ljgui.Class
---@generic V
---@param class C
---@param name string
---@param getter ljgui.Getter<C, V>
---@param setter ljgui.Setter<C, V>
function gui.getterSetter(class, name, getter, setter)
	gui.getter(class, name, getter)
	gui.setter(class, name, setter)
end

---@param class ljgui.Class
---@param name string
function gui.basicGetter(class, name)
	local internalName = "_" .. name
	class.__getters[name] = function(object)
		return object[internalName]
	end
end

---@param class ljgui.Class
---@param name string
function gui.basicSetter(class, name)
	local internalName = "_" .. name
	class.__setters[name] = function(object, value)
		object[internalName] = value
	end
end
