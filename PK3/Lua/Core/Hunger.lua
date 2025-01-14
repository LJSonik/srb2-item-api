---@class itemapi
local mod = itemapi


---@class player_t
---@field itemapi_hunger tic_t


mod.MAX_HUNGER = 10*60*TICRATE


---@param player player_t
local function updateInfoBubble(player)
	local bubbles = player.itemapi_infoBubbles
	local hunger = player.itemapi_hunger

	local bubbleID
	if hunger > mod.MAX_HUNGER / 4 then -- 25-100%
		bubbleID = nil
	elseif hunger > mod.MAX_HUNGER / 10 then -- 10-25%
		bubbleID = "hungry"
	elseif hunger > mod.MAX_HUNGER / 20 then -- 5-10%
		bubbleID = "starving"
	else -- 0-5%
		bubbleID = "starving"
	end

	if bubbleID == "hungry" and not bubbles["hungry"] then
		mod.startInfoBubble(player, {
			id = "hungry",
			sprite = SPR_IAPI,
			frame = C,
			scale = FU/2
		})
	elseif bubbleID ~= "hungry" and bubbles["hungry"] then
		mod.stopInfoBubble(player, "hungry")
	end

	if bubbleID == "starving" and not bubbles["starving"] then
		mod.startInfoBubble(player, {
			id = "starving",
			sprite = SPR_IAPI,
			frame = D,
			scale = FU/2
		})
	elseif bubbleID ~= "starving" and bubbles["starving"] then
		mod.stopInfoBubble(player, "starving")
	end
end

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

	local newHunger = oldHunger
	if leveltime % freq == 0 then
		newHunger = max($ - 1, 0)
	end

	player.itemapi_hunger = newHunger

	if newHunger == 0 and newHunger ~= oldHunger and player.mo then
		P_DamageMobj(player.mo, nil, nil, nil, DMG_INSTAKILL)
	end

	updateInfoBubble(player)
end
