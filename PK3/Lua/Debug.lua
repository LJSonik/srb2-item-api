---@class itemapi
local mod = itemapi


mod.debugLog = {}


function mod.logDebugLine(line)
	table.insert(mod.debugLog, line)
end


---@param p player_t
addHook("PlayerSpawn", function(p)
	-- p.itemapi_inventory:add("log", 10)
	-- p.itemapi_inventory:setSlot(1, "log")
	-- p.itemapi_hunger = mod.MAX_HUNGER * 11/100
	-- local fire = mod.placeItem(p, "campfire")
	-- mod.campfire_addItemToSpit(fire, "raw_meat")
	-- mod.carryItem(p, "chest")
	-- mod.placeItem(p, "chest")
	-- mod.setUIMode("large_item_placement", "campfire")
	-- P_SetOrigin(p.mo, -3026*FU, -5666*FU, 48*FU)
	-- p.mo.angle = 180*ANG1
	-- mod.DayNightCycle.vars.time = 10*mod.DayNightCycle.HOUR
end)

COM_AddCommand("seelog", function()
	print "[DEBUG LOG START]"

	for _, line in ipairs(mod.debugLog) do
		print(line)
	end

	print "[DEBUG LOG END]"
end, COM_ADMIN | COM_LOCAL)

COM_AddCommand("clearlog", function()
	mod.debugLog = {}
end, COM_ADMIN | COM_LOCAL)


local function stringToPlayer(s)
	if not s then return nil end

	local n = tonumber(s)
	if n == nil then -- Player name
		s = s:lower()
		local matchingplayer, ambiguous
		for p in players.iterate do
			local name = p.name:lower()
			if name:find(s, nil, true) then
				if s == name then
					return p
				elseif matchingplayer then
					ambiguous = true
				else
					matchingplayer = p
				end
			end
		end

		if ambiguous then
			return nil, "ambiguous"
		else
			return matchingplayer
		end
	elseif n < 0 or n > 31 then -- Invalid player number
		return nil
	else -- Player number
		local p = players[n]
		if p and p.valid then return p end
	end

	return nil
end

COM_AddCommand("giveitem", function(p, id, quantity, target)
	if not id then
		CONS_Printf(p, "giveitem <item type> [quantity] [player name/number]")
		return
	end

	quantity = tonumber($ or 1)

	if target then
		target = stringToPlayer(target)

		if not target then
			CONS_Printf(p, "Player not found, or partial name ambiguous.")
			return
		end
	else
		target = p
	end

	if not mod.itemDefs[id] then
		CONS_Printf(p, "Item type not found")
		return
	end

	if not target.itemapi_inventory then return end

	target.itemapi_inventory:add(id, quantity)
end, COM_ADMIN)

COM_AddCommand("checkitems", function(p, checkedplayer)
	if not checkedplayer then
		CONS_Printf(p, "checkitems <player name/number>")
		return
	end

	local checkedplayer = stringToPlayer(checkedplayer)
	if not checkedplayer then
		CONS_Printf(p, "Player not found, or partial name ambiguous.")
		return
	end

	local inv = checkedplayer.itemapi_inventory
	if not inv then return end

	local items = {}
	for i = 1, inv.numSlots do
		local id, quantity = inv:get(i)
		if id then
			items[id] = ($ or 0) + quantity
		end
	end

	for id, quantity in pairs(items) do
		CONS_Printf(p, itemapi.itemDefs[id].name .. ": " .. quantity)
	end
end, COM_ADMIN)

COM_AddCommand("countitems", function(_, id)
	if not id then
		id = "berry_bush_seed"
	end

	local n = 0
	for p in players.iterate do
		if p.itemapi_inventory then
			n = $ + p.itemapi_inventory:count(id)
		end
	end

	print("There are " .. n .. " " .. id .. " among all players.")
end, COM_ADMIN | COM_LOCAL)

COM_AddCommand("stealitems", function(p, stolenplayer)
	if not stolenplayer then
		CONS_Printf(p, "stealitems <player name/number>")
		return
	end

	local stolenplayer = stringToPlayer(stolenplayer)
	if not stolenplayer then
		CONS_Printf(p, "Player not found, or partial name ambiguous.")
		return
	end

	local srcinv = stolenplayer.itemapi_inventory
	local dstinv = p.itemapi_inventory
	if not stolenplayer.itemapi_inventory then return end

	local full = false

	for i = 1, srcinv.numSlots do
		local id, quantity = srcinv:get(i)
		if id then
			if dstinv:add(id, quantity) then
				srcinv:removeFromSlot(i, quantity)
			else
				full = true
			end
		end
	end

	if full then
		CONS_Printf(p, "Some items could not be taken because your inventory is full.")
	end
end, COM_ADMIN)
