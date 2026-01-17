---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Instance
---@field root ljgui.Root
---@field mouse ljgui.Mouse
---@field eventManager ljgui.EventManager
---@field dependencyManager ljgui.DependencyManager
local Instance, base = gui.class()
gui.Instance = Instance


function Instance:__init()
	gui.instance = self

	self.eventManager = gui.EventManager()
	self.dependencyManager = gui.DependencyManager()

	self.root = gui.Root()
	gui.root = self.root

	self.mouse = gui.Mouse()
end

---@param v videolib
function Instance:update(v)
	gui.instance = self
	gui.root = self.root
	gui.v = v

	gui.instance.dependencyManager:propagateModifiedAttributes()

	self.eventManager:update()

	if self.mouse.enabled then return
		self.mouse:update()
	end
end

---@param v videolib
---@param item ljgui.Item
local function drawItem(v, item)
	local l, t = item.cachedLeft, item.cachedTop
	local r, b = l + item.width, t + item.height

	if gui.pushDrawRegion(v, l, t, r, b) then
		item:draw(v)

		local children = item.children.items
		for i = #children, 1, -1 do
			drawItem(v, children[i])
		end

		gui.popDrawRegion()
	end
end

-- local numsamples = 1
-- local totaltime = 0

---@param v videolib
function Instance:draw(v)
	-- local startTime = getTimeMicros()

	gui.instance = self
	gui.root = self.root
	gui.v = v

	gui.instance.dependencyManager:propagateModifiedAttributes()

	drawItem(v, self.root)

	if self.mouse.enabled then return
		self.mouse:draw(v)
	end

	-- if numsamples > 5 * TICRATE then
	-- 	numsamples = 0
	-- 	totaltime = 0
	-- end
	-- totaltime = $ + getTimeMicros() - startTime
	-- numsamples = $ + 1
	-- print(totaltime / numsamples)
end
