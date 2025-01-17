---@class itemapi
local mod = itemapi


mod.vars.mobjTickers = {}

---@type boolean
mod.vars.tickersInitialised = false

---@type integer
mod.vars.nextTickerID = 1

local mobjTickerIdToFrequency = nil
local mobjTickerIdToIndex = nil
local mobjTickerCallbacks = nil


local function cacheClientData()
	mobjTickerIdToFrequency = {}
	mobjTickerIdToIndex = {}
	mobjTickerCallbacks = {}

	for freq = 1, TICRATE do
		mobjTickerIdToIndex[freq] = {}
		mobjTickerCallbacks[freq] = {}

		local tickers = mod.vars.mobjTickers[freq]
		for i = 1, #tickers.ids do
			local id = tickers.ids[i]
			mobjTickerIdToFrequency[id] = freq
			mobjTickerIdToIndex[id] = i
			mobjTickerCallbacks[freq][i] = mod.idToEntity[tickers.callbackIDs[i]]
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

	if not mobjTickerCallbacks then
		cacheClientData()
	end

	if frequency <= TICRATE then
		local tickers = mod.vars.mobjTickers[frequency]
		local i = #tickers.ids + 1

		local id = mod.vars.nextTickerID
		tickers.ids[i] = id
		tickers.mobjs[i] = mobj
		tickers.callbackIDs[i] = mod.entityToID[callback]
		mobjTickerIdToFrequency[id] = frequency
		mobjTickerIdToIndex[id] = i
		mobjTickerCallbacks[frequency][i] = callback
	else
		error "unimplemented for frequencies > TICRATE"
	end

	mod.vars.nextTickerID = $ + 1
end

---@param id integer
function mod.stopMobjTicker(id)
	if not mobjTickerCallbacks then
		cacheClientData()
	end

	local frequency = mobjTickerIdToFrequency[id]

	if frequency <= TICRATE then
		local tickers = mod.vars.mobjTickers[frequency]
		local i = mobjTickerIdToIndex[id]
		local len = #tickers.ids

		local ids = tickers.ids
		local mobjs = tickers.mobjs
		local callbackIDs = tickers.callbackIDs
		local callbacks = mobjTickerCallbacks[frequency]

		mobjTickerIdToIndex[ids[len]] = i

		ids[i] = ids[len]
		mobjs[i] = mobjs[len]
		callbackIDs[i] = callbackIDs[len]
		callbacks[i] = callbacks[len]

		ids[len] = nil
		mobjs[len] = nil
		callbackIDs[len] = nil
		callbacks[len] = nil

		mobjTickerIdToFrequency[id] = nil
		mobjTickerIdToIndex[id] = nil
	else
		error "unimplemented for frequencies > TICRATE"
	end
end

function mod.updateTickers()
	if not mobjTickerCallbacks then
		cacheClientData()
	end

	local time = leveltime

	for freq = 1, TICRATE do
		if time % freq ~= 0 then continue end

		local tickers = mod.vars.mobjTickers[freq]
		local mobjs = tickers.mobjs
		local callbacks = mobjTickerCallbacks[freq]

		for i = #mobjs, 1, -1 do
			local mo = mobjs[i]

			-- !!!
			if not mo then
				dump("ticker mobjs", mobjs)
			end

			if not mo.valid then
				mod.stopMobjTicker(tickers.ids[i])
				continue
			end

			local callback = callbacks[i]
			callback(mo, freq)
		end
	end
end

function mod.initialiseTickers()
	if mod.vars.tickersInitialised then return end

	for freq = 1, TICRATE do
		mod.vars.mobjTickers[freq] = {
			ids = {},
			mobjs = {},
			callbackIDs = {}
		}
	end

	mod.vars.tickersInitialised = true
end

function mod.uninitialiseTickers()
	if not mod.vars.tickersInitialised then return end

	mod.vars.mobjTickers = {}
	mod.uninitialiseClientTickers()
	mod.vars.tickersInitialised = false
end

function mod.uninitialiseClientTickers()
	mobjTickerIdToFrequency = nil
	mobjTickerIdToIndex = nil
	mobjTickerCallbacks = nil
end
