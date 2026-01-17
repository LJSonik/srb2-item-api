-- Item API by LJ Sonic


---@class itemapi
local mod = itemapi


local nc = ljrequire "ljnetcommand"


---@class player_t
---@field itemapi_initialised boolean


freeslot("SPR_IAPI")


---@type { [any]: integer }
mod.entityToID = {}

---@type any[]
mod.idToEntity = {}


---@class itemapi.Vars
---@field time tic_t
---@field mapInitialised boolean
mod.vars.time = 0
mod.vars.mapInitialised = false


---@class itemapi.Client
---@field time tic_t
---@field initialised boolean
---@field mapInitialised boolean
mod.client.time = 0
mod.client.initialised = false
mod.client.mapInitialised = false

local delayedNetCommands = {}


-- Hopefully temporary wrapper because currently
-- SRB2 sends synced commands immediately if you are in singleplayer
function mod.sendNetCommand(sender, s)
	table.insert(delayedNetCommands, { sender, s })
end

---@param entity any
function mod.register(entity)
	if mod.entityToID[entity] then return end

	local id = #mod.idToEntity + 1

	mod.idToEntity[id] = entity
	mod.entityToID[entity] = id
end

function mod.initialiseMap()
	mod.initialiseTickers()

	if mod.client.initialised and not mod.client.mapInitialised then
		mod.initialiseClientMap()
	end

	mod.vars.mapInitialised = true
end

function mod.uninitialiseMap()
	mod.uninitialiseTickers()
	mod.uninitialiseModels()
	mod.uninitialiseActions()

	if mod.client.mapInitialised then
		mod.uninitialiseClientMap()
	end

	mod.vars.mapInitialised = false
end

---@param p player_t
function mod.initialisePlayer(p)
	p.itemapi_carrySlots = {}
	p.itemapi_inventory = mod.Inventory(8, 4)
	p.itemapi_hunger = mod.MAX_HUNGER
	p.itemapi_thirst = mod.MAX_THIRST
	p.itemapi_infoBubbles = {}

	p.itemapi_initialised = true
end

---@param p player_t
function mod.uninitialisePlayingPlayer(p)
	if p == consoleplayer then
		mod.closeUI() -- !!! INTERFACE
	end

	if p.itemapi_action then
		mod.stopAction(p)
	end

	for i = 1, #mod.carrySlotDefs do
		mod.uncarryItem(p, i)
	end

	for i = #p.itemapi_infoBubbles, 1, -1 do
		mod.stopInfoBubble(p, p.itemapi_infoBubbles[i])
	end
end


function mod.initialiseClient()
	mod.loadOptions()
	mod.loadControlOptions()

	if not mod.client.mapInitialised then
		mod.initialiseClientMap()
	end

	mod.client.initialised = true
end

function mod.uninitialiseClient()
	if mod.client.mapInitialised then
		mod.uninitialiseClientMap()
	end

	mod.uninitialiseInterface()

	mod.client.initialised = false
end

function mod.updateClient()
	mod.updateInterface() -- !!! INTERFACE
	mod.updateClientTickers()
	mod.updateCulling()

	mod.client.time = $ + 1
end

function mod.initialiseClientMap()
	mod.client_initialiseTickers()
	mod.initialiseVisualCulling()
	mod.initialiseModelAvatars()

	mod.client.mapInitialised = true
end

function mod.uninitialiseClientMap()
	mod.client_uninitialiseTickers()
	mod.uninitialiseVisualCulling()
	mod.uninitialiseModelAvatars()
	mod.uninitialiseActionTargetIcon() -- !!! INTERFACE
	mod.closeUI() -- !!! INTERFACE

	mod.client.mapInitialised = false
end

addHook("ThinkFrame", function()
	if gamestate ~= GS_LEVEL then return end

	if not mod.vars.mapInitialised then
		mod.initialiseMap()
	end

	mod.vars.time = $ + 1

	for p in players.iterate do
		if not p.mo then continue end

		mod.updateCarriedItems(p)
		mod.updateHunger(p)
		mod.updateThirst(p)
		mod.updateInfoBubbles(p)
	end

	mod.updateActions()

	mod.updateTickers()
	mod.updateModels()

	--- !!! Is this the right place for clientside code?
	if not isdedicatedserver and consoleplayer then
		if not mod.client.initialised then
			mod.initialiseClient()
		end

		mod.updateClient()
	end
end)

addHook("PostThinkFrame", function()
	if gamestate ~= GS_LEVEL then return end

	for _, cmd in ipairs(delayedNetCommands) do
		nc.send(cmd[1], cmd[2])
	end

	delayedNetCommands = {}
end)

---@param p player_t
addHook("PlayerSpawn", function(p)
	if p.itemapi_initialised then
		p.itemapi_hunger = mod.MAX_HUNGER / 4
		p.itemapi_thirst = mod.MAX_THIRST / 4
	else
		mod.initialisePlayer(p)
	end

	for i = 1, #mod.carrySlotDefs do
		local slot = p.itemapi_carrySlots[i]
		if slot and not (slot.mobj and slot.mobj.valid) then
			mod.spawnCarriedItemMobj(p, i)
		end
	end
end)

---@param p player_t
addHook("TeamSwitch", function(p, team)
	local oldSpectator = p.spectator
	local newSpectator = (team == 0)

	if not oldSpectator and newSpectator then
		mod.uninitialisePlayingPlayer(p)
	end
end)

---@param p player_t
addHook("PlayerQuit", function(p)
	if p.itemapi_action then
		mod.stopAction(p)
	end

	for i = 1, #mod.carrySlotDefs do
		mod.uncarryItem(p, i)
	end

	for i = #p.itemapi_infoBubbles, 1, -1 do
		mod.stopInfoBubble(p, p.itemapi_infoBubbles[i])
	end
end)

addHook("MapChange", function()
	if mod.vars.mapInitialised then
		mod.uninitialiseMap()
	end
end)

addHook("GameQuit", function()
	if mod.client.initialised then
		mod.uninitialiseClient()
	end
end)

addHook("NetVars", function()
	if not isserver and mod.client.initialised then
		mod.uninitialiseClient()
	end
end)

-- addHook("PlayerCmd", function()
-- 	mod.client.time = $ + 1
-- 	mod.updateInterface()
-- end)
