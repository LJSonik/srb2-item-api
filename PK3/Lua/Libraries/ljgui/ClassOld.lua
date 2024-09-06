-- ---@class ljgui
-- local gui = ljrequire "ljgui.common"


-- ---@class ljgui.Class
-- ---@field __class ljgui.Class


-- function gui.class(parent)
-- 	local class = {}

-- 	local objectMetatable = { __index = class }

-- 	if parent then
-- 		for k, v in pairs(parent) do
-- 			class[k] = v
-- 		end
-- 	end

-- 	class.__class = class

-- 	setmetatable(class, {
-- 		__call = function(_, ...)
-- 			local object = setmetatable({}, objectMetatable)

-- 			if object.__init then
-- 				object:__init(...)
-- 			end

-- 			return object
-- 		end,
-- 		__newindex = function(class, k, v)
-- 			if k:sub(1, 2) == "__" and k ~= "__init" then
-- 				objectMetatable[k] = v
-- 			else
-- 				rawset(class, k, v)
-- 			end
-- 		end
-- 	})

-- 	return class, parent
-- end
