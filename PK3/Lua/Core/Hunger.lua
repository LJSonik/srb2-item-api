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
	player.itemapi_hunger = max($ - 1, 0)
end
