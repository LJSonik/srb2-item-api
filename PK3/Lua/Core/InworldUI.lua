---@class itemapi
local mod = itemapi


local ljclass = ljrequire "ljclass"


---@class itemapi.InworldUIDef
---@field id string
---@field index integer
---
---@field initialise fun(ui: itemapi.InworldUI)


---@class itemapi.InworldUIAvatar
---@field widgets itemapi.InworldWidget[]


---@type table<string|integer, itemapi.InworldUIDef>
mod.inworldUIDefs = {}

---@type itemapi.InworldUI[]
mod.vars.inworldUIs = {}

---@type itemapi.InworldUIAvatar[]
mod.client.inworldUIAvatars = {}


freeslot("MT_ITEMAPI_UI", "S_ITEMAPI_UI")

mobjinfo[MT_ITEMAPI_UI] = {
	spawnstate = S_ITEMAPI_UI,
	spawnhealth = 1,
	radius = 8*FU,
	height = 16*FU,
	flags = MF_NOBLOCKMAP|MF_NOCLIP|MF_NOCLIPHEIGHT|MF_SCENERY|MF_NOGRAVITY
}

states[S_ITEMAPI_UI] = { SPR_IAPI, B }


---@class itemapi.InworldUI : ljclass.Class
---@field type integer
---@field x fixed_t
---@field y fixed_t
---@field z fixed_t
local InworldUI = ljclass.class()
mod.InworldUI = InworldUI


---@param id string|integer
---@param y fixed_t
---@param z fixed_t
---@param z fixed_t
---@param state? table
function InworldUI:__init(id, x, y, z, state)
	self.type = mod.inworldUIDefs[id].index
	self.x, self.y, self.z = x, y, z
	mod.copy(state or {}, self)
end

---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
function InworldUI:setPosition(x, y, z)
	local oldX, oldY = self.x, self.y
	self.x, self.y, self.z = x, y, z
	mod.moveEntityInCullingSystem("inworld_ui", self, oldX, oldY, x, y)
end

---@param angle? angle_t
function InworldUI:setAngle(angle)
	self.angle = angle
end

function InworldUI:despawn()
	mod.removeEntityFromCullingSystem("inworld_ui", self, self.x, self.y)
end

---@param id string
---@param widget itemapi.InworldWidget
function InworldUI:attach(id, widget)
	local avatar = mod.client.inworldUIAvatars[self]
	widget = mod.copy(widget, mod.InworldWidget(id))
	table.insert(avatar.widgets, widget)
end


---@param id string
---@param def itemapi.InworldUIDef
function mod.addInworldUI(id, def)
	if type(id) ~= "string" then
		error("missing or invalid in-world UI ID", 2)
	end

	def.index = #mod.inworldUIDefs + 1
	def.id = id
	mod.inworldUIDefs[def.index] = def
	mod.inworldUIDefs[id] = def
end

---@param id string|integer
---@param x fixed_t
---@param y fixed_t
---@param z fixed_t
---@param state? table
---@return itemapi.InworldUI
function mod.spawnInworldUI(id, x, y, z, state)
	local ui = InworldUI(id, x, y, z, state)
	table.insert(mod.vars.inworldUIs, ui)
	mod.addEntityToCullingSystem("inworld_ui", ui, x, y)
	return ui
end

---@param ui itemapi.InworldUI
---@return nil
function mod.despawnInworldUI(ui)
	itemapi.removeValueFromUnorderedArray(mod.vars.inworldUIs, ui)
	mod.removeEntityFromCullingSystem("inworld_ui", ui, ui.x, ui.y)
	return nil
end

function mod.uninitialiseInworldUIs()
	mod.vars.inworldUIs = {}
end

---@return angle_t
local function getCameraAngle()
	if camera.chase or not (displayplayer.realmo and displayplayer.realmo.valid) then
		return camera.angle + ANGLE_180
	else
		return displayplayer.realmo.angle + ANGLE_180
	end

	-- local angle
	-- if camera.chase or not (displayplayer.realmo and displayplayer.realmo.valid) then
	-- 	angle = camera.angle
	-- else
	-- 	angle = displayplayer.realmo.angle
	-- end
	-- angle = InvAngle(angle)
end

local function updateInworldUIAvatar(ui, avatar)
	local angle
	if ui.angle ~= nil then
		angle = ui.angle
	else
		angle = getCameraAngle()
	end

	local widgets = avatar.widgets
	for i = 1, #widgets do
		local widget = widgets[i]
		local widgetDef = mod.inworldWidgetDefs[widget.type]
		widgetDef.updateMobjFacing(widget, ui, angle)
	end
end

function mod.updateInworldUIAvatars()
	if not displayplayer then return end

	for ui, avatar in pairs(mod.client.inworldUIAvatars) do
		updateInworldUIAvatar(ui, avatar)
	end
end

function mod.initialiseInworldUIAvatars()
	mod.client.inworldUIAvatars = {}

	local uis = mod.vars.inworldUIs
	for i = 1, #uis do
		local ui = uis[i]
		mod.addEntityToCullingSystem("inworld_ui", ui, ui.x, ui.y)
	end
end

function mod.uninitialiseInworldUIAvatars()
	mod.client.inworldUIAvatars = {}
end


mod.addCullableEntity("inworld_ui", {
	---@param ui itemapi.InworldUI
	spawn = function(ui)
		if mod.client.inworldUIAvatars[ui] then return end

		local avatar = { widgets = {} }
		mod.client.inworldUIAvatars[ui] = avatar

		local uiDef = mod.inworldUIDefs[ui.type]
		uiDef.initialise(ui)

		local widgets = avatar.widgets
		for i = 1, #widgets do
			local widget = widgets[i]
			local widgetDef = mod.inworldWidgetDefs[widget.type]
			widgetDef.spawnMobjs(widget, ui)
		end

		updateInworldUIAvatar(ui, avatar)
	end,

	---@param ui itemapi.InworldUI
	despawn = function(ui)
		local avatar = mod.client.inworldUIAvatars[ui]
		if not avatar then return end

		for i = 1, #avatar.widgets do
			local widget = avatar.widgets[i]
			local widgetDef = mod.inworldWidgetDefs[widget.type]

			widgetDef.despawnMobjs(widget)
		end

		mod.client.inworldUIAvatars[ui] = nil
	end
})
