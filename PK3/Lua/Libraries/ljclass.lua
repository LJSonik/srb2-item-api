local ljclass = {}


---@class ljclass.Class
---@field __class ljclass.Class
---@field __getters table<string, ljclass.Getter>
---@field __setters table<string, ljclass.Setter>

---@alias ljclass.Getter<C, V> fun(class: C): V
---@alias ljclass.Setter<C, V> fun(class: C, value: V)


---@generic P
---@param parent? P
---@param registered boolean
---@return ljclass.Class
---@return P
local function createClass(parent, registered)
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

	class.__class = class
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

	if registered then
		registerMetatable(class)
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

---@generic P
---@param parent? P
---@return ljclass.Class
---@return P
function ljclass.class(parent)
	return createClass(parent, true)
end

---@generic P
---@param parent? P
---@return ljclass.Class
---@return P
function ljclass.localclass(parent)
	return createClass(parent, false)
end

---@generic C : ljclass.Class
---@generic V
---@param class C
---@param name string
---@param callback ljclass.Getter<C, V>
function ljclass.getter(class, name, callback)
	class.__getters[name] = callback
end

---@generic C : ljclass.Class
---@generic V
---@param class C
---@param name string
---@param callback ljclass.Setter<C, V>
function ljclass.setter(class, name, callback)
	class.__setters[name] = callback
end

---@generic C : ljclass.Class
---@generic V
---@param class C
---@param name string
---@param getter ljclass.Getter<C, V>
---@param setter ljclass.Setter<C, V>
function ljclass.getterSetter(class, name, getter, setter)
	ljclass.getter(class, name, getter)
	ljclass.setter(class, name, setter)
end

---@param class ljclass.Class
---@param name string
function ljclass.basicGetter(class, name)
	local internalName = "_" .. name
	class.__getters[name] = function(object)
		return object[internalName]
	end
end

---@param class ljclass.Class
---@param name string
function ljclass.basicSetter(class, name)
	local internalName = "_" .. name
	class.__setters[name] = function(object, value)
		object[internalName] = value
	end
end


return ljclass
