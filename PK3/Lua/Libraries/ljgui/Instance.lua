---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.Instance
---@field root ljgui.Root
---@field mouse ljgui.Mouse
---@field eventManager ljgui.EventManager
---@field itemLayoutsToGenerate ljgui.Item[]
---@field itemsWithModifiedAttributes ljgui.Set<ljgui.Item>
local Instance = gui.class()
gui.Instance = Instance


function Instance:__init()
	gui.instance = self

	self.itemLayoutsToGenerate = {}
	self.itemsWithModifiedAttributes = {}

	self.eventManager = gui.EventManager()

	self.root = gui.Root()
	gui.root = self.root

	self.mouse = gui.Mouse()
end

---@param v videolib
function Instance:update(v)
	gui.instance = self
	gui.root = self.root
	gui.v = v

	gui.propagateModifiedItemAttributes()
	-- gui.generatePendingItemLayouts()

	self.eventManager:update()

	if self.mouse.enabled then return
		self.mouse:update()
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

	gui.propagateModifiedItemAttributes()
	-- gui.generatePendingItemLayouts()

	self.root:draw(v)

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
