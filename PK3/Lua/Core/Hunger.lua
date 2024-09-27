---@class itemapi
local mod = itemapi


---@class player_t
---@field itemapi_hunger tic_t


mod.MAX_HUNGER = 10*60*TICRATE


---@param player player_t
function mod.eat(player, amount)
	player.itemapi_hunger = min($ + amount, mod.MAX_HUNGER)
end

---@param player player_t
function mod.updateHunger(player)
	local oldHunger = player.itemapi_hunger

	local freq
	if oldHunger > mod.MAX_HUNGER / 10 then -- 10-100%
		freq = 1
	elseif oldHunger > mod.MAX_HUNGER / 20 then -- 5-10%
		freq = 2
	else -- 0-5%
		freq = 5
	end

	local newHunger
	if leveltime % freq == 0 then
		newHunger = max(oldHunger - 1, 0)
	end

	player.itemapi_hunger = newHunger

	if newHunger == 0 and newHunger ~= oldHunger then
		P_DamageMobj(player.mo, nil, nil, nil, DMG_INSTAKILL)
	end
end
