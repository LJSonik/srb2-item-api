---@class itemapi
local mod = itemapi


---@type mobj_t[][]
mod.vars.mobjTickers_mobj = {}

---@type integer[][]
mod.vars.mobjTickers_callbackID = {}

---@type boolean
mod.vars.tickersInitialised = false

---@type fun(mobj: mobj_t, deltaTime: tic_t)[][]?
local mobjTickers_callback = nil


local function cacheCallbacks()
	mobjTickers_callback = {}

	for freq = 1, TICRATE do
		mobjTickers_callback[freq] = {}

		for i, id in ipairs(mod.vars.mobjTickers_callbackID[freq]) do
			mobjTickers_callback[freq][i] = mod.idToEntity[id]
		end
	end
end

---@param mobj mobj_t
---@param callback fun(mobj: mobj_t)
---@param frequency tic_t
function mod.startMobjTicker(mobj, callback, frequency)
	if not mod.vars.tickersInitialised then
		mod.initialiseTickers()
	end

	if not mobjTickers_callback then
		cacheCallbacks()
	end

	if frequency <= TICRATE then
		local tickers_mobj = mod.vars.mobjTickers_mobj[frequency]
		local i = #tickers_mobj + 1

		tickers_mobj[i] = mobj
		mod.vars.mobjTickers_callbackID[frequency][i] = mod.entityToID[callback]
		mobjTickers_callback[frequency][i] = callback
	else
		error "unimplemented for frequencies > TICRATE"
	end
end

function mod.updateTickers()
	if not mobjTickers_callback then
		cacheCallbacks()
	end

	local tickers_mobj = mod.vars.mobjTickers_mobj
	local tickers_callbackID = mod.vars.mobjTickers_callbackID
	local tickers_callback = mobjTickers_callback
	local time = leveltime

	for freq = 1, TICRATE do
		if time % freq ~= 0 then continue end

		local list_mobj = tickers_mobj[freq]
		local list_callback = tickers_callback[freq]

		for i = #list_mobj, 1, -1 do
			local mo = list_mobj[i]

			if not mo.valid then
				local len = #list_mobj

				list_mobj[i] = list_mobj[len]
				list_mobj[len] = nil

				local list_callbackID = tickers_callbackID[freq]
				list_callbackID[i] = list_callbackID[len]
				list_callbackID[len] = nil

				list_callback[i] = list_callback[len]
				list_callback[len] = nil

				continue
			end

			local callback = list_callback[i]
			callback(mo, freq)
		end
	end
end

function mod.initialiseTickers()
	if mod.vars.tickersInitialised then return end

	for freq = 1, TICRATE do
		mod.vars.mobjTickers_mobj[freq] = {}
		mod.vars.mobjTickers_callbackID[freq] = {}
	end

	mod.vars.tickersInitialised = true
end

function mod.uninitialiseTickers()
	if not mod.vars.tickersInitialised then return end

	mod.vars.mobjTickers_mobj = {}
	mod.vars.mobjTickers_callbackID = {}

	mod.uninitialiseClientTickers()

	mod.vars.tickersInitialised = false
end

function mod.uninitialiseClientTickers()
	mobjTickers_callback = nil
end
