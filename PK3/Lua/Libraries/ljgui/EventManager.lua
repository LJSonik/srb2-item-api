---@class ljgui
local gui = ljrequire "ljgui.common"


---@class ljgui.EventType : string


---@class ljgui.Event
---@field callback function


---@class ljgui.EventManager
---@field focusedItem? ljgui.Item
---
---@field itemEvents         table<ljgui.Item, table<ljgui.EventType, ljgui.Event[]>>
---@field detachedItemEvents table<ljgui.Item, table<ljgui.EventType, ljgui.Event[]>>
---@field itemsByEventType   table<ljgui.EventType, ljgui.Set<ljgui.Item>>
local Manager = gui.class()
gui.EventManager = Manager


function Manager:__init()
	self.itemEvents = {}
	self.detachedItemEvents = setmetatable({}, { __mode = "k" })
	self.itemsByEventType = {}
end

---@param item ljgui.Item
---@param eventType ljgui.EventType
---@param callback function
function Manager:addItemEvent(item, eventType, callback)
	---@type ljgui.Event
	local event = { callback = callback }

	local events = item.rooted and self.itemEvents or self.detachedItemEvents
	events[item] = $ or {}
	events[item][eventType] = $ or {}
	table.insert(events[item][eventType], event)

	if item.rooted then
		self.itemsByEventType[eventType] = $ or {}
		self.itemsByEventType[eventType][item] = true
	end
end

---@param item ljgui.Item
---@param eventType ljgui.EventType
---@param callback? function
function Manager:removeItemEvent(item, eventType, callback)
	local allEvents = item.rooted and self.itemEvents or self.detachedItemEvents
	local events = allEvents[item][eventType]

	if callback then
		for i = #events, 1, -1 do
			if events[i].callback == callback then
				table.remove(events, i)
			end
		end
	end

	if not callback or #events == 0 then
		allEvents[item][eventType] = nil

		if item.rooted then
			self.itemsByEventType[eventType][item] = nil
		end
	end
end

---@param item ljgui.Item
function Manager:attachItemEvents(item)
	local detachedEvents = self.detachedItemEvents[item]
	if not detachedEvents then return end

	self.itemEvents[item] = detachedEvents
	self.detachedItemEvents[item] = nil

	for eventType, _ in pairs(detachedEvents) do
		self.itemsByEventType[eventType] = $ or {}
		self.itemsByEventType[eventType][item] = true
	end
end

---@param item ljgui.Item
function Manager:detachItemEvents(item)
	local events = self.itemEvents[item]
	if not events then return end

	self.itemEvents[item] = nil
	self.detachedItemEvents[item] = events

	for eventType, _ in pairs(events) do
		self.itemsByEventType[eventType][item] = nil
	end
end

---@param item ljgui.Item
---@param eventType ljgui.EventType
---@return boolean
function Manager:callItemEvent(item, eventType, ...)
	local allEvents = self.itemEvents[item]
	if not allEvents then return false end

	local events = allEvents[eventType]
	if not events then return false end

	for i = 1, #events do
		if events[i].callback(item, ...) then
			return true
		end
	end

	return false
end

---@param eventType ljgui.EventType
---@return boolean
function Manager:callGlobalItemEvent(eventType, ...)
	local items = self.itemsByEventType[eventType]
	if not items then return false end

	for item, _ in pairs(items) do
		local events = self.itemEvents[item][eventType]
		for i = 1, #events do
			if events[i].callback(item, ...) then
				return true
			end
		end
	end

	return false
end

function Manager:update()
	self:callGlobalItemEvent("Tick")
end

---@param key keyevent_t
---@return boolean
function Manager:handleKeyDown(key)
	return false
end

---@param key keyevent_t
---@return boolean
function Manager:handleKeyUp(key)
	return false
end


---@param key keyevent_t
---@return boolean
function gui.handleKeyDown(key)
	if not gui.instance then return false end

	local manager = gui.instance.eventManager
    local item = manager.focusedItem
	while item do
		if manager:callItemEvent(item, "KeyPress", key) then
			return true
		end
		item = item.parent
	end

	-- local manager = gui.instance.eventManager
    -- local item = manager.focusedItem
	-- if item and manager:callItemEvent(item, "KeyPress", key) then
	-- 	return true
	-- end

	if key.name == "mouse1" and gui.instance.mouse:pressLeftButton() then
		return true
	end

	return false
end

---@param key keyevent_t
---@return boolean
function gui.handleKeyUp(key)
	if not gui.instance then return false end

	local manager = gui.instance.eventManager
    local item = manager.focusedItem
	if item and manager:callItemEvent(item, "KeyRelease", key) then
		return true
	end

	if key.name == "mouse1" and gui.instance.mouse:releaseLeftButton() then
		return true
	end

	return false
end
