---@class itemapi
local mod = itemapi


mod.vars.mobjTickerData = nil
mod.vars.tickersInitialised = false

local clientMobjTickerData = nil
local mobjTickerCache = nil
local clientMobjTickerCache = nil
local client_tickersInitialised = false

local function initialiseCache(tickerData)
	local cache = {}

	cache.idToFrequency = {}
	cache.idToIndex = {}
	cache.callbacks = {}

	for freq = 1, TICRATE do
		cache.idToIndex[freq] = {}
		cache.callbacks[freq] = {}

		local tickers = tickerData.tickers[freq]
		for i = 1, #tickers.ids do
			local id = tickers.ids[i]
			cache.idToFrequency[id] = freq
			cache.idToIndex[id] = i
			cache.callbacks[freq][i] = mod.idToEntity[tickers.callbackIDs[i]]
		end
	end

	return cache
end

---@param mobj mobj_t
---@param callback fun(mobj: mobj_t)
---@param frequency tic_t
---@param tickerData table
---@param cache table
local function startMobjTicker(mobj, callback, frequency, tickerData, cache)
	if frequency <= TICRATE then
		local tickers = tickerData.tickers[frequency]
		local i = #tickers.ids + 1
		local id = tickerData.nextTickerID

		tickers.ids[i] = id
		tickers.mobjs[i] = mobj
		tickers.callbackIDs[i] = mod.entityToID[callback]

		cache.idToFrequency[id] = frequency
		cache.idToIndex[id] = i
		cache.callbacks[frequency][i] = callback
	else
		error "unimplemented for frequencies > TICRATE"
	end

	tickerData.nextTickerID = $ + 1
end

---@param mobj mobj_t
---@param callback fun(mobj: mobj_t)
---@param frequency tic_t
function mod.startMobjTicker(mobj, callback, frequency)
	if not mod.vars.tickersInitialised then
		mod.initialiseTickers()
	end

	if not mobjTickerCache then
		mobjTickerCache = initialiseCache(mod.vars.mobjTickerData)
	end

	startMobjTicker(mobj, callback, frequency, mod.vars.mobjTickerData, mobjTickerCache)
end

---@param mobj mobj_t
---@param callback fun(mobj: mobj_t)
---@param frequency tic_t
function mod.startClientMobjTicker(mobj, callback, frequency)
	if not client_tickersInitialised then
		mod.client_initialiseTickers()
	end

	if not clientMobjTickerCache then
		clientMobjTickerCache = initialiseCache(clientMobjTickerData)
	end

	startMobjTicker(mobj, callback, frequency, clientMobjTickerData, clientMobjTickerCache)
end

---@param id integer
---@param tickerData table
---@param cache table
local function stopMobjTicker(id, tickerData, cache)
	local frequency = cache.idToFrequency[id]

	if frequency <= TICRATE then
		local tickers = tickerData.tickers[frequency]
		local i = cache.idToIndex[id]
		local len = #tickers.ids

		local ids = tickers.ids
		local mobjs = tickers.mobjs
		local callbackIDs = tickers.callbackIDs
		local callbacks = cache.callbacks[frequency]

		cache.idToIndex[ids[len]] = i

		ids[i] = ids[len]
		mobjs[i] = mobjs[len]
		callbackIDs[i] = callbackIDs[len]
		callbacks[i] = callbacks[len]

		ids[len] = nil
		mobjs[len] = nil
		callbackIDs[len] = nil
		callbacks[len] = nil

		cache.idToFrequency[id] = nil
		cache.idToIndex[id] = nil
	else
		error "unimplemented for frequencies > TICRATE"
	end
end

---@param id integer
function mod.stopMobjTicker(id)
	if not mobjTickerCache then
		mobjTickerCache = initialiseCache(mod.vars.mobjTickerData)
	end

	stopMobjTicker(id, mod.vars.mobjTickerData, mobjTickerCache)
end

---@param id integer
function mod.stopClientMobjTicker(id)
	if not clientMobjTickerCache then
		clientMobjTickerCache = initialiseCache(clientMobjTickerData)
	end

	stopMobjTicker(id, clientMobjTickerData, clientMobjTickerCache)
end

local function updateTickersForFrequency(tickerData, cache, frequency)
	local tickers = tickerData.tickers[frequency]
	local mobjs = tickers.mobjs
	local callbacks = cache.callbacks[frequency]

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
		callback(mo, frequency)
	end
end

local function updateTickers(tickerData, cache)
	local time = leveltime

	for freq = 1, TICRATE do
		if time % freq == 0 then
			updateTickersForFrequency(tickerData, cache, freq)
		end
	end
end

function mod.updateTickers()
	if not mobjTickerCache then
		mobjTickerCache = initialiseCache(mod.vars.mobjTickerData)
	end

	updateTickers(mod.vars.mobjTickerData, mobjTickerCache)
end

function mod.updateClientTickers()
	if not clientMobjTickerCache then
		clientMobjTickerCache = initialiseCache(clientMobjTickerData)
	end

	updateTickers(clientMobjTickerData, clientMobjTickerCache)
end

local function initialiseTickerData()
	local tickerData = {}

	tickerData.tickers = {}
	tickerData.nextTickerID = 1

	for freq = 1, TICRATE do
		tickerData.tickers[freq] = {
			ids = {},
			mobjs = {},
			callbackIDs = {}
		}
	end

	return tickerData
end

function mod.initialiseTickers()
	if mod.vars.tickersInitialised then return end

	mod.vars.mobjTickerData = initialiseTickerData()
	mod.vars.tickersInitialised = true
end

function mod.client_initialiseTickers()
	if client_tickersInitialised then return end

	clientMobjTickerData = initialiseTickerData()
	client_tickersInitialised = true
end

function mod.uninitialiseTickers()
	if not mod.vars.tickersInitialised then return end

	mod.vars.mobjTickerData = nil
	mod.vars.tickersInitialised = false

	mod.client_uninitialiseTickers()
end

function mod.client_uninitialiseTickers()
	clientMobjTickerData = nil

	mobjTickerCache = nil
	clientMobjTickerCache = nil

	client_tickersInitialised = false
end
